import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class AddPyq extends StatefulWidget {
  const AddPyq({super.key});

  @override
  State<AddPyq> createState() => _AddPyqState();
}

class _AddPyqState extends State<AddPyq> {
  final _yearController = TextEditingController();
  final _testNameController = TextEditingController();
  String? _pyqType;
  String? _errorMessage;
  bool _isLoading = false;
  double _progress = 0.0;
  List<dynamic>? _jsonData;
  bool _isJsonValidated = false;

  Future<Map<String, dynamic>> _validateJson(String jsonString) async {
    try {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _jsonData = jsonData;

      // Check total number of questions
      if (jsonData.length != 150 && jsonData.length != 200) {
        return {
          'success': false,
          'error':
              'JSON must contain exactly 150 questions for PCM or 200 questions for PCB. Found ${jsonData.length} elements.',
        };
      }

      final Map<String, int> subjectCounts = {
        'Physics': 0,
        'Chemistry': 0,
        'Maths': 0,
        'Biology': 0
      };
      final List<String> errorMessages = [];

      for (var i = 0; i < jsonData.length; i++) {
        final item = jsonData[i];
        if (item is! Map<String, dynamic>) {
          errorMessages.add(
              'Element ${i + 1} is not an object. Each question must be a JSON object with fields: question, options, answer, explanation, subject.');
          continue;
        }

        final requiredFields = [
          'explanation',
          'answer',
          'options',
          'question',
          'subject'
        ];
        final missingFields =
            requiredFields.where((field) => !item.containsKey(field)).toList();
        if (missingFields.isNotEmpty) {
          errorMessages.add(
              'Element ${i + 1} is missing fields: ${missingFields.join(', ')}. Each question must include all required fields.');
        }

        if (item['explanation'] is! Map<String, dynamic> ||
            !item['explanation'].containsKey('text') ||
            !item['explanation'].containsKey('image')) {
          errorMessages.add(
              'Element ${i + 1} has invalid explanation format. The "explanation" field must be an object with "text" and "image" properties.');
        }

        if (item['options'] is! Map<String, dynamic> ||
            !item['options'].containsKey('A') ||
            !item['options'].containsKey('B') ||
            !item['options'].containsKey('C') ||
            !item['options'].containsKey('D')) {
          errorMessages.add(
              'Element ${i + 1} has invalid options format. The "options" field must be an object with keys "A", "B", "C", and "D".');
        }

        if (item['question'] is! Map<String, dynamic> ||
            !item['question'].containsKey('text') ||
            !item['question'].containsKey('image')) {
          errorMessages.add(
              'Element ${i + 1} has invalid question format. The "question" field must be an object with "text" and "image" properties.');
        }

        if (!['A', 'B', 'C', 'D'].contains(item['answer'])) {
          errorMessages.add(
              'Element ${i + 1} has invalid answer value. The "answer" field must be one of "A", "B", "C", or "D".');
        }

        final subject = item['subject'] as String?;
        if (subject == null ||
            !['Physics', 'Chemistry', 'Maths', 'Biology'].contains(subject)) {
          errorMessages.add(
              'Element ${i + 1} has invalid or missing subject. The "subject" field must be one of "Physics", "Chemistry", "Maths", or "Biology".');
        } else {
          subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
        }
      }

      if (errorMessages.isNotEmpty) {
        return {
          'success': false,
          'error': errorMessages.take(5).join(' ') +
              (errorMessages.length > 5 ? ' ...' : ''),
        };
      }

      String? pyqType;
      if (jsonData.length == 150 &&
          subjectCounts['Physics'] == 50 &&
          subjectCounts['Chemistry'] == 50 &&
          subjectCounts['Maths'] == 50 &&
          subjectCounts['Biology'] == 0) {
        pyqType = 'pcm';
      } else if (jsonData.length == 200 &&
          subjectCounts['Physics'] == 50 &&
          subjectCounts['Chemistry'] == 50 &&
          subjectCounts['Biology'] == 100 &&
          subjectCounts['Maths'] == 0) {
        pyqType = 'pcb';
      } else {
        return {
          'success': false,
          'error':
              'Invalid subject distribution. For PCM, require 50 Physics, 50 Chemistry, 50 Maths (150 total). For PCB, require 50 Physics, 50 Chemistry, 100 Biology (200 total). Found: Physics=${subjectCounts['Physics']}, Chemistry=${subjectCounts['Chemistry']}, Maths=${subjectCounts['Maths']}, Biology=${subjectCounts['Biology']}.',
        };
      }

      return {
        'success': true,
        'data': jsonData,
        'pyqType': pyqType,
      };
    } catch (e) {
      return {
        'success': false,
        'error':
            'Invalid JSON format: $e. Please ensure the file is valid JSON with an array of 150 or 200 question objects.',
      };
    }
  }

