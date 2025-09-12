import 'dart:io';

import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/notes/pdf_viewer_page.dart';
import 'package:cet_verse/screens/pricing_page.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ToppersNotes extends StatefulWidget {
  const ToppersNotes({super.key});

  @override
  State<ToppersNotes> createState() => _ToppersNotesState();
}

class _ToppersNotesState extends State<ToppersNotes> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.getUserType ?? '').toLowerCase() == 'admin';
    final canDownload = auth.topperNotesDownload; // Orbit/Galaxy

    return Scaffold(
      appBar: AppBar(
        title: const Text("Topper Notes"),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Add Topper Note',
              icon: const Icon(Icons.add),
              onPressed: () => _openUploadSheet(context),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('toppersNotes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text('No topper notes yet.', style: AppTheme.captionStyle),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final id = docs[i].id;
              final title = (d['title'] as String?)?.trim().isNotEmpty == true
                  ? d['title'] as String
                  : 'Untitled';
              final pdfUrl = (d['pdfUrl'] as String?) ?? '';

              return Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (pdfUrl.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No PDF attached')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PdfViewerPage(pdfUrl: pdfUrl)),
                    );
                  },
                  onLongPress:
                      isAdmin ? () => _confirmDelete(context, id, title) : null,
                  child: ListTile(
                    title: Text(title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      canDownload
                          ? 'Tap to view • Download available'
                          : 'Tap to view • Download locked (Orbit/Galaxy)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.description, color: Colors.blue),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip:
                              canDownload ? 'Download' : 'Upgrade to download',
                          icon: Icon(canDownload ? Icons.download : Icons.lock,
                              color: canDownload ? Colors.green : Colors.red),
                          onPressed: () {
                            if (pdfUrl.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('No PDF attached')),
                              );
                              return;
                            }
                            if (!canDownload) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Topper notes download is available on Orbit/Galaxy')),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PricingPage()),
                              );
                              return;
                            }
                            // Simple approach: open in viewer; implement file-saving if needed.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      PdfViewerPage(pdfUrl: pdfUrl)),
                            );
                          },
                        ),
                        if (isAdmin)
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _confirmDelete(context, id, title),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------- Admin: Upload ----------
  void _openUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _UploadTopperNoteSheet(),
    );
  }

  // ---------- Admin: Delete ----------
  Future<void> _confirmDelete(
      BuildContext context, String docId, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Are you sure you want to delete “$title”?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('toppersNotes')
          .doc(docId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }
}

class _UploadTopperNoteSheet extends StatefulWidget {
  const _UploadTopperNoteSheet();

  @override
  State<_UploadTopperNoteSheet> createState() => _UploadTopperNoteSheetState();
}

class _UploadTopperNoteSheetState extends State<_UploadTopperNoteSheet> {
  final _title = TextEditingController();
  bool _isUploading = false;
  double _progress = 0.0;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.getUserType ?? '').toLowerCase() == 'admin';

    if (!isAdmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: const SafeArea(
          child: Text('Only admins can add topper notes'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Topper Note',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_isUploading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress / 100),
              const SizedBox(height: 8),
              Text('${_progress.toStringAsFixed(0)}%'),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Select PDF'),
              onPressed: _isUploading ? null : _pickAndUpload,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    setState(() {
      _error = null;
      _isUploading = true;
      _progress = 0.0;
    });

    try {
      if (_title.text.trim().isEmpty) {
        setState(() {
          _isUploading = false;
          _error = 'Please enter a title';
        });
        return;
      }

      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (picked == null ||
          picked.files.isEmpty ||
          picked.files.single.path == null) {
        setState(() => _isUploading = false);
        return;
      }

      final path = picked.files.single.path!;
      final file = File(path);
      final fileName = 'topper_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final ref = FirebaseStorage.instance.ref().child('toppers/$fileName');
      final task = ref.putFile(file);

      task.snapshotEvents.listen((s) {
        final total = s.totalBytes == 0 ? 1 : s.totalBytes;
        setState(() => _progress = (s.bytesTransferred / total) * 100.0);
      });

      await task;
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('toppersNotes').add({
        'title': _title.text.trim(),
        'pdfUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Uploaded')));
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = 'Upload failed: $e';
      });
    }
  }
}
