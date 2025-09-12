import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/courses/TimerController.dart';
import 'package:cet_verse/features/courses/pyq/tests/new_test_view/test_provider.dart';
import 'package:cet_verse/features/courses/pyq/tests/new_test_view/widets.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void showStartConfirmation(
    BuildContext context, TimerController timerController) {
  final int totalQuestions =
      Provider.of<TestProvider>(context, listen: false).pyqType.toLowerCase() ==
              'pcm'
          ? 150
          : 200;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        insetPadding: const EdgeInsets.all(0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF8F8F8), // Light gray
                Colors.white,
                Color(0xFFF5F5F5), // Off-white
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(40),
                          border:
                              Border.all(color: Colors.grey.shade400, width: 2),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'MHT CET ${Provider.of<TestProvider>(context, listen: false).year}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${Provider.of<TestProvider>(context, listen: false).pyqType.toUpperCase()} Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildPaperStatColumn('$totalQuestions', 'Questions',
                              Icons.quiz, Colors.blueGrey),
                          buildPaperStatColumn('180 min', 'Duration',
                              Icons.schedule, Colors.blueGrey),
                          buildPaperStatColumn(
                              '200', 'Marks', Icons.star, Colors.blueGrey),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blueGrey, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Test Instructions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      buildPaperInstruction(
                        Icons.timer,
                        'Auto-submit when time expires',
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      buildPaperInstruction(
                        Icons.radio_button_checked,
                        'Multiple choice questions with single correct answer',
                        Colors.blueGrey,
                      ),
                      const SizedBox(height: 12),
                      buildPaperInstruction(
                        Icons.pause_circle_outline,
                        'Test cannot be paused for fair ranking',
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      final provider =
                          Provider.of<TestProvider>(context, listen: false);
                      provider.confirmStart();

                      // Wrap _submitTest in a closure to pass required args
                      timerController.initialize(10800, () {
                        _submitTest(provider, timerController, context);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      'Start Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showSubmitConfirmation(BuildContext context, TestProvider provider,
    TimerController timerController) {
  int attemptedCount = provider.userAnswers.where((a) => a != -1).length;
  int unattemptedCount = provider.userAnswers.where((a) => a == -1).length;
  int reviewCount = provider.reviewedQuestions.length;
  String timeLeft = timerController.formatTime(timerController.timeRemaining);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      title: const Text(
        'Submit Test?',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
      content: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildPaperSubmitStatRow(Icons.check_circle, 'Attempted',
                '$attemptedCount', Colors.green),
            const SizedBox(height: 8),
            buildPaperSubmitStatRow(Icons.radio_button_unchecked, 'Unattempted',
                '$unattemptedCount', Colors.red),
            const SizedBox(height: 8),
            buildPaperSubmitStatRow(
                Icons.bookmark, 'For Review', '$reviewCount', Colors.orange),
            const SizedBox(height: 8),
            buildPaperSubmitStatRow(
                Icons.schedule, 'Time Left', timeLeft, Colors.blueGrey),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _submitTest(provider, timerController, context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Colors.green, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Submit Test'),
        ),
      ],
    ),
  );
}

void _submitTest(TestProvider provider, TimerController timerController,
    BuildContext context) async {
  if (provider.hasSubmitted) return;

  // Mark as submitted
  provider.submitTest();
  timerController.stop();

  int totalScore = 0;
  int correctCount = 0;
  int unansweredCount = 0;

  for (int i = 0; i < provider.mcqs.length; i++) {
    final mcq = provider.mcqs[i];
    final subject = mcq['subject'] as String?;

    if (provider.userAnswers[i] == -1) {
      unansweredCount++;
      continue;
    }

    final correctIndex =
        provider.answerToIndex(mcq['answer'] as String? ?? "A");
    if (provider.userAnswers[i] == correctIndex) {
      correctCount++;
      if (provider.pyqType.toLowerCase() == 'pcm' && subject == 'Maths') {
        totalScore += 2;
      } else {
        totalScore += 1;
      }
    }
  }

  final totalQuestions = provider.mcqs.length;
  final attemptedCount = totalQuestions - unansweredCount;
  final wrongCount = attemptedCount - correctCount;
  final accuracy = attemptedCount > 0
      ? (correctCount / attemptedCount * 100).toStringAsFixed(6)
      : '0.0';
  final timeLeft = timerController.formatTime(timerController.timeRemaining);

  // Show loading dialog while saving to Firebase
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  // Save result to Firebase
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;
    if (userPhoneNumber != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('pyqHistory')
          .add({
        'year': provider.year,
        'pyqType': provider.pyqType,
        'accuracy': accuracy,
        'correct': correctCount,
        'score': totalScore,
        'timeleft': timeLeft,
        'timestamp': FieldValue.serverTimestamp(),
        'attempted': attemptedCount, //new
        'unattempted': unansweredCount,
        'wrong': wrongCount,
        'totalQuestion': totalQuestions, //new
      });

      //   await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(userPhoneNumber)
      //       .update({
      //     'stats.totalTestMark': FieldValue.increment(totalQuestions),
      //     'stats.totalScore': FieldValue.increment(correctCount),
      //     'stats.totalWrong': FieldValue.increment(wrongCount),
      //     'stats.totalAttempted': FieldValue.increment(attemptedCount),
      //     'stats.totalUnattempted': FieldValue.increment(unansweredCount),
      //     'stats.totalAccuracy': FieldValue.increment(double.parse(accuracy)),
      //     'stats.totalTests': FieldValue.increment(1),
      //     'stats.lastUpdated': FieldValue.serverTimestamp(),
      //   });

      // 2. Fetch existing stats + user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .get();

      final data = userDoc.data() ?? {};
      final stats = Map<String, dynamic>.from(data['stats'] ?? {});

      final oldScore = (stats['rankScore'] ?? 0.0).toDouble();
      final oldAttempts = (stats['totalAttempted'] ?? 0).toDouble();
      final oldTotalScore = (stats['totalScore'] ?? 0).toInt();
      final oldTotalWrong = (stats['totalWrong'] ?? 0).toInt();
      final oldAccuracySum = (stats['totalAccuracySum'] ?? 0.0).toDouble();
      final oldTests = (stats['totalTests'] ?? 0).toInt();

      final newAttempts = attemptedCount.toDouble();
      final newAccuracy =
          attemptedCount > 0 ? correctCount / attemptedCount : 0.0;

      // 3. Apply PDF formula (rolling score)
      final newRankScore = (oldAttempts + newAttempts) == 0
          ? newAccuracy
          : ((oldScore * oldAttempts) + (newAccuracy * newAttempts)) /
              (oldAttempts + newAttempts);

      final formattedRankScore = double.parse(newRankScore.toStringAsFixed(1));

      // 4. Build new stats map
      final updatedStats = {
        'totalScore': oldTotalScore + correctCount,
        'totalWrong': oldTotalWrong + wrongCount,
        'totalAttempted': oldAttempts.toInt() + attemptedCount,
        'totalAccuracySum': oldAccuracySum + double.parse(accuracy),
        'totalTests': oldTests + 1,
        'rankScore': formattedRankScore,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // 5. Update user stats (replace whole map)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .update({'stats': updatedStats});

      // 6. Update leaderboard entry
      await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc(userPhoneNumber)
          .set({
        if (data['name'] != null) 'name': data['name'],
        if (data['city'] != null) 'city': data['city'],
        'rankScore': formattedRankScore,
        'totalScore': updatedStats['totalScore'],
        'totalTests': updatedStats['totalTests'],
        'avgAccuracy': double.parse(
            (updatedStats['totalAccuracySum'] / updatedStats['totalTests'])
                .toStringAsFixed(6)),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  } catch (e) {
    // Handle Firebase errors if needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to submit test: $e')),
    );
  } finally {
    Navigator.pop(context); // Close loading dialog
  }

  // Navigate to result page
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => TestResultPage(
        mcqs: provider.mcqs,
        userAnswers: provider.userAnswers,
        correctCount: correctCount,
        unansweredCount: unansweredCount,
        timeTaken: timeLeft,
      ),
    ),
  );
}