  Future<bool> _uploadToFirestore(List<dynamic> jsonData, String year,
      String testName, String pyqType) async {
    try {
      final newDocRef = await FirebaseFirestore.instance.collection('pyq').add({
        'testName': testName,
        'testYear': int.parse(year),
        'group': pyqType,
      });

      final collectionRef = newDocRef.collection('test');

      const totalItems = 150; // Max items, adjusted dynamically
      int processedItems = 0;

      for (int i = 0; i < jsonData.length; i++) {
        final docData = Map<String, dynamic>.from(jsonData[i]);
        docData['createdAt'] = FieldValue.serverTimestamp();
        await collectionRef.doc((i + 1).toString()).set(docData);
        processedItems++;
        setState(() {
          _progress = processedItems / (pyqType == 'pcm' ? 150 : 200);
        });
      }
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading to Firestore: $e';
      });
      return false;
    }
  }

  Future<void> _pickAndValidateFile() async {
    if (_yearController.text.isEmpty || _yearController.text.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a valid 4-digit year (e.g., 2024).';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pyqType = null;
      _progress = 0.0;
      _jsonData = null;
      _isJsonValidated = false;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _errorMessage = 'No file selected. Please choose a JSON file.';
          _isLoading = false;
        });
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final validationResult = await _validateJson(jsonString);
      if (!validationResult['success']) {
        setState(() {
          _errorMessage = validationResult['error'];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _pyqType = validationResult['pyqType'] as String;
        _jsonData = validationResult['data'] as List<dynamic>;
        _isJsonValidated = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('JSON validated successfully! Please review and upload.')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing file: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAndUpload() async {
    if (_jsonData == null || _pyqType == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = 0.0;
    });

    try {
      final year = _yearController.text.trim();
      final testName = _testNameController.text.trim();
      final success =
          await _uploadToFirestore(_jsonData!, year, testName, _pyqType!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test uploaded successfully!')),
        );
        setState(() {
          _jsonData = null;
          _isJsonValidated = false;
          _pyqType = null;
          _yearController.clear();
          _testNameController.clear();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to upload test to Firestore.';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
        _progress = 0.0;
      });
    }
  }

  void _showJsonTreemap() {
    if (_jsonData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON Structure'),
        content: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: SingleChildScrollView(
            child: Column(
              children: _jsonData!.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isValid = item is Map<String, dynamic> &&
                    ['explanation', 'answer', 'options', 'question', 'subject']
                        .every((field) => item.containsKey(field)) &&
                    item['explanation'] is Map<String, dynamic> &&
                    item['explanation'].containsKey('text') &&
                    item['explanation'].containsKey('image') &&
                    item['options'] is Map<String, dynamic> &&
                    ['A', 'B', 'C', 'D']
                        .every((opt) => item['options'].containsKey(opt)) &&
                    item['question'] is Map<String, dynamic> &&
                    item['question'].containsKey('text') &&
                    item['question'].containsKey('image') &&
                    ['A', 'B', 'C', 'D'].contains(item['answer']) &&
                    ['Physics', 'Chemistry', 'Maths', 'Biology']
                        .contains(item['subject']);

                return ExpansionTile(
                  title: Text(
                    'Question ${index + 1} ${isValid ? '(Valid)' : '(Invalid)'}',
                    style: TextStyle(
                      color: isValid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    if (item is! Map<String, dynamic>)
                      const ListTile(
                        title: Text(
                          'Error: Not an object',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    else ...[
                      _buildFieldTile('question', item['question'],
                          valid: item['question'] is Map<String, dynamic> &&
                              item['question'].containsKey('text') &&
                              item['question'].containsKey('image')),
                      _buildFieldTile('options', item['options'],
                          valid: item['options'] is Map<String, dynamic> &&
                              ['A', 'B', 'C', 'D'].every(
                                  (opt) => item['options'].containsKey(opt))),
                      _buildFieldTile('answer', item['answer'],
                          valid: ['A', 'B', 'C', 'D'].contains(item['answer'])),
                      _buildFieldTile('explanation', item['explanation'],
                          valid: item['explanation'] is Map<String, dynamic> &&
                              item['explanation'].containsKey('text') &&
                              item['explanation'].containsKey('image')),
                      _buildFieldTile('subject', item['subject'],
                          valid: ['Physics', 'Chemistry', 'Maths', 'Biology']
                              .contains(item['subject'])),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldTile(String field, dynamic value, {required bool valid}) {
    return ExpansionTile(
      title: Text(
        '$field ${valid ? '(Valid)' : '(Invalid)'}',
        style: TextStyle(color: valid ? Colors.green : Colors.red),
      ),
      children: [
        ListTile(
          title: Text(
            value == null ? 'Missing' : jsonEncode(value),
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _testNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Test',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Test JSON',
                  style: AppTheme.subheadingStyle.copyWith(
                    fontSize: 28,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter Year (e.g., 2024)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _yearController.text.isNotEmpty &&
                            _yearController.text.length != 4
                        ? 'Please enter a valid 4-digit year'
                        : null,
                  ),
                  maxLength: 4,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _testNameController,
                  decoration: InputDecoration(
                    labelText: 'Enter Test Name (e.g., Shift 1-12 Oct)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _testNameController.text.isEmpty &&
                            _errorMessage != null
                        ? 'Test name is required'
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _pickAndValidateFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    _isLoading ? 'Processing...' : 'Pick and Validate JSON',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isJsonValidated && _jsonData != null) ...[
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmAndUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      _isLoading ? 'Uploading...' : 'Upload to Firestore',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showJsonTreemap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Show JSON Structure'),
                  ),
                ],
                if (_isLoading && _progress > 0.0)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey[300],
                        color: Colors.indigo,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading: ${(_progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                if (_pyqType != null)
                  Text(
                    'Test Type: ${_pyqType!.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                if (_errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showJsonTreemap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Show JSON Structure'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
