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
  State<ChapterWiseTest> createState() => _ChapterWiseTestState();
}

class _ChapterWiseTestState extends State<ChapterWiseTest> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMcqs = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchMcqs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error initializing data: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMcqs() async {
    setState(() => _isLoading = true);
    try {
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
          return {...data, 'docId': doc.id};
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading MCQs: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _fetchMcqs();
  }

  // Split MCQs into tests of 20 each
  List<List<Map<String, dynamic>>> _groupMcqsIntoTests() {
    const int testSize = 20;
    final tests = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < _allMcqs.length; i += testSize) {
      tests.add(_allMcqs.sublist(i,
          (i + testSize > _allMcqs.length) ? _allMcqs.length : i + testSize));
    }
    return tests;
  }

  bool _isTestAccessible(BuildContext context, int testIndexZeroBased) {
    final auth = context.read<AuthProvider>();
    if (auth.fullMockTestSeries) return true; // Pro = unlimited
    // Starter/Plus: only first N tests allowed (N = mockTestsPerSubject)
    final max = auth.mockTestsPerSubject; // Starter=1, Plus=2
    return testIndexZeroBased < max;
  }

  Widget _buildTestLeadingIcon(BuildContext context, int testIndexZeroBased) {
    final locked = !_isTestAccessible(context, testIndexZeroBased);
    if (locked) {
      return Image.asset("assets/crown.png",
          width: 24, height: 24, fit: BoxFit.contain);
    }
    return const Icon(Icons.auto_fix_high, size: 20);
  }

  void _handleTestTap(BuildContext context, int testIndexZeroBased,
      List<Map<String, dynamic>> testMcqs) {
    if (!_isTestAccessible(context, testIndexZeroBased)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Upgrade plan to unlock more chapter-wise tests")),
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
          testNumber: testIndexZeroBased + 1,
          mcqs: testMcqs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tests = _groupMcqsIntoTests();
    final auth = context.watch<AuthProvider>(); // to reflect plan changes live

    final displayLevel = widget.level == '12th Standard'
        ? 'Class 12'
        : widget.level == '11th Standard'
            ? 'Class 11'
            : widget.level;

    final subtitleText = auth.fullMockTestSeries
        ? 'Unlimited tests (Pro)'
        : 'First ${auth.mockTestsPerSubject} tests available';

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
              ? const Center(child: Text("No tests available."))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  backgroundColor: Colors.white,
                  color: Colors.indigoAccent,
                  strokeWidth: 3.0,
                  displacement: 40.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0, left: 4.0, right: 4.0),
                          child: Text(
                            subtitleText,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: tests.length,
                            itemBuilder: (context, index) {
                              final testMcqs = tests[index];
                              final locked = !_isTestAccessible(context, index);

                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.only(bottom: 20),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  title: Text(
                                    "Mock Test ${index + 1}",
                                    style: AppTheme.subheadingStyle
                                        .copyWith(fontSize: 16),
                                  ),
                                  leading:
                                      _buildTestLeadingIcon(context, index),
                                  trailing: Text(
                                      "${testMcqs.length} Que | ${testMcqs.length} mark"),
                                  onTap: () =>
                                      _handleTestTap(context, index, testMcqs),
                                  subtitle: locked
                                      ? const Text('Locked — Upgrade to access',
                                          style: TextStyle(color: Colors.red))
                                      : null,
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
