import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cet_verse/ui/theme/constants.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_tex/flutter_tex.dart';

class AddMCQ extends StatefulWidget {
  final String level;
  final String subject;
  final String chapter;

  const AddMCQ({
    super.key,
    required this.level,
    required this.subject,
    required this.chapter,
  });

  @override
  _AddMCQState createState() => _AddMCQState();
}

class _AddMCQState extends State<AddMCQ> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _op1Controller = TextEditingController();
  final TextEditingController _op2Controller = TextEditingController();
  final TextEditingController _op3Controller = TextEditingController();
  final TextEditingController _op4Controller = TextEditingController();
  final TextEditingController _explanationController = TextEditingController();

  File? _questionImage;
  File? _op1Image;
  File? _op2Image;
  File? _op3Image;
  File? _op4Image;
  File? _explanationImage;

  String _selectedAnswer = 'A';
  bool _isLoading = false;
  bool _showLatexPreview = false;
  String _previewText = '';
  String _previewTitle = '';

  final ImagePicker _picker = ImagePicker();

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
          break;
        case 'op1':
          _op1Image = null;
          break;
        case 'op2':
          _op2Image = null;
          break;
        case 'op3':
          _op3Image = null;
          break;
        case 'op4':
          _op4Image = null;
          break;
        case 'explanation':
          _explanationImage = null;
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

  Future<String?> _uploadImage(File? imageFile, String label) async {
    if (imageFile == null) return '';
    try {
      final fileName =
          "${widget.chapter}_${label}_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}";
      final storageRef =
          FirebaseStorage.instance.ref().child('mcq_images/$fileName');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading $label image: $e")),
        );
      }
      return null;
    }
  }

  Future<void> _addMCQ() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final questionImageUrl = await _uploadImage(_questionImage, "question");
      if (questionImageUrl == null) {
        throw Exception("Question image upload failed");
      }
      final op1ImageUrl = await _uploadImage(_op1Image, "op1");
      if (op1ImageUrl == null) throw Exception("Option A image upload failed");
      final op2ImageUrl = await _uploadImage(_op2Image, "op2");
      if (op2ImageUrl == null) throw Exception("Option B image upload failed");
      final op3ImageUrl = await _uploadImage(_op3Image, "op3");
      if (op3ImageUrl == null) throw Exception("Option C image upload failed");
      final op4ImageUrl = await _uploadImage(_op4Image, "op4");
      if (op4ImageUrl == null) throw Exception("Option D image upload failed");
      final explanationImageUrl =
          await _uploadImage(_explanationImage, "explanation");
      if (explanationImageUrl == null && _explanationImage != null) {
        throw Exception("Explanation image upload failed");
      }

      final mcqData = {
        "question": {
          "text": _questionController.text.trim(),
          "image": questionImageUrl,
        },
        "options": {
          "A": {"text": _op1Controller.text.trim(), "image": op1ImageUrl},
          "B": {"text": _op2Controller.text.trim(), "image": op2ImageUrl},
          "C": {"text": _op3Controller.text.trim(), "image": op3ImageUrl},
          "D": {"text": _op4Controller.text.trim(), "image": op4ImageUrl},
        },
        "answer": _selectedAnswer,
        "explanation": {
          "text": _explanationController.text.trim(),
          "image": explanationImageUrl,
        },
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(widget.chapter)
          .collection('mcqs')
          .add(mcqData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("MCQ added successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding MCQ: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLevel = widget.level == '12th Standard'
        ? 'Class 12'
        : widget.level == '11th Standard'
            ? 'Class 11'
            : widget.level;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Add MCQ - ${widget.chapter} ($displayLevel)",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
          ),
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
                      "Adding MCQ...",
                      style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12), // Reduced padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputSection(
                            title: "Question",
                            icon: Icons.help_outline,
                            controller: _questionController,
                            image: _questionImage,
                            target: 'question',
                            onPreview: () => _showPreview(
                                _questionController.text, "Question Preview"),
                            minLines: 3,
                          ),
                          _buildSectionTitle("Options", Icons.list_alt),
                          _buildOptionField('A', _op1Controller, _op1Image),
                          _buildOptionField('B', _op2Controller, _op2Image),
                          _buildOptionField('C', _op3Controller, _op3Image),
                          _buildOptionField('D', _op4Controller, _op4Image),
                          _buildSectionTitle(
                              "Correct Answer", Icons.check_circle_outline),
                          _buildAnswerDropdown(),
                          _buildInputSection(
                            title: "Explanation",
                            icon: Icons.info_outline,
                            controller: _explanationController,
                            image: _explanationImage,
                            target: 'explanation',
                            onPreview: () => _showPreview(
                                _explanationController.text,
                                "Explanation Preview"),
                            minLines: 4,
                            isOptional: true,
                          ),
                          const SizedBox(height: 24), // Increased spacing
                          ElevatedButton.icon(
                            onPressed: _addMCQ,
                            icon: const Icon(Icons.add),
                            label: const Text("Add MCQ"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showLatexPreview) _buildLatexPreviewOverlay(),
                ],
              ),
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required File? image,
    required String target,
    required VoidCallback onPreview,
    int minLines = 1,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, icon),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10), // Reduced padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: controller,
                minLines: minLines,
                maxLines: minLines + 2,
                decoration: InputDecoration(
                  hintText: "Enter $title ${isOptional ? '(optional)' : ''}",
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                validator: isOptional
                    ? null
                    : (value) {
                        if ((value == null || value.isEmpty) && image == null) {
                          return "$title must have text or an image";
                        }
                        return null;
                      },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.preview, size: 16),
                    label: const Text("Preview"),
                    onPressed: onPreview,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (image != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text("Remove Image"),
                      onPressed: () => _deleteImage(target),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text("Add Image"),
                      onPressed: () => _pickImage(target),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              if (image != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24), // Increased spacing
      ],
    );
  }

  Widget _buildOptionField(
      String option, TextEditingController controller, File? image) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Reduced padding
      child: Container(
        padding: const EdgeInsets.all(10), // Reduced padding
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedAnswer == option
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Option $option",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildInputSection(
              title: "Option $option",
              icon: Icons.radio_button_checked,
              controller: controller,
              image: image,
              target: 'op${option.toLowerCase()}',
              onPreview: () =>
                  _showPreview(controller.text, "Option $option Preview"),
              isOptional: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerDropdown() {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select the correct answer:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedAnswer,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: ['A', 'B', 'C', 'D'].map((option) {
              final controller = {
                'A': _op1Controller,
                'B': _op2Controller,
                'C': _op3Controller,
                'D': _op4Controller,
              }[option];
              return DropdownMenuItem(
                value: option,
                child: Text(
                  controller!.text.isNotEmpty
                      ? "Option $option${controller.text.length > 20 ? " - ${controller.text.substring(0, 20)}..." : " - ${controller.text}"}"
                      : "Option $option",
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedAnswer = value!),
            validator: (value) =>
                value == null ? "Select a correct answer" : null,
            icon: const Icon(Icons.arrow_drop_down),
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  Widget _buildLatexPreviewOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showLatexPreview = false),
      child: Container(
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
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
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
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
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: TeXView(
                      child: TeXViewDocument(
                        _previewText.isEmpty
                            ? "No content to preview"
                            : _previewText,
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
}
