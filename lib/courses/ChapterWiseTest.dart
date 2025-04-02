import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/MyDrawer.dart'; // optional if you want to use a drawer
import 'package:cet_verse/constants.dart'; // Your AppTheme or color definitions

import 'QuestionTestPage.dart'; // The page to display the chosen test questions

class ChapterWiseTest extends StatefulWidget {
  final String level; // e.g., "11th Standard"
  final String subject; // e.g., "Biology"
  final String chapter; // e.g., "Diversity in Organisms"

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
  List<List<Map<String, dynamic>>> _tests = []; // Each list is up to 20 MCQs
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchMcqs();
  }

  /// Fetches all MCQs from Firestore and splits them into sets of 20
  Future<void> _fetchMcqs() async {
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

      final mcqs = snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      setState(() {
        _allMcqs = mcqs;
        _tests = _splitIntoTests(mcqs, 20);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error loading MCQs: $e";
      });
    }
  }

  /// Splits a list of MCQs into chunks (20 each by default)
  List<List<Map<String, dynamic>>> _splitIntoTests(
      List<Map<String, dynamic>> mcqs, int chunkSize) {
    List<List<Map<String, dynamic>>> results = [];
    for (var i = 0; i < mcqs.length; i += chunkSize) {
      final end = (i + chunkSize < mcqs.length) ? i + chunkSize : mcqs.length;
      results.add(mcqs.sublist(i, end));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        drawer: const MyDrawer(), // Optional drawer
        backgroundColor:
            AppTheme.scaffoldBackground, // Use your AppTheme background
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "${widget.chapter} Tests",
            style: AppTheme.subheadingStyle, // Use subheading style from theme
          ),
          elevation: 1,
          backgroundColor: Colors.white,
          centerTitle: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_statusMessage.isNotEmpty) {
      return Center(
        child: Text(
          _statusMessage,
          style: AppTheme.captionStyle
              .copyWith(color: Colors.red), // styled error message
        ),
      );
    }
    if (_allMcqs.isEmpty) {
      return Center(
        child: Text(
          "No MCQs found in this chapter.",
          style: AppTheme.captionStyle,
        ),
      );
    }

    // Builds a list of cards, each representing a "Test #index+1"
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _tests.length,
        itemBuilder: (context, index) 
        {
          final testNumber = index + 1;
          final questionCount = _tests[index].length; // up to 20

          return _buildTestTile(
            context,
            testNumber,
            questionCount,
            _tests[index],
          );
        },
      ),
    );
  }

  Widget _buildTestTile(BuildContext context, int testNumber, int questionCount,
      List<Map<String, dynamic>> mcqsForTest) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          "Test $testNumber",
          style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
        ),
        subtitle: Text(
          "$questionCount questions available",
          style: AppTheme.captionStyle,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to QuestionTestPage with these 20 MCQs
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionTestPage(
                level: widget.level,
                subject: widget.subject,
                chapter: widget.chapter,
                testNumber: testNumber,
                mcqs: mcqsForTest,
              ),
            ),
          );
        },
      ),
    );
  }
}
