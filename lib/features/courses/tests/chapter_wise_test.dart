import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/tests/test_confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class ChapterWiseTest extends StatefulWidget {
  final String level;
  final String subject;
  final String chapter;

  const ChapterWiseTest({
    super.key,
    required this.level,
    required this.subject,
    required this.chapter,
  });

  @override
  _ChapterWiseTestState createState() => _ChapterWiseTestState();
}

class _ChapterWiseTestState extends State<ChapterWiseTest> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMcqs = [];
  bool _hasFullAccess = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchMcqs();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phoneNumber = authProvider.userPhoneNumber;
      if (phoneNumber == null) {
        throw Exception("User phone number is not available");
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userType = userData['userType'] as String?;
        final subscription = userData['subscription'] as Map<String, dynamic>?;
        final planType =
            subscription != null ? subscription['planType'] as String? : null;

        setState(() {
          _hasFullAccess = userType == 'Admin' || planType == 'Subscribed';
        });

        authProvider.userType = userType;
        authProvider.planType = planType;
        authProvider.notifyListeners();
      } else {
        throw Exception("User data not found");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error initializing data: $e")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMcqs() async {
    try {
      setState(() {
        _isLoading = true; // Show loading during fetch
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(widget.chapter)
          .collection('mcqs')
          .get();

      setState(() {
        _allMcqs = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'docId': doc.id,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading MCQs: $e")),
      );
    }
  }

  Future<void> _refresh() async {
    try {
      await _fetchMcqs(); // Reload MCQs
      await _initializeData(); // Reload user access status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error refreshing: $e")),
      );
    }
  }

  List<List<Map<String, dynamic>>> _groupMcqsIntoTests() {
    const int testSize = 20;
    List<List<Map<String, dynamic>>> tests = [];
    for (int i = 0; i < _allMcqs.length; i += testSize) {
      tests.add(_allMcqs.sublist(
          i, i + testSize > _allMcqs.length ? _allMcqs.length : i + testSize));
    }
    return tests;
  }

  bool _isTestAccessible(int testIndex) {
    if (testIndex == 0) return true;
    return _hasFullAccess;
  }

  Widget _buildTestTrailingIcon(int testIndex) {
    if (!_isTestAccessible(testIndex)) {
      return Image.asset("assets/crown.png"); // Replace Icon with Image.asset
    }
    return const Icon(Icons.auto_fix_high, size: 16);
  }

  void _handleTestTap(int testIndex, List<Map<String, dynamic>> testMcqs) {
    if (!_isTestAccessible(testIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upgrade to Premium or Admin access required"),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestConfirmationPage(
          level: widget.level,
          subject: widget.subject,
          chapter: widget.chapter,
          testNumber: testIndex + 1,
          mcqs: testMcqs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tests = _groupMcqsIntoTests();
    final authProvider = Provider.of<AuthProvider>(context);
    final displayLevel = widget.level == '12th Standard'
        ? 'Class 12'
        : widget.level == '11th Standard'
            ? 'Class 11'
            : widget.level;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.chapter} Tests ($displayLevel)",
          style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
        ),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : tests.isEmpty
              ? const Center(
                  child: Text(
                    "No tests available.",
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  backgroundColor: Colors.white,
                  color: Colors.indigoAccent, // Matches app theme
                  strokeWidth: 3.0,
                  displacement: 40.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: tests.length,
                            itemBuilder: (context, index) {
                              final testMcqs = tests[index];
                              final isAccessible = _isTestAccessible(index);

                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  title: Text(
                                    "Mock Test ${index + 1}",
                                    style: AppTheme.subheadingStyle.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                                  leading: _buildTestTrailingIcon(index),
                                  trailing: Text(
                                      "${testMcqs.length} Que | ${testMcqs.length} mark"),
                                  onTap: () => _handleTestTap(index, testMcqs),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
