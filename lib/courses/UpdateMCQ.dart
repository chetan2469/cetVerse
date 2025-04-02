import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cet_verse/constants.dart'; // Assuming AppTheme is here
import 'package:path/path.dart' as p; // For file name manipulation

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

  String _selectedAnswer = 'A'; // "A", "B", "C", or "D"
  bool _isLoading = false;

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

  /// Pick image for a specific target
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

  /// Upload image to Firebase Storage and return URL
  Future<String?> _uploadImage(
      File? imageFile, String? existingUrl, String label) async {
    if (imageFile == null)
      return existingUrl; // Keep existing URL if no new image

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
      return existingUrl; // Return existing URL on failure
    }
  }

  /// Update MCQ in Firestore
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
        const SnackBar(content: Text("MCQ updated successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating MCQ: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = Colors.blue.shade200;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: Text(
            "Update MCQ - ${widget.chapter}",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Section
                        _buildSectionTitle("Question"),
                        _buildTextArea(
                            _questionController, "Enter the question", 3),
                        const SizedBox(height: 12),
                        _buildImagePicker(
                            "Question Image (Optional)",
                            _questionImage,
                            _questionImageUrl,
                            () => _pickImage('question')),

                        const SizedBox(height: 24),

                        // Options Section
                        _buildSectionTitle("Options (A - D)"),
                        _buildOptionField("A", _op1Controller, _op1Image,
                            _op1ImageUrl, () => _pickImage('op1')),
                        _buildOptionField("B", _op2Controller, _op2Image,
                            _op2ImageUrl, () => _pickImage('op2')),
                        _buildOptionField("C", _op3Controller, _op3Image,
                            _op3ImageUrl, () => _pickImage('op3')),
                        _buildOptionField("D", _op4Controller, _op4Image,
                            _op4ImageUrl, () => _pickImage('op4')),

                        const SizedBox(height: 24),

                        // Correct Answer
                        _buildSectionTitle("Correct Answer"),
                        _buildAnswerDropdown(),
                        const SizedBox(height: 24),

                        // Explanation Section
                        _buildSectionTitle("Explanation"),
                        _buildTextArea(_explanationController,
                            "Enter a detailed explanation", 4),
                        const SizedBox(height: 12),
                        _buildImagePicker(
                            "Explanation Image (Optional)",
                            _explanationImage,
                            _explanationImageUrl,
                            () => _pickImage('explanation')),

                        const SizedBox(height: 32),

                        // Update Button
                        Center(
                          child: ElevatedButton(
                            onPressed: _updateMCQ,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: subjectColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              "Update MCQ",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Section title widget
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
    );
  }

  /// Text area widget
  Widget _buildTextArea(
      TextEditingController controller, String hintText, int maxLines) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value!.isEmpty ? "$hintText cannot be empty" : null,
    );
  }

  /// Option field with text and image
  Widget _buildOptionField(String label, TextEditingController controller,
      File? imageFile, String? imageUrl, VoidCallback onPick) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Option $label",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 6),
          _buildTextArea(controller, "Enter text for option $label", 1),
          const SizedBox(height: 6),
          _buildImagePicker("Image for option $label (Optional)", imageFile,
              imageUrl, onPick),
        ],
      ),
    );
  }

  /// Image picker widget
  Widget _buildImagePicker(
      String label, File? imageFile, String? imageUrl, VoidCallback onPick) {
    return Row(
      children: [
        Expanded(
          child: imageFile != null
              ? Image.file(imageFile, height: 70, fit: BoxFit.cover)
              : imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 70,
                        color: Colors.grey[200],
                        child: const Center(child: Text("Image not available")),
                      ),
                    )
                  : Container(
                      height: 70,
                      color: Colors.grey[200],
                      child: Center(child: Text(label)),
                    ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: onPick,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade200,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child:
              const Text("Pick Image", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  /// Answer dropdown widget
  Widget _buildAnswerDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedAnswer,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const [
        DropdownMenuItem(value: 'A', child: Text("A")),
        DropdownMenuItem(value: 'B', child: Text("B")),
        DropdownMenuItem(value: 'C', child: Text("C")),
        DropdownMenuItem(value: 'D', child: Text("D")),
      ],
      onChanged: (value) {
        setState(() {
          _selectedAnswer = value ?? 'A';
        });
      },
      validator: (value) => value == null ? "Select a correct answer" : null,
    );
  }
}
