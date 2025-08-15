import 'dart:io';
import 'package:cet_verse/features/courses/notes/add_chapter_page.dart';
import 'package:cet_verse/features/courses/notes/pdf_viewer_page.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
      setState(() {
        _isLoading = true;
        _statusMessage = "";
      });

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddChapterPage(
                      level: widget.level,
                      subject: widget.subject,
                    ),
                  ),
                ).then((_) => _fetchChapters());
              },
              icon: const Icon(Icons.add),
            ),
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
                    : RefreshIndicator(
                        onRefresh: _fetchChapters,
                        backgroundColor: Colors.white,
                        color: Colors.blue,
                        strokeWidth: 3.0,
                        displacement: 40.0,
                        child: Padding(
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
      ),
    );
  }

  Widget _buildChapterCard(String chapter) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _deleteChapter(chapter),
        splashColor: Colors.blue.withOpacity(0.3),
        highlightColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color.fromARGB(25, 33, 149, 243)],
            ),
          ),
          child: FutureBuilder<DocumentSnapshot>(
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
                return const ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text('Loading...'),
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!.exists) {
                return ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.book_outlined,
                        size: 30, color: Colors.blue),
                  ),
                  title: Text(
                    chapter,
                    style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.error_outline,
                      size: 20, color: Colors.red),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final resources = data?['resources'] as Map<String, dynamic>?;
              final pdfUrl = resources?['pdf'] as String? ?? "";

              return Semantics(
                label: pdfUrl.isNotEmpty
                    ? 'View notes for $chapter'
                    : 'No notes available for $chapter, tap upload icon to add',
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.book_outlined,
                        size: 30, color: Colors.blue),
                  ),
                  title: Text(
                    chapter,
                    style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: pdfUrl.isEmpty
                      ? InkWell(
                          onTap: () => _uploadPdfDialog(chapter),
                          child: const Icon(Icons.cloud_upload,
                              size: 20, color: Colors.green),
                        )
                      : null,
                  onTap: () {
                    if (pdfUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerPage(pdfUrl: pdfUrl),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("No notes available yet.")),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _uploadPdfDialog(String chapterId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UploadPdfSheet(
        level: widget.level,
        subject: widget.subject,
        chapterId: chapterId,
        onUploadDone: () {
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
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 16),
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
                backgroundColor: Colors.green,
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

  Future<void> _pickAndUploadPdf() async {
    try {
      setState(() {
        _statusMessage = "";
        _uploadProgress = 0.0;
        _isUploading = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        setState(() {
          _isUploading = false;
          _statusMessage = "File path not found.";
        });
        return;
      }

      final file = File(filePath);
      final fileName =
          "${widget.chapterId}_${DateTime.now().millisecondsSinceEpoch}.pdf";

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

      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

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

      setState(() {
        _isUploading = false;
        _statusMessage = "Uploaded Successfully!";
      });

      widget.onUploadDone();
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
