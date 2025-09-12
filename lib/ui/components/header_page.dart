import 'package:cet_verse/core/models/user_model.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';

class HeaderPage extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onDrawerOpen;

  const HeaderPage({super.key, required this.user, required this.onDrawerOpen});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: onDrawerOpen,
        icon: const Icon(Icons.menu),
      ),
      title: Text(
        "Hello, ${user?.name ?? 'User'}!",
        style: AppTheme.headingStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "Lets Practice",
        style: AppTheme.captionStyle,
      ),
      trailing: InkWell(
        onTap: () {
          // buildLeaderboardFromHistory();
        },
        child: Container(
          child: Image.asset('assets/logo.png'),
        ),
      ),
    );
  }

  // Future<void> buildLeaderboardFromHistory() async {
  //   print("STARTING");
  //   final firestore = FirebaseFirestore.instance;

  //   // Fetch all users
  //   final usersSnapshot = await firestore.collection('users').get();

  //   for (final userDoc in usersSnapshot.docs) {
  //     final userId = userDoc.id;
  //     final userData = userDoc.data();

  //     final name = userData['name'] ?? "Unknown";
  //     final city = userData['city'] ?? "";

  //     int totalScore = 0;
  //     int totalTests = 0;
  //     int totalAttempted = 0;
  //     int totalWrong = 0;
  //     int totalUnattempted = 0;
  //     double totalAccuracySum = 0.0;

  //     // 🔹 Helper: process a history collection (safe if not exists)
  //     Future<void> processHistory(String collection) async {
  //       final snap = await firestore
  //           .collection('users')
  //           .doc(userId)
  //           .collection(collection)
  //           .get();

  //       if (snap.docs.isEmpty) return;

  //       for (final doc in snap.docs) {
  //         final data = doc.data();

  //         totalScore += (data['score'] ?? 0) as int;
  //         totalAttempted += (data['attempted'] ?? 0) as int;
  //         totalWrong += (data['wrong'] ?? 0) as int;
  //         totalUnattempted += (data['unattempted'] ?? 0) as int;

  //         // accuracy can be stored as string or num
  //         final accRaw = data['accuracy'];
  //         double acc = 0.0;
  //         if (accRaw is num) acc = accRaw.toDouble();
  //         if (accRaw is String) acc = double.tryParse(accRaw) ?? 0.0;

  //         totalAccuracySum += acc;
  //         totalTests++;
  //       }
  //     }

  //     // 🔹 Process pyqHistory & testHistory safely
  //     await processHistory("pyqHistory");
  //     await processHistory("testHistory");

  //     // 🔹 Calculate avgAccuracy & rankScore
  //     final avgAccuracy = totalTests > 0 ? totalAccuracySum / totalTests : 0.0;

  //     final rankScore = totalAttempted > 0
  //         ? (totalScore / totalAttempted) * avgAccuracy
  //         : 0.0;

  //     final formattedRankScore = double.parse(rankScore.toStringAsFixed(1));

  //     // 🔹 Build stats map (all zero if no tests)
  //     final updatedStats = {
  //       "totalScore": totalScore,
  //       "totalTests": totalTests,
  //       "totalAttempted": totalAttempted,
  //       "totalWrong": totalWrong,
  //       "totalUnattempted": totalUnattempted,
  //       "totalAccuracySum": double.parse(totalAccuracySum.toStringAsFixed(2)),
  //       "rankScore": formattedRankScore,
  //       "lastUpdated": FieldValue.serverTimestamp(),
  //     };

  //     // 🔹 Update stats inside user doc (create if missing)
  //     await firestore.collection('users').doc(userId).set({
  //       "stats": updatedStats,
  //     }, SetOptions(merge: true));

  //     // 🔹 Store into leaderboard (always)
  //     await firestore.collection('leaderboard').doc(userId).set({
  //       "name": name,
  //       "city": city,
  //       "rankScore": formattedRankScore,
  //       "totalScore": totalScore,
  //       "totalTests": totalTests,
  //       "avgAccuracy": double.parse(avgAccuracy.toStringAsFixed(2)),
  //       "totalAttempted": totalAttempted,
  //       "totalWrong": totalWrong,
  //       "totalUnattempted": totalUnattempted,
  //       "lastUpdated": FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //   }

  //   print(
  //       "✅ Leaderboard + user stats rebuilt successfully (zero defaults applied).");
  // }
}
