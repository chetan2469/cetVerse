import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/PdfViewerPage.dart';
import 'package:cet_verse/courses/AddChapterPage.dart';
import 'package:cet_verse/MyDrawer.dart';
import 'package:cet_verse/constants.dart';
import 'package:cet_verse/state/AuthProvider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For file uploads
import 'package:path/path.dart' as path; // For file name manipulation if needed

class NotesPage extends StatefulWidget {
  final String level; // e.g., "11th Standard"
  final String subject; // e.g., "Biology"

  const NotesPage({
    super.key,
    required this.level,
    required this.subject,
  });

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  bool _isLoading = true;
  List<String> _allChapters = [];
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .get();

      setState(() {
        _allChapters = snapshot.docs.map((doc) => doc.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error loading chapters: $e";
        _isLoading = false;
      });
    }
  }

  /// Delete a chapter on long-press
  Future<void> _deleteChapter(String chapterId) async {
    try {
      await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(chapterId)
          .delete();

      setState(() {
        _allChapters.remove(chapterId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("'$chapterId' deleted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting '$chapterId': $e")),
      );
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "${widget.subject} Notes",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
          ),
          elevation: 2,
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () {
                // Add new chapter
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddChapterPage(
                      level: widget.level,
                      subject: widget.subject,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _statusMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _statusMessage,
                      style: AppTheme.captionStyle.copyWith(color: Colors.red),
                    ),
                  )
                : _allChapters.isEmpty
                    ? Center(
                        child: Text(
                          "No chapters found.",
                          style: AppTheme.captionStyle,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _allChapters.length,
                          itemBuilder: (context, index) {
                            final chapterId = _allChapters[index];
                            return _buildChapterCard(chapterId);
                          },
                        ),
                      ),
      ),
    );
  }

  /// Builds each chapter card with a dynamic trailing icon:
  /// - If "pdf" exists -> open PDF
  /// - Otherwise -> "upload" icon to pick PDF & upload
  Widget _buildChapterCard(String chapter) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // You can add onTap logic to open a notes detail page if needed
        },
        onLongPress: () => _deleteChapter(chapter),
        splashColor: Colors.blue.withOpacity(0.3),
        highlightColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color.fromARGB(25, 33, 149, 243)],
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 30,
                color: Colors.blue,
              ),
            ),
            title: Text(
              chapter,
              style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('levels')
                  .doc(widget.level)
                  .collection('subjects')
                  .doc(widget.subject)
                  .collection('chapters')
                  .doc(chapter)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return const Icon(Icons.error_outline,
                      size: 20, color: Colors.red);
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final resources = data?['resources'] as Map<String, dynamic>?;

                final pdfUrl = resources?['pdf'] as String? ?? "";

                if (pdfUrl.isNotEmpty) {
                  // Show an icon to open PDF
                  return InkWell(
                    onTap: () {
                      // Open the PDF
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerPage(pdfUrl: pdfUrl),
                        ),
                      );
                    },
                    child: const Icon(Icons.picture_as_pdf,
                        size: 20, color: Colors.blue),
                  );
                } else {
                  // Show an icon to upload PDF
                  return InkWell(
                    onTap: () => _uploadPdfDialog(chapter),
                    child: const Icon(Icons.cloud_upload,
                        size: 20, color: Colors.blue),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Show a bottom sheet or dialog for uploading PDF
  /// We'll do a bottom sheet with CETverse UI style
  void _uploadPdfDialog(String chapterId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // so we can have a gradient
      isScrollControlled: true,
      builder: (_) => _UploadPdfSheet(
        level: widget.level,
        subject: widget.subject,
        chapterId: chapterId,
        onUploadDone: () {
          // Refresh the UI after upload
          setState(() {});
        },
      ),
    );
  }
}

class _UploadPdfSheet extends StatefulWidget {
  final String level;
  final String subject;
  final String chapterId;
  final VoidCallback onUploadDone;

  const _UploadPdfSheet({
    required this.level,
    required this.subject,
    required this.chapterId,
    required this.onUploadDone,
  });

  @override
  State<_UploadPdfSheet> createState() => _UploadPdfSheetState();
}

class _UploadPdfSheetState extends State<_UploadPdfSheet> {
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String _statusMessage = "";

  @override
  Widget build(BuildContext context) {
    // A container with a gradient background to mimic CETverse UI style
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Upload PDF for '${widget.chapterId}'",
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),

            // Show progress bar if uploading
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text("${_uploadProgress.toStringAsFixed(0)}% uploaded"),
              const SizedBox(height: 16),
            ],

            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Select PDF"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Picks a PDF file, uploads it to Firebase Storage, updates Firestore
  Future<void> _pickAndUploadPdf() async {
    try {
      setState(() {
        _statusMessage = "";
        _uploadProgress = 0.0;
        _isUploading = true;
      });

      // Let user pick a file using file_picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        // user canceled
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        // no valid file path
        setState(() {
          _isUploading = false;
          _statusMessage = "File path not found.";
        });
        return;
      }

      final file = File(filePath);
      final fileName =
          "${widget.chapterId}_${DateTime.now().millisecondsSinceEpoch}.pdf";

      // Upload to firebase storage
      final storageRef = FirebaseStorage.instance.ref().child("pdfs/$fileName");
      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((snapshot) {
        final totalBytes = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        double progress = (transferred / totalBytes) * 100;
        setState(() {
          _uploadProgress = progress;
        });
      });

      // Wait for completion
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Save the url in Firestore
      await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(widget.chapterId)
          .update({
        "resources.pdf": downloadUrl,
      });

      // done
      setState(() {
        _isUploading = false;
        _statusMessage = "Uploaded Successfully!";
      });

      // refresh notes page
      widget.onUploadDone();

      // Optionally close the sheet after a small delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error uploading PDF: $e";
        _isUploading = false;
      });
    }
  }
}
