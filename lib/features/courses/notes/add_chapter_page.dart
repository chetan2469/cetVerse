import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cet_verse/ui/theme/constants.dart';

class AddChapterPage extends StatefulWidget {
  final String level; // e.g., "11th Standard"
  final String subject; // e.g., "Physics"

  const AddChapterPage({
    super.key,
    required this.level,
    required this.subject,
  });

  @override
  State<AddChapterPage> createState() => _AddChapterPageState();
}

class _AddChapterPageState extends State<AddChapterPage> {
  final TextEditingController _chapterNameController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          "Add Chapter",
          style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status message
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],

            TextField(
              controller: _chapterNameController,
              decoration: InputDecoration(
                labelText: "Chapter Name",
                hintText: "e.g. Force, Momentum, etc.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _addChapterToFirestore,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Add Chapter", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addChapterToFirestore() async {
    final chapterName = _chapterNameController.text.trim();
    if (chapterName.isEmpty) {
      setState(() {
        _statusMessage = "Please enter a chapter name.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(chapterName);

      // default fields (example)
      final chapterData = {
        "name": chapterName,
        "dependencies": <String>[], // empty list or some default
        "practicals": <String>[], // empty list or some default
        "weightage": "", // or "5%"
        "resources": {
          "notes": "",
          "pdf": "",
          "video": "",
        },
      };

      // Overwrite or merge doc if needed:
      await docRef.set(chapterData);

      setState(() {
        _statusMessage = "Chapter '$chapterName' added successfully!";
      });
      _chapterNameController.clear();
    } catch (e) {
      setState(() {
        _statusMessage = "Error adding chapter: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
