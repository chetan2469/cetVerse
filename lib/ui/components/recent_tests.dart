import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RecentTestsPage extends StatefulWidget {
  const RecentTestsPage({super.key});

  @override
  State<RecentTestsPage> createState() => _RecentTestsPageState();
}

class _RecentTestsPageState extends State<RecentTestsPage> {
  List<Map<String, dynamic>> recentTests = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentTests();
  }

  Future<void> _loadRecentTests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;
    try {
      if (userPhoneNumber != null) {
        final testHistorySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userPhoneNumber)
            .collection('testHistory')
            .orderBy('timestamp', descending: true)
            .limit(25)
            .get();

        final pyqHistorySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userPhoneNumber)
            .collection('pyqHistory')
            .orderBy('timestamp', descending: true)
            .limit(25)
            .get();

        List<Map<String, dynamic>> allTests = [];

        for (var doc in testHistorySnapshot.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            allTests.add({
              'testId':
                  '${data['subject']} ${data['chapter']} Test ${data['testnumber']}',
              'score': (data['score'] as num?)?.toDouble() ?? 0.0,
              'date': DateFormat('MMM dd, yyyy').format(timestamp.toDate()),
              'timestamp': timestamp.toDate(),
              'type': 'mock',
              'accuracy': data['accuracy'],
            });
          }
        }

        for (var doc in pyqHistorySnapshot.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            allTests.add({
              'testId': 'PYQ ${data['year']} ${data['pyqType']}',
              'score': (data['score'] as num?)?.toDouble() ?? 0.0,
              'date': DateFormat('MMM dd, yyyy').format(timestamp.toDate()),
              'timestamp': timestamp.toDate(),
              'type': 'pyq',
              'accuracy': data['accuracy'],
            });
          }
        }

        allTests.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
        setState(() {
          recentTests = allTests;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingRecent = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch tests result: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recent Tests',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: _isLoadingRecent
          ? const Center(child: CircularProgressIndicator()) // ✅ Loading
          : recentTests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tests taken yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: recentTests.length,
                  itemBuilder: (context, index) {
                    final test = recentTests[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: test['type'] == 'mock'
                                  ? Colors.blue.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              test['type'] == 'mock'
                                  ? Icons.quiz
                                  : Icons.history_edu,
                              size: 16,
                              color: test['type'] == 'mock'
                                  ? Colors.blue.shade600
                                  : Colors.orange.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test['testId'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  test['date'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${test['accuracy']}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
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
}
