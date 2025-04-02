import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cet_verse/constants.dart'; // Contains AppTheme
import 'package:path/path.dart' as p; // For file name manipulation if needed

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

  // Text Fields
  final TextEditingController _questionTextController = TextEditingController();
  final TextEditingController _op1TextController = TextEditingController();
  final TextEditingController _op2TextController = TextEditingController();
  final TextEditingController _op3TextController = TextEditingController();
  final TextEditingController _op4TextController = TextEditingController();
  final TextEditingController _explanationController = TextEditingController();

  String _selectedAnswer = 'A'; // "A", "B", "C", or "D"
  bool _isLoading = false;

  /// Image Files: question, op1..op4, explanation
  File? _questionImage;
  File? _op1Image;
  File? _op2Image;
  File? _op3Image;
  File? _op4Image;
  File? _explanationImage; // New field for explanation image

  /// Image pickers
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _questionTextController.dispose();
    _op1TextController.dispose();
    _op2TextController.dispose();
    _op3TextController.dispose();
    _op4TextController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  /// Picks an image from gallery for a given target: question, op1, op2..., explanation
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
          _explanationImage = File(pickedFile.path); // New case for explanation
          break;
      }
    });
  }

  /// Uploads image to Firebase Storage if not null, returns the download url
  Future<String?> _uploadImage(File? imageFile, String label) async {
    if (imageFile == null) return null;

    try {
      final fileName =
          "${widget.chapter}_${label}_${DateTime.now().millisecondsSinceEpoch}${p.extension(imageFile.path)}";
      final storageRef =
          FirebaseStorage.instance.ref().child('mcq_images/$fileName');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading $label image: $e")),
      );
      return null;
    }
  }

  /// Validate form, upload images, then store everything in Firestore
  Future<void> _addMCQ() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images for question, op1..op4, explanation
      final questionImgUrl = await _uploadImage(_questionImage, "question");
      final op1ImgUrl = await _uploadImage(_op1Image, "op1");
      final op2ImgUrl = await _uploadImage(_op2Image, "op2");
      final op3ImgUrl = await _uploadImage(_op3Image, "op3");
      final op4ImgUrl = await _uploadImage(_op4Image, "op4");
      final explanationImgUrl =
          await _uploadImage(_explanationImage, "explanation"); // New upload

      // Construct MCQ data
      final mcqData = {
        "question": {
          "text": _questionTextController.text.trim(),
          "image": questionImgUrl ?? "",
        },
        "options": {
          "A": {
            "text": _op1TextController.text.trim(),
            "image": op1ImgUrl ?? "",
          },
          "B": {
            "text": _op2TextController.text.trim(),
            "image": op2ImgUrl ?? "",
          },
          "C": {
            "text": _op3TextController.text.trim(),
            "image": op3ImgUrl ?? "",
          },
          "D": {
            "text": _op4TextController.text.trim(),
            "image": op4ImgUrl ?? "",
          },
        },
        "answer": _selectedAnswer, // e.g. "A"
        "explanation": {
          "text": _explanationController.text.trim(),
          "image": explanationImgUrl ?? "", // New field for explanation image
        },
        "createdAt": DateTime.now(), // optional metadata
      };

      // Add to Firestore
      await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(widget.chapter)
          .collection('mcqs')
          .add(mcqData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("MCQ added successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding MCQ: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// CETverse UI build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _buildMainContent(),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      backgroundColor: Colors.transparent, // so gradient shows around edges
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Add MCQ - ${widget.chapter}",
          style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildForm(),
            ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildSectionTitle("Question"),
          const SizedBox(height: 8),
          _buildTextArea(
            controller: _questionTextController,
            hintText: "Enter the question text",
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildImagePicker(
            label: "Question Image (Optional)",
            file: _questionImage,
            onPick: () => _pickImage('question'),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle("Options (A - D)"),
          const SizedBox(height: 8),
          // Option A
          _buildOptionRow(
              "A", _op1TextController, _op1Image, () => _pickImage('op1')),
          const SizedBox(height: 12),
          // Option B
          _buildOptionRow(
              "B", _op2TextController, _op2Image, () => _pickImage('op2')),
          const SizedBox(height: 12),
          // Option C
          _buildOptionRow(
              "C", _op3TextController, _op3Image, () => _pickImage('op3')),
          const SizedBox(height: 12),
          // Option D
          _buildOptionRow(
              "D", _op4TextController, _op4Image, () => _pickImage('op4')),
          const SizedBox(height: 24),

          _buildSectionTitle("Correct Answer"),
          const SizedBox(height: 8),
          _buildAnswerDropdown(),
          const SizedBox(height: 24),

          _buildSectionTitle("Explanation"),
          const SizedBox(height: 8),
          _buildTextArea(
            controller: _explanationController,
            hintText: "Enter a detailed explanation",
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          _buildImagePicker(
            label: "Explanation Image (Optional)",
            file: _explanationImage,
            onPick: () => _pickImage('explanation'),
          ),
          const SizedBox(height: 32),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTheme.subheadingStyle.copyWith(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? "$hintText cannot be empty" : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// A row for each option (text + optional image)
  Widget _buildOptionRow(
    String label,
    TextEditingController textController,
    File? imageFile,
    VoidCallback onPick,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Option Label
        Text(
          "Option $label",
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        // Text Field
        _buildTextArea(
          controller: textController,
          hintText: "Enter text for option $label",
        ),
        const SizedBox(height: 6),
        // Image pick row
        _buildImagePicker(
          label: "Image for option $label (Optional)",
          file: imageFile,
          onPick: onPick,
        ),
      ],
    );
  }

  /// A small card to show or pick an image
  Widget _buildImagePicker({
    required String label,
    required File? file,
    required VoidCallback onPick,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white54),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: file == null
                ? Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      file,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onPick,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.image, color: Colors.white, size: 16),
            label: const Text("Pick", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Dropdown for correct answer
  Widget _buildAnswerDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white54),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        value: _selectedAnswer,
        style: const TextStyle(color: Colors.white),
        dropdownColor: Colors.black87,
        decoration: const InputDecoration(border: InputBorder.none),
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
        validator: (value) => value == null ? "Select correct answer" : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _addMCQ,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              "Add MCQ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
