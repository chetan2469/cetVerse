import 'package:cet_verse/features/courses/mcq/add_mcq.dart';
import 'package:cet_verse/features/courses/mcq/display_mcq.dart';
import 'package:cet_verse/features/courses/mcq/update_mcq.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

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
  State<ChapterWiseMcq> createState() => _ChapterWiseMcqState();
}

class _ChapterWiseMcqState extends State<ChapterWiseMcq> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadErrorMessage;

  List<Map<String, dynamic>> _allMcqs = [];

  // Selection state
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};

  CollectionReference<Map<String, dynamic>> get _mcqCollection =>
      FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(widget.chapter)
          .collection('mcqs');

  @override
  void initState() {
    super.initState();
    _fetchMcqs();
  }

  Future<void> _fetchMcqs() async {
    try {
      final snapshot = await _mcqCollection.get();
      final list =
          snapshot.docs.map((doc) => {...doc.data(), 'docId': doc.id}).toList();
      if (mounted) {
        setState(() {
          _allMcqs = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading MCQs: $e')),
      );
    }
  }

  // ---------- Upload JSON (unchanged behavior, with minor guards) ----------
  Future<Map<String, dynamic>> _validateJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);

      if (jsonData.isEmpty) {
        return {
          'success': false,
          'error': 'JSON array is empty. Must contain at least one MCQ.'
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
        final missing =
            requiredFields.where((f) => !item.containsKey(f)).toList();
        if (missing.isNotEmpty) {
          errorMessages.add('Element ${i + 1} missing: ${missing.join(', ')}.');
        }

        if (item['question'] is! Map<String, dynamic> ||
            !item['question'].containsKey('text') ||
            !item['question'].containsKey('image')) {
          errorMessages.add(
              'Element ${i + 1} question invalid. Must have "text" and "image".');
        }

        if (item['options'] is! Map<String, dynamic> ||
            !['A', 'B', 'C', 'D']
                .every((opt) => item['options'].containsKey(opt))) {
          errorMessages
              .add('Element ${i + 1} options invalid. Must have A, B, C, D.');
        } else {
          for (final opt in ['A', 'B', 'C', 'D']) {
            final option = item['options'][opt];
            if (option is! Map<String, dynamic> ||
                !option.containsKey('text') ||
                !option.containsKey('image')) {
              errorMessages.add(
                  'Element ${i + 1} option $opt invalid. Needs "text" and "image".');
            }
          }
        }

        if (!['A', 'B', 'C', 'D'].contains(item['answer'])) {
          errorMessages.add(
              'Element ${i + 1} answer invalid. Must be "A", "B", "C", or "D".');
        }

        if (item['explanation'] is! Map<String, dynamic> ||
            !item['explanation'].containsKey('text') ||
            !item['explanation'].containsKey('image')) {
          errorMessages.add(
              'Element ${i + 1} explanation invalid. Needs "text" and "image".');
        }

        if (item.containsKey('subject') && item['subject'] is! String) {
          errorMessages.add('Element ${i + 1} subject must be a string.');
        }
        if (item.containsKey('origin') && item['origin'] is! String) {
          errorMessages.add('Element ${i + 1} origin must be a string.');
        }
      }

      if (errorMessages.isNotEmpty) {
        final msg = errorMessages.take(5).join('\n') +
            (errorMessages.length > 5 ? '\n...' : '');
        return {'success': false, 'error': msg};
      }
      return {'success': true, 'data': jsonData};
    } catch (e) {
      return {
        'success': false,
        'error': 'Invalid JSON format: $e. Must be an array of MCQ objects.'
      };
    }
  }

  Future<void> _uploadMcqs(List<dynamic> jsonData) async {
    try {
      int processed = 0;
      for (final item in jsonData) {
        await _mcqCollection.add(item);
        processed++;
        if (mounted) {
          setState(() => _uploadProgress = processed / jsonData.length);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MCQs uploaded successfully!')),
      );
      await _fetchMcqs();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadErrorMessage = 'Error uploading MCQs: $e');
    }
  }

  Future<void> _pickAndUploadJson() async {
    if (!mounted) return;
    setState(() {
      _isUploading = true;
      _uploadErrorMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        setState(() {
          _uploadErrorMessage = 'No file selected.';
          _isUploading = false;
        });
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final validationResult = await _validateJson(jsonString);
      if (validationResult['success'] != true) {
        setState(() {
          _uploadErrorMessage = validationResult['error'] as String?;
          _isUploading = false;
        });
        return;
      }

      await _uploadMcqs(validationResult['data'] as List<dynamic>);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadErrorMessage = 'Error processing file: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  // ---------- Selection helpers ----------
  void _enterSelectionMode([String? id]) {
    setState(() {
      _selectionMode = true;
      if (id != null) _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String id, bool value) {
    setState(() {
      if (value) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _selectAll() {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..addAll(_allMcqs.map((e) => e['docId'] as String));
    });
  }

  // ---------- Delete logic ----------
  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete MCQs'),
        content: Text(
            'Delete ${_selectedIds.length} selected MCQ(s)? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.delete(_mcqCollection.doc(id));
      }
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedIds.length} MCQ(s) deleted.')),
      );
      _exitSelectionMode();
      await _fetchMcqs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _deleteSingle(String docId) async {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(docId);
    });
    await _deleteSelected();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const MyDrawer(),
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _selectionMode
                ? _exitSelectionMode
                : () => Navigator.pop(context),
          ),
          title: Text(
            "${widget.chapter} MCQs",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 12),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            if (_selectionMode) ...[
              IconButton(
                tooltip: 'Select All',
                onPressed: _selectAll,
                icon: const Icon(Icons.done_all, color: Colors.black),
              ),
              IconButton(
                tooltip: 'Delete Selected',
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                tooltip: 'Add New MCQ',
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
                  ).then((_) => _fetchMcqs());
                },
              ),
              IconButton(
                icon: const Icon(Icons.upload_file, color: Colors.black),
                tooltip: 'Upload JSON MCQs',
                onPressed: _isUploading ? null : _pickAndUploadJson,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allMcqs.isEmpty
                ? const Center(
                    child: Text(
                      'No MCQs found.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
                                  value: _uploadProgress, minHeight: 4),
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
                              final mcq = _allMcqs[index];
                              final docId = mcq['docId'] as String;
                              return _buildMCQPreviewCard(
                                  mcq, index + 1, docId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildMCQPreviewCard(
      Map<String, dynamic> mcq, int number, String docId) {
    final questionMap = (mcq['question'] as Map<String, dynamic>?) ?? const {};
    final questionText = (questionMap['text'] as String?) ?? '';

    final checked = _selectedIds.contains(docId);

    return Card(
      key: ValueKey(docId),
      elevation: 4,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onLongPress: () => _enterSelectionMode(docId),
        onTap: () {
          if (_selectionMode) {
            _toggleSelected(docId, !checked);
          } else {
            // Open view page (old behavior)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DisplayMcq(mcq: mcq)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Q no. + actions / checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Q$number.',
                    style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                  ),
                  Row(
                    children: [
                      if (_selectionMode)
                        Checkbox(
                          value: checked,
                          onChanged: (v) => _toggleSelected(docId, v ?? false),
                        )
                      else ...[
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit MCQ',
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
                          tooltip: 'View MCQ',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DisplayMcq(mcq: mcq)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete MCQ',
                          onPressed: () => _deleteSingle(docId),
                        ),
                      ],
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
      ),
    );
  }
}
