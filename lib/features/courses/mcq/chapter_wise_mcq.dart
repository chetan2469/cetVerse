import 'package:cet_verse/features/courses/mcq/add_mcq.dart';
import 'package:cet_verse/features/courses/mcq/display_mcq.dart';
import 'package:cet_verse/features/courses/mcq/update_mcq.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
        SnackBar(
          content: Text('Error loading MCQs: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // ---------- Upload JSON ----------
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
        SnackBar(
          content: const Text('MCQs uploaded successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text('Delete MCQs', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
            'Delete ${_selectedIds.length} selected MCQ(s)? This cannot be undone.',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 14)),
          ),
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
        SnackBar(
          content: Text('${_selectedIds.length} MCQ(s) deleted.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      _exitSelectionMode();
      await _fetchMcqs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
    return Scaffold(
      key: _scaffoldKey,
      drawer: const MyDrawer(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48, // Reduced height
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: _selectionMode
              ? _exitSelectionMode
              : () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.chapter} MCQs",
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 18, // Updated to 18
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_selectionMode) ...[
            IconButton(
              tooltip: 'Select All',
              onPressed: _selectAll,
              icon: const Icon(Icons.done_all,
                  color: Colors.indigoAccent, size: 20),
            ),
            IconButton(
              tooltip: 'Delete Selected',
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.add, color: Colors.indigoAccent, size: 20),
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
              icon: const Icon(Icons.upload_file,
                  color: Colors.indigoAccent, size: 20),
              tooltip: 'Upload JSON MCQs',
              onPressed: _isUploading ? null : _pickAndUploadJson,
            ),
          ],
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16), // Reduced padding
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12), // Reduced spacing
                  Text(
                    "MCQ Questions",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 16, // Updated to 16
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced spacing
                  _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.quiz,
                color: Colors.white,
                size: 24, // Reduced size
              ),
            ),
            const SizedBox(width: 16), // Reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chapter,
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 16, // Updated to 16
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4), // Reduced spacing
                  Text(
                    '${widget.subject} - Chapter MCQs',
                    style: AppTheme.captionStyle.copyWith(
                      fontSize: 14, // Updated to 14
                      color: Colors.black87,
                    ),
                  ),
                  if (_allMcqs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_allMcqs.length} Questions',
                        style: TextStyle(
                          fontSize: 12, // Updated to 12
                          fontWeight: FontWeight.w500,
                          color: Colors.indigoAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_allMcqs.isEmpty) {
      return _buildEmptyCard();
    }

    return Column(
      children: [
        if (_isUploading) _buildUploadProgress(),
        if (_uploadErrorMessage != null) _buildUploadError(),
        ..._allMcqs.map((mcq) {
          final index = _allMcqs.indexOf(mcq);
          final docId = mcq['docId'] as String;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
            child: _buildMCQPreviewCard(mcq, index + 1, docId),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(5, (index) => _buildShimmerMCQCard()),
    );
  }

  Widget _buildShimmerMCQCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
      child: Card(
        elevation: 2, // Reduced elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 60,
                      height: 16, // Reduced height
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                        3,
                        (index) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  width: 20, // Reduced size
                                  height: 20, // Reduced size
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            )),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Reduced spacing
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: double.infinity,
                  height: 14, // Reduced height
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 6), // Reduced spacing
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 180, // Reduced width
                  height: 14, // Reduced height
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20), // Reduced padding
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.grey,
              size: 40, // Reduced size
            ),
            const SizedBox(height: 12), // Reduced spacing
            Text(
              'No MCQs available',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16, // Updated to 16
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              'Add MCQs to get started with practice questions',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14, // Updated to 14
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12), // Reduced spacing
            ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8), // Reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2, // Reduced elevation
              ),
              child: const Text(
                'Add First MCQ',
                style: TextStyle(
                  fontSize: 14, // Updated to 14
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: Colors.indigoAccent,
                    size: 18, // Reduced size
                  ),
                ),
                const SizedBox(width: 10), // Reduced spacing
                Text(
                  'Uploading MCQs...',
                  style: AppTheme.subheadingStyle.copyWith(
                    fontSize: 16, // Updated to 16
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced spacing
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
              minHeight: 4, // Reduced height
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}% Complete',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14, // Updated to 14
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadError() {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 18, // Reduced size
              ),
            ),
            const SizedBox(width: 10), // Reduced spacing
            Expanded(
              child: Text(
                _uploadErrorMessage!,
                style: AppTheme.captionStyle.copyWith(
                  fontSize: 14, // Updated to 14
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCQPreviewCard(
      Map<String, dynamic> mcq, int number, String docId) {
    final questionMap = (mcq['question'] as Map<String, dynamic>?) ?? const {};
    final questionText = (questionMap['text'] as String?) ?? '';
    final checked = _selectedIds.contains(docId);
    final isFirstItem = number == 1;

    return Card(
      key: ValueKey(docId),
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _enterSelectionMode(docId),
        onTap: () {
          if (_selectionMode) {
            _toggleSelected(docId, !checked);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DisplayMcq(mcq: mcq)),
            );
          }
        },
        splashColor: Colors.indigoAccent.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced padding
          child: Row(
            children: [
              Container(
                width: 20, // Reduced size
                height: 20, // Reduced size
                decoration: BoxDecoration(
                  color:
                      isFirstItem ? Colors.indigoAccent : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 10, // Updated to 10
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            questionText.isNotEmpty
                                ? questionText
                                : 'Question $number',
                            style: AppTheme.subheadingStyle.copyWith(
                              fontSize: 14, // Updated to 14
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isFirstItem) ...[
                          const SizedBox(width: 6), // Reduced spacing
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2, // Reduced padding
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FIRST',
                              style: TextStyle(
                                fontSize: 10, // Updated to 10
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4), // Reduced spacing
                    Text(
                      'MCQ Practice Question',
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 12, // Updated to 12
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTrailingWidget(checked, docId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(bool checked, String docId) {
    if (_selectionMode) {
      return Checkbox(
        value: checked,
        onChanged: (v) => _toggleSelected(docId, v ?? false),
        activeColor: Colors.indigoAccent,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    } else {
      return PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'edit':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UpdateMCQ(
                    level: widget.level,
                    subject: widget.subject,
                    chapter: widget.chapter,
                    mcq: _allMcqs.firstWhere((m) => m['docId'] == docId),
                    docId: docId,
                  ),
                ),
              ).then((_) => _fetchMcqs());
              break;
            case 'view':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DisplayMcq(
                    mcq: _allMcqs.firstWhere((m) => m['docId'] == docId),
                  ),
                ),
              );
              break;
            case 'delete':
              _deleteSingle(docId);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.indigoAccent, size: 18),
                const SizedBox(width: 10),
                const Text('Edit MCQ', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility, color: Colors.indigoAccent, size: 18),
                const SizedBox(width: 10),
                const Text('View MCQ', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                const SizedBox(width: 10),
                const Text('Delete MCQ', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
        icon: const Icon(
          Icons.more_vert,
          color: Colors.indigoAccent,
          size: 18,
        ),
      );
    }
  }
}
