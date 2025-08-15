import 'package:cet_verse/features/courses/mcq/add_mcq.dart';
import 'package:cet_verse/features/courses/mcq/display_mcq.dart';
import 'package:cet_verse/features/courses/mcq/update_mcq.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class ChapterWiseMcq extends StatefulWidget {
  final String level; // e.g. "11th Standard"
  final String subject; // e.g. "Biology"
  final String chapter; // e.g. "Diversity in Organisms"

  const ChapterWiseMcq(
      {super.key,
      required this.level,
      required this.subject,
      required this.chapter});

  @override
  _ChapterWiseMcqState createState() => _ChapterWiseMcqState();
}

class _ChapterWiseMcqState extends State<ChapterWiseMcq> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMcqs = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadErrorMessage;

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

  Future<Map<String, dynamic>> _validateJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);

      if (jsonData.isEmpty) {
        return {
          'success': false,
          'error': 'JSON array is empty. Must contain at least one MCQ.',
        };
      }

      final List<String> errorMessages = [];

      for (var i = 0; i < jsonData.length; i++) {
        final item = jsonData[i];
        if (item is! Map<String, dynamic>) {
          errorMessages.add(
              'Element ${i + 1} is not an object. Each MCQ must be a JSON object.');
          continue;
        }

        final requiredFields = ['question', 'options', 'answer', 'explanation'];
        final missingFields =
            requiredFields.where((field) => !item.containsKey(field)).toList();
        if (missingFields.isNotEmpty) {
          errorMessages.add(
              'Element ${i + 1} is missing fields: ${missingFields.join(', ')}.');
        }

        if (item['question'] is! Map<String, dynamic> ||
            !item['question'].containsKey('text') ||
            !item['question'].containsKey('image')) {
          errorMessages.add(
              'Element ${i + 1} has invalid question format. Must have "text" and "image".');
        }

        if (item['options'] is! Map<String, dynamic> ||
            !['A', 'B', 'C', 'D']
                .every((opt) => item['options'].containsKey(opt))) {
          errorMessages.add(
              'Element ${i + 1} has invalid options format. Must have "A", "B", "C", "D".');
        } else {
          for (var opt in ['A', 'B', 'C', 'D']) {
            final option = item['options'][opt];
            if (option is! Map<String, dynamic> ||
                !option.containsKey('text') ||
                !option.containsKey('image')) {
              errorMessages.add(
                  'Element ${i + 1} option $opt invalid. Must have "text" and "image".');
            }
          }
        }

        if (!['A', 'B', 'C', 'D'].contains(item['answer'])) {
          errorMessages.add(
              'Element ${i + 1} has invalid answer. Must be "A", "B", "C", or "D".');
        }

        if (item['explanation'] is! Map<String, dynamic> ||
            !item['explanation'].containsKey('text') ||
            !item['explanation'].containsKey('image')) {
          errorMessages.add(
              'Element ${i + 1} has invalid explanation format. Must have "text" and "image".');
        }

        // Subject and origin are optional, but if present, check types
        if (item.containsKey('subject') && item['subject'] is! String) {
          errorMessages.add('Element ${i + 1} subject must be a string.');
        }
        if (item.containsKey('origin') && item['origin'] is! String) {
          errorMessages.add('Element ${i + 1} origin must be a string.');
        }
      }

      if (errorMessages.isNotEmpty) {
        return {
          'success': false,
          'error': errorMessages.take(5).join('\n') +
              (errorMessages.length > 5 ? '\n...' : ''),
        };
      }

      return {
        'success': true,
        'data': jsonData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Invalid JSON format: $e. Must be an array of MCQ objects.',
      };
    }
  }

  Future<void> _uploadMcqs(List<dynamic> jsonData) async {
    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(widget.chapter)
          .collection('mcqs');

      int processed = 0;
      for (var item in jsonData) {
        await collectionRef.add(item);
        processed++;
        setState(() {
          _uploadProgress = processed / jsonData.length;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MCQs uploaded successfully!')),
      );
      _fetchMcqs();
    } catch (e) {
      setState(() {
        _uploadErrorMessage = 'Error uploading MCQs: $e';
      });
    }
  }

  Future<void> _pickAndUploadJson() async {
    setState(() {
      _isUploading = true;
      _uploadErrorMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _uploadErrorMessage = 'No file selected.';
          _isUploading = false;
        });
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final validationResult = await _validateJson(jsonString);
      if (!validationResult['success']) {
        setState(() {
          _uploadErrorMessage = validationResult['error'];
          _isUploading = false;
        });
        return;
      }

      await _uploadMcqs(validationResult['data'] as List<dynamic>);
    } catch (e) {
      setState(() {
        _uploadErrorMessage = 'Error processing file: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
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
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "${widget.chapter} MCQs",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 12),
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
            IconButton(
              icon: const Icon(Icons.upload_file, color: Colors.black),
              tooltip: "Upload JSON MCQs",
              onPressed: _isUploading ? null : _pickAndUploadJson,
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
                    child: Column(
                      children: [
                        if (_isUploading)
                          Column(
                            children: [
                              LinearProgressIndicator(
                                value: _uploadProgress,
                                minHeight: 4,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        if (_uploadErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _uploadErrorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _allMcqs.length,
                            itemBuilder: (context, index) {
                              final mcqData = _allMcqs[index];
                              return _buildMCQPreviewCard(mcqData, index + 1);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  /// Builds a preview card for each MCQ
  Widget _buildMCQPreviewCard(Map<String, dynamic> mcq, int number) {
    final questionMap = mcq['question'] as Map<String, dynamic>? ?? {};
    final String questionText = questionMap['text'] ?? "";
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
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      tooltip: "View MCQ",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DisplayMcq(mcq: mcq),
                          ),
                        );
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
