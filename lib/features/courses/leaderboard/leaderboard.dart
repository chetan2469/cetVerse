import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor =
        const Color.fromARGB(255, 3, 107, 176); // 🔥 your app theme color
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Leaderboard"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaderboard')
            .orderBy('rankScore', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No leaderboard data yet"));
          }

          // Top 3 users
          final topUsers = docs.take(3).toList();
          final others = docs.skip(3).toList();
          final myIndex = docs.indexWhere((d) => d.id == userPhoneNumber);

          return Container(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                // 🏆 Top 3 podium layout
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPodiumUser(topUsers.length > 2 ? topUsers[2] : null,
                          3, themeColor,
                          height: 100),
                      _buildPodiumUser(topUsers.length > 1 ? topUsers[1] : null,
                          2, themeColor,
                          height: 140),
                      _buildPodiumUser(topUsers.isNotEmpty ? topUsers[0] : null,
                          1, themeColor,
                          height: 180),
                    ],
                  ),
                ),

                // 🙋 My profile card
                if (myIndex != -1)
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade100, Colors.purple.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(docs[myIndex]['name'] ?? "Me",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(
                                "Points: ${(docs[myIndex]['rankScore'] as num).toDouble() * 10 ~/ 1}",
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Text("Position: ${myIndex + 1}"),
                        // Column(
                        //   crossAxisAlignment: CrossAxisAlignment.end,
                        //   children: [
                        //     const Text("Level: Silver 🏅"),
                        //     Text("Position: ${myIndex + 1}"),
                        //   ],
                        // )
                      ],
                    ),
                  ),

                // 📋 Other users list
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(4),
                      itemCount: others.length,
                      itemBuilder: (context, index) {
                        final doc = others[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final rank = index + 4; // since 1–3 are podium
                        final score =
                            (data['rankScore'] ?? 0.0 as num).toDouble();

                        return ListTile(
                          leading: Text(
                            rank.toString().padLeft(2, "0"),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          title: Text(data['name'] ?? "Unknown",
                              style: const TextStyle(fontSize: 16)),
                          subtitle: Text(
                            "${(score * 10).toStringAsFixed(0)} pts",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          trailing: Icon(Icons.emoji_events,
                              color: themeColor, size: 18),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodiumUser(
      QueryDocumentSnapshot<Object?>? doc, int rank, Color themeColor,
      {required double height}) {
    if (doc == null) {
      return SizedBox(height: height, width: 80);
    }

    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? "User";

    // Safe parsing of rankScore from Firestore (num or String)
    final rawScore = data['rankScore'];
    double score;
    if (rawScore == null) {
      score = 0.0;
    } else if (rawScore is num) {
      score = rawScore.toDouble();
    } else {
      // if it's a String or something else, try parsing
      score = double.tryParse(rawScore.toString()) ?? 0.0;
    }

    final scoreDisplay = (score * 10).toStringAsFixed(0);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: themeColor.withOpacity(0.2),
            child: const Icon(Icons.person, size: 28, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text("$scoreDisplay pts",
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            height: height,
            width: 70,
            alignment: Alignment.topCenter,
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
