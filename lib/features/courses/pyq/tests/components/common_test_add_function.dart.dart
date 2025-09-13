import 'package:cloud_firestore/cloud_firestore.dart';

Future<double> submitAndUpdateLeaderboard({
  required String userPhoneNumber,
  required String testType, // "pyq" or "test"
  required int correctCount,
  required int marks, // ✅ real score (not just correctCount)
  required int wrongCount,
  required int attemptedCount,
  required int unansweredCount,
  required int totalQuestions,
  required String accuracy,
  required String timeLeft,
  String? year,
  String? pyqType,
  String? level,
  String? subject,
  String? chapter,
  int? testNumber,
}) async {
  final firestore = FirebaseFirestore.instance;

  // 1. Save history in correct collection
  final historyCollection = testType == "pyq" ? "pyqHistory" : "testHistory";

  final historyData = {
    'accuracy': accuracy,
    'correct': correctCount,
    'wrong': wrongCount,
    'attempted': attemptedCount,
    'unattempted': unansweredCount,
    'totalQuestion': totalQuestions,
    'score': correctCount, // ✅ score = correctCount (or add formula if needed)
    'timeleft': timeLeft,
    'timestamp': FieldValue.serverTimestamp(),
  };

  if (testType == "pyq") {
    historyData.addAll({
      'year': year!,
      'pyqType': pyqType!,
    });
  } else {
    historyData.addAll({
      'level': level!,
      'subject': subject!,
      'chapter': chapter!,
      'testnumber': testNumber!,
    });
  }

  await firestore
      .collection('users')
      .doc(userPhoneNumber)
      .collection(historyCollection)
      .add(historyData);

  // 2. Fetch user info + stats
  final userDoc =
      await firestore.collection('users').doc(userPhoneNumber).get();
  final data = userDoc.data() ?? {};
  final stats = Map<String, dynamic>.from(data['stats'] ?? {});

  final oldRankScore = (stats['rankScore'] ?? 0.0).toDouble();
  final oldTotalScore = (stats['totalScore'] ?? 0).toInt();
  final oldTotalWrong = (stats['totalWrong'] ?? 0).toInt();
  final oldAccuracySum = (stats['totalAccuracySum'] ?? 0.0).toDouble();
  final oldTests = (stats['totalTests'] ?? 0).toInt();
  final oldAttempts = (stats['totalAttempted'] ?? 0).toInt();

  // 3. Calculate THIS test’s rank score
  final testRankScore = calculateRankScore(
    marks: marks,
    totalQ: totalQuestions,
    attemptedQ: attemptedCount,
  );

  // ✅ Incremental rank score
  final newRankScore = oldRankScore + testRankScore;

  // 4. Update stats
  final updatedStats = {
    'totalScore': oldTotalScore + correctCount,
    'totalWrong': oldTotalWrong + wrongCount,
    'totalAttempted': oldAttempts + attemptedCount,
    'totalAccuracySum': oldAccuracySum + double.parse(accuracy),
    'totalTests': oldTests + 1,
    'rankScore': newRankScore,
    'lastUpdated': FieldValue.serverTimestamp(),
  };

  await firestore
      .collection('users')
      .doc(userPhoneNumber)
      .update({'stats': updatedStats});

  // 5. Update leaderboard
  await firestore.collection('leaderboard').doc(userPhoneNumber).set({
    if (data['name'] != null) 'name': data['name'],
    if (data['city'] != null) 'city': data['city'],
    'rankScore': newRankScore,
    'lastUpdated': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  return newRankScore;
}

double calculateRankScore({
  required int marks,
  required int totalQ,
  required int attemptedQ,
}) {
  if (totalQ == 0 || attemptedQ == 0) return 0.0;

  final percentTotal = (marks / totalQ) * 100;
  final percentAttempted = (marks / attemptedQ) * 100;
  final avg = (percentTotal + percentAttempted) / 2;

  return double.parse((avg * (attemptedQ * 0.01)).toStringAsFixed(1));
}
