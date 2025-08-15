import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cet_verse/ui/theme/constants.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_tex/flutter_tex.dart';

class UpdateMCQ extends StatefulWidget {
  final String level;
  final String subject;
  final String chapter;
  final Map<String, dynamic> mcq;
  final String docId;

  const UpdateMCQ({
    super.key,
    required this.level,
    required this.subject,
    required this.chapter,
    required this.mcq,
    required this.docId,
  });

  @override
  _UpdateMCQState createState() => _UpdateMCQState();
}

class _UpdateMCQState extends State<UpdateMCQ> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _questionController;
  late TextEditingController _op1Controller;
  late TextEditingController _op2Controller;
  late TextEditingController _op3Controller;
  late TextEditingController _op4Controller;
  late TextEditingController _explanationController;
  late TextEditingController _originOfQuestion;

  // Image Files and URLs
  File? _questionImage;
  File? _op1Image;
  File? _op2Image;
  File? _op3Image;
  File? _op4Image;
  File? _explanationImage;
  String? _questionImageUrl;
  String? _op1ImageUrl;
  String? _op2ImageUrl;
  String? _op3ImageUrl;
  String? _op4ImageUrl;
  String? _explanationImageUrl;

  String _selectedAnswer = 'A';
  bool _isLoading = false;
  bool _showLatexPreview = false;
  String _previewText = '';
  String _previewTitle = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    final questionMap = widget.mcq['question'] as Map<String, dynamic>? ?? {};
    final optionsMap = widget.mcq['options'] as Map<String, dynamic>? ?? {};
    final explanationMap =
        widget.mcq['explanation'] as Map<String, dynamic>? ?? {};

    _questionController =
        TextEditingController(text: questionMap['text'] ?? '');
    _op1Controller =
        TextEditingController(text: optionsMap['A']?['text'] ?? '');
    _op2Controller =
        TextEditingController(text: optionsMap['B']?['text'] ?? '');
    _op3Controller =
        TextEditingController(text: optionsMap['C']?['text'] ?? '');
    _op4Controller =
        TextEditingController(text: optionsMap['D']?['text'] ?? '');
    _explanationController =
        TextEditingController(text: explanationMap['text'] ?? '');
    _originOfQuestion = TextEditingController(text: widget.mcq['origin'] ?? '');

    // Load existing image URLs
    _questionImageUrl = questionMap['image'] ?? '';
    _op1ImageUrl = optionsMap['A']?['image'] ?? '';
    _op2ImageUrl = optionsMap['B']?['image'] ?? '';
    _op3ImageUrl = optionsMap['C']?['image'] ?? '';
    _op4ImageUrl = optionsMap['D']?['image'] ?? '';
    _explanationImageUrl = explanationMap['image'] ?? '';

    _selectedAnswer = widget.mcq['answer'] ?? 'A';
  }

  @override
  void dispose() {
    _questionController.dispose();
    _op1Controller.dispose();
    _op2Controller.dispose();
    _op3Controller.dispose();
    _op4Controller.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String target) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      switch (target) {
        case 'question':
          _questionImage = File(pickedFile.path);
          break;
        case 'op1':
          _op1Image = File(pickedFile.path);
          break;
        case 'op2':
          _op2Image = File(pickedFile.path);
          break;
        case 'op3':
          _op3Image = File(pickedFile.path);
          break;
        case 'op4':
          _op4Image = File(pickedFile.path);
          break;
        case 'explanation':
          _explanationImage = File(pickedFile.path);
          break;
      }
    });
  }

  void _deleteImage(String target) {
    setState(() {
      switch (target) {
        case 'question':
          _questionImage = null;
          _questionImageUrl = '';
          break;
        case 'op1':
          _op1Image = null;
          _op1ImageUrl = '';
          break;
        case 'op2':
          _op2Image = null;
          _op2ImageUrl = '';
          break;
        case 'op3':
          _op3Image = null;
          _op3ImageUrl = '';
          break;
        case 'op4':
          _op4Image = null;
          _op4ImageUrl = '';
          break;
        case 'explanation':
          _explanationImage = null;
          _explanationImageUrl = '';
          break;
      }
    });
  }

  void _showPreview(String text, String title) {
    setState(() {
      _previewText = text;
      _previewTitle = title;
      _showLatexPreview = true;
    });
  }

  Future<String?> _uploadImage(
      File? imageFile, String? existingUrl, String label) async {
    // If existing image is deleted but no new image is uploaded
    if (imageFile == null && (existingUrl == null || existingUrl.isEmpty)) {
      return '';
    }

    // If no new image is selected, keep existing URL
    if (imageFile == null) return existingUrl;

    try {
      final fileName =
          "${widget.chapter}_${label}_${widget.docId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}";
      final storageRef =
          FirebaseStorage.instance.ref().child('mcq_images/$fileName');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading $label image: $e")),
      );
      return existingUrl;
    }
  }

  Future<void> _updateMCQ() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images and get URLs
      _questionImageUrl =
          await _uploadImage(_questionImage, _questionImageUrl, "question");
      _op1ImageUrl = await _uploadImage(_op1Image, _op1ImageUrl, "op1");
      _op2ImageUrl = await _uploadImage(_op2Image, _op2ImageUrl, "op2");
      _op3ImageUrl = await _uploadImage(_op3Image, _op3ImageUrl, "op3");
      _op4ImageUrl = await _uploadImage(_op4Image, _op4ImageUrl, "op4");
      _explanationImageUrl = await _uploadImage(
          _explanationImage, _explanationImageUrl, "explanation");

      // Construct updated MCQ data
      final updatedMcqData = {
        "origin": _originOfQuestion.text.trim(),
        "question": {
          "text": _questionController.text.trim(),
          "image": _questionImageUrl ?? '',
        },
        "options": {
          "A": {
            "text": _op1Controller.text.trim(),
            "image": _op1ImageUrl ?? '',
          },
          "B": {
            "text": _op2Controller.text.trim(),
            "image": _op2ImageUrl ?? '',
          },
          "C": {
            "text": _op3Controller.text.trim(),
            "image": _op3ImageUrl ?? '',
          },
          "D": {
            "text": _op4Controller.text.trim(),
            "image": _op4ImageUrl ?? '',
          },
        },
        "answer": _selectedAnswer,
        "explanation": {
          "text": _explanationController.text.trim(),
          "image": _explanationImageUrl ?? '',
        },
      };

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(widget.chapter)
          .collection('mcqs')
          .doc(widget.docId)
          .update(updatedMcqData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("MCQ updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating MCQ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = Colors.blue.shade700;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: Text(
            "Update MCQ - ${widget.chapter}",
            style: AppTheme.subheadingStyle.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          backgroundColor: subjectColor,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      "Updating MCQ...",
                      style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _originOfQuestion,
                                  decoration: InputDecoration(
                                    hintText: 'Origin Of Question',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.blue, width: 2.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey, width: 1.0),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                                ),
                                // Question Section
                                _buildSectionTitle(
                                    "Question", Icons.help_outline),
                                const SizedBox(height: 8),
                                _buildTextFieldWithLatexPreview(
                                  _questionController,
                                  "Enter the question",
                                  3,
                                  () => _pickImage('question'),
                                  _questionImage,
                                  _questionImageUrl,
                                  "question",
                                  () => _showPreview(_questionController.text,
                                      "Question Preview"),
                                ),
                                const SizedBox(height: 24),

                                // Options Section
                                _buildSectionTitle("Options", Icons.list_alt),
                                const SizedBox(height: 8),
                                _buildOptionField(
                                  "A",
                                  _op1Controller,
                                  () => _pickImage('op1'),
                                  _op1Image,
                                  _op1ImageUrl,
                                  "op1",
                                  () => _showPreview(
                                      _op1Controller.text, "Option A Preview"),
                                ),
                                _buildOptionField(
                                  "B",
                                  _op2Controller,
                                  () => _pickImage('op2'),
                                  _op2Image,
                                  _op2ImageUrl,
                                  "op2",
                                  () => _showPreview(
                                      _op2Controller.text, "Option B Preview"),
                                ),
                                _buildOptionField(
                                  "C",
                                  _op3Controller,
                                  () => _pickImage('op3'),
                                  _op3Image,
                                  _op3ImageUrl,
                                  "op3",
                                  () => _showPreview(
                                      _op3Controller.text, "Option C Preview"),
                                ),
                                _buildOptionField(
                                  "D",
                                  _op4Controller,
                                  () => _pickImage('op4'),
                                  _op4Image,
                                  _op4ImageUrl,
                                  "op4",
                                  () => _showPreview(
                                      _op4Controller.text, "Option D Preview"),
                                ),

                                const SizedBox(height: 24),

                                // Correct Answer
                                _buildSectionTitle("Correct Answer",
                                    Icons.check_circle_outline),
                                const SizedBox(height: 8),
                                _buildAnswerDropdown(),
                                const SizedBox(height: 24),

                                // Explanation Section
                                _buildSectionTitle(
                                    "Explanation", Icons.info_outline),
                                const SizedBox(height: 8),
                                _buildTextFieldWithLatexPreview(
                                  _explanationController,
                                  "Enter a detailed explanation",
                                  4,
                                  () => _pickImage('explanation'),
                                  _explanationImage,
                                  _explanationImageUrl,
                                  "explanation",
                                  () => _showPreview(
                                      _explanationController.text,
                                      "Explanation Preview"),
                                ),
                                const SizedBox(height: 32),

                                // Update Button
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _updateMCQ,
                                    icon: const Icon(Icons.update),
                                    label: const Text("Update MCQ"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: subjectColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showLatexPreview) _buildLatexPreviewOverlay(),
                ],
              ),
      ),
    );
  }

  Widget _buildLatexPreviewOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showLatexPreview = false),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _previewTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () =>
                            setState(() => _showLatexPreview = false),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: TeXView(
                      child: TeXViewDocument(
                        _previewText.isEmpty
                            ? "No content to preview"
                            : _previewText,
                      ),
                      style: const TeXViewStyle(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 18,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithLatexPreview(
    TextEditingController controller,
    String hintText,
    int maxLines,
    VoidCallback onPick,
    File? imageFile,
    String? imageUrl,
    String target,
    VoidCallback onPreview,
  ) {
    bool hasImage =
        imageFile != null || (imageUrl != null && imageUrl.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              final text = value ?? '';
              final hasContent = text.isNotEmpty || hasImage;
              return hasContent
                  ? null
                  : "$hintText cannot be empty (text or image required)";
            },
          ),
          const SizedBox(height: 12),

          // Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // LaTeX Preview Button
              OutlinedButton.icon(
                icon: const Icon(Icons.preview, size: 16),
                label: const Text("Preview"),
                onPressed: onPreview,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Image Actions
              if (hasImage)
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text("Delete Image"),
                  onPressed: () => _deleteImage(target),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate, size: 16),
                  label: const Text("Add Image"),
                  onPressed: onPick,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),

          // Image Preview
          if (hasImage) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                      ),
                    )
                  : imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Image not available",
                                    style:
                                        TextStyle(color: Colors.red.shade800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const Center(child: Text("No image selected")),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionField(
    String label,
    TextEditingController controller,
    VoidCallback onPick,
    File? imageFile,
    String? imageUrl,
    String target,
    VoidCallback onPreview,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedAnswer == label
                  ? Colors.green.shade100
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedAnswer == label
                    ? Colors.green.shade700
                    : Colors.blue.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedAnswer == label
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  size: 18,
                  color: _selectedAnswer == label
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  "Option $label",
                  style: TextStyle(
                    color: _selectedAnswer == label
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Option Text Field and Images
          _buildTextFieldWithLatexPreview(
            controller,
            "Enter text for option $label",
            1,
            onPick,
            imageFile,
            imageUrl,
            target,
            onPreview,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerDropdown() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select the correct option:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedAnswer,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'A',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "A",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_op1Controller.text.isNotEmpty
                          ? "Option A${_op1Controller.text.length > 20 ? " - ${_op1Controller.text.substring(0, 20)}..." : " - ${_op1Controller.text}"}"
                          : "Option A"),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'B',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "B",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_op2Controller.text.isNotEmpty
                          ? "Option B${_op2Controller.text.length > 20 ? " - ${_op2Controller.text.substring(0, 20)}..." : " - ${_op2Controller.text}"}"
                          : "Option B"),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'C',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "C",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_op3Controller.text.isNotEmpty
                          ? "Option C${_op3Controller.text.length > 20 ? " - ${_op3Controller.text.substring(0, 20)}..." : " - ${_op3Controller.text}"}"
                          : "Option C"),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'D',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "D",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_op4Controller.text.isNotEmpty
                          ? "Option D${_op4Controller.text.length > 20 ? " - ${_op4Controller.text.substring(0, 20)}..." : " - ${_op4Controller.text}"}"
                          : "Option D"),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAnswer = value ?? 'A';
                });
              },
              validator: (value) =>
                  value == null ? "Select a correct answer" : null,
              icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
