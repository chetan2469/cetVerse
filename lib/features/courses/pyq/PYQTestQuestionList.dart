import 'package:cet_verse/features/courses/pyq/UpdatePyqMcq.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class PYQTestQuestionList extends StatefulWidget {
  final String docId;
  final String testName;

  const PYQTestQuestionList({
    super.key,
    required this.docId,
    required this.testName,
  });

  @override
  _PYQTestQuestionListState createState() => _PYQTestQuestionListState();
}

class _PYQTestQuestionListState extends State<PYQTestQuestionList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMcqs = [];

  @override
  void initState() {
    super.initState();
    _fetchMcqs();
  }

  Future<void> _fetchMcqs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pyq')
          .doc(widget.docId)
          .collection('test')
          .get();

      setState(() {
        _allMcqs = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'questionId': doc.id,
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: Text(
            "${widget.testName} MCQs",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
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
                        return _buildMCQPreviewCard(mcqData, index + 1);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildMCQPreviewCard(Map<String, dynamic> mcq, int number) {
    final questionMap = mcq['question'] as Map<String, dynamic>? ?? {};
    final String questionText = questionMap['text'] ?? "";
    final String questionId = mcq['questionId'] as String;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Q$number.",
                  style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: "Edit MCQ",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdatePyqMcq(
                              docId: widget.docId,
                              questionId: questionId,
                              mcq: mcq,
                            ),
                          ),
                        ).then((_) => _fetchMcqs());
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              questionText,
              style: AppTheme.subheadingStyle.copyWith(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
