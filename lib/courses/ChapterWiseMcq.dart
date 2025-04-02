import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/MyDrawer.dart';
import 'package:cet_verse/constants.dart';
import 'package:cet_verse/courses/AddMCQ.dart';
import 'package:cet_verse/courses/UpdateMCQ.dart';

class ChapterWiseMcq extends StatefulWidget {
  final String level; // e.g. "11th Standard"
  final String subject; // e.g. "Biology"
  final String chapter; // e.g. "Diversity in Organisms"

  const ChapterWiseMcq({
    super.key,
    required this.level,
    required this.subject,
    required this.chapter,
  });

  @override
  _ChapterWiseMcqState createState() => _ChapterWiseMcqState();
}

class _ChapterWiseMcqState extends State<ChapterWiseMcq> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMcqs = [];

  @override
  void initState() {
    super.initState();
    _fetchMcqs();
  }

  /// Fetch all MCQs from Firestore for the given level/subject/chapter
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

      setState(() {
        _allMcqs = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
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

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        drawer: const MyDrawer(),
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            "${widget.chapter} MCQs",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              tooltip: "Add New MCQ",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMCQ(
                      level: widget.level,
                      subject: widget.subject,
                      chapter: widget.chapter,
                    ),
                  ),
                ).then((_) => _fetchMcqs()); // Reload after adding MCQ
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allMcqs.isEmpty
                ? const Center(
                    child: Text(
                      "No MCQs found.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _allMcqs.length,
                      itemBuilder: (context, index) {
                        final mcqData = _allMcqs[index];
                        return _buildMCQPaperCard(mcqData, index + 1);
                      },
                    ),
                  ),
      ),
    );
  }

  /// Builds a card for each MCQ with question, options, and explanation
  Widget _buildMCQPaperCard(Map<String, dynamic> mcq, int number) {
    // Extract fields from the MCQ document
    final questionMap = mcq['question'] as Map<String, dynamic>? ?? {};
    final String questionText = questionMap['text'] ?? "";
    final String questionImage = questionMap['image'] ?? "";

    final optionsMap = mcq['options'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionA =
        optionsMap['A'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionB =
        optionsMap['B'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionC =
        optionsMap['C'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionD =
        optionsMap['D'] as Map<String, dynamic>? ?? {};

    final String aText = optionA['text'] ?? "";
    final String aImage = optionA['image'] ?? "";
    final String bText = optionB['text'] ?? "";
    final String bImage = optionB['image'] ?? "";
    final String cText = optionC['text'] ?? "";
    final String cImage = optionC['image'] ?? "";
    final String dText = optionD['text'] ?? "";
    final String dImage = optionD['image'] ?? "";

    final String answer = mcq['answer'] ?? "A";
    final explanationMap = mcq['explanation'] as Map<String, dynamic>? ?? {};
    final String explanationText =
        explanationMap['text'] ?? "No explanation given.";
    final String explanationImage = explanationMap['image'] ?? "";
    final docId = mcq['docId'] as String;

    return Card(
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number and edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Q$number.",
                  style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: "Edit MCQ",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UpdateMCQ(
                          level: widget.level,
                          subject: widget.subject,
                          chapter: widget.chapter,
                          mcq: mcq,
                          docId: docId,
                        ),
                      ),
                    ).then((_) => _fetchMcqs());
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Question text
            Text(
              questionText,
              style: AppTheme.subheadingStyle.copyWith(fontSize: 14),
            ),

            // Question image
            if (questionImage.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildImage(questionImage),
            ],
            const SizedBox(height: 12),

            // Options
            _buildOptionRow("A", aText, aImage, answer),
            const SizedBox(height: 8),
            _buildOptionRow("B", bText, bImage, answer),
            const SizedBox(height: 8),
            _buildOptionRow("C", cText, cImage, answer),
            const SizedBox(height: 8),
            _buildOptionRow("D", dText, dImage, answer),
            const SizedBox(height: 12),

            // Explanation text
            Text(
              "Explanation: $explanationText",
              style: AppTheme.captionStyle.copyWith(fontSize: 14),
            ),

            // Explanation image
            if (explanationImage.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildImage(explanationImage),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds an option row with text and optional image
  Widget _buildOptionRow(
    String label,
    String text,
    String imageUrl,
    String correctAnswer,
  ) {
    final bool isCorrect = (label == correctAnswer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$label: ",
              style: TextStyle(
                color: isCorrect ? Colors.green : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        if (imageUrl.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildImage(imageUrl),
        ],
      ],
    );
  }

  /// Reusable image widget with error handling
  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        height: 70,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 70,
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.error, color: Colors.red)),
        ),
      ),
    );
  }
}
