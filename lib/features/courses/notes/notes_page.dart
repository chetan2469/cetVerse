import 'dart:io';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/notes/add_chapter_page.dart';
import 'package:cet_verse/features/courses/notes/pdf_viewer_page.dart';
import 'package:cet_verse/screens/pricing_page.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class NotesPage extends StatefulWidget {
  final String level; // e.g., "11th Standard"
  final String subject; // e.g., "Biology"

  const NotesPage({
    super.key,
    required this.level,
    required this.subject,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
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

  // Natural sorting function to handle numeric prefixes correctly
  int _naturalCompare(String a, String b) {
    final RegExp numRegex = RegExp(r'\d+');

    // Extract the first number from each string
    final Match? matchA = numRegex.firstMatch(a);
    final Match? matchB = numRegex.firstMatch(b);

    if (matchA != null && matchB != null) {
      final int numA = int.parse(matchA.group(0)!);
      final int numB = int.parse(matchB.group(0)!);

      // If numbers are different, sort by number
      if (numA != numB) {
        return numA.compareTo(numB);
      }

      // If numbers are same, sort by the rest of the string
      final String restA = a.substring(matchA.end);
      final String restB = b.substring(matchB.end);
      return restA.compareTo(restB);
    }

    // If no numbers found, use regular string comparison
    return a.compareTo(b);
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

      final List<String> chapters = snapshot.docs.map((doc) => doc.id).toList();

      // Sort chapters using natural comparison
      chapters.sort(_naturalCompare);

      setState(() {
        _allChapters = chapters;
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
    final auth = context.read<AuthProvider>();
    final isAdmin = (auth.getUserType ?? '').toLowerCase() == 'admin';
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only admins can delete chapters'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            const Text('Delete Chapter'),
          ],
        ),
        content: Text(
            "Are you sure you want to delete '$chapterId'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
        SnackBar(
          content: Text("'$chapterId' deleted successfully."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting '$chapterId': $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _openNotesOrUpsell(String pdfUrl, String chapter) {
    final auth = context.read<AuthProvider>();
    final canSeeNotes = auth.chapterWiseNotesAccess;

    if (!canSeeNotes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notes are available on Plus/Pro plans'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PricingPage()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(pdfUrl: pdfUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.getUserType ?? '').toLowerCase() == 'admin';

    return Scaffold(
      key: scaffoldKey,
      drawer: const MyDrawer(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.subject} Notes",
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Add Chapter',
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
              icon: const Icon(Icons.add, color: Colors.indigoAccent),
            ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Text(
                    "Chapter Notes",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
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
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.book,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.subject} Notes',
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Study materials and chapter notes',
                    style: AppTheme.captionStyle.copyWith(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (_allChapters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_allChapters.length} Chapters',
                        style: const TextStyle(
                          fontSize: 12,
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

    if (_statusMessage.isNotEmpty) {
      return _buildErrorCard();
    }

    if (_allChapters.isEmpty) {
      return _buildEmptyCard();
    }

    return Column(
      children: _allChapters.map((chapter) {
        final index = _allChapters.indexOf(chapter);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildChapterCard(chapter, index),
        );
      }).toList(),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(6, (index) => _buildShimmerChapterCard()),
    );
  }

  Widget _buildShimmerChapterCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 150,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 24,
                  height: 24,
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

  Widget _buildErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading chapters',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchChapters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.getUserType ?? '').toLowerCase() == 'admin';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.grey,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              'No chapters available',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chapters will be added soon for this subject',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Add First Chapter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(String chapter, int index) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.getUserType ?? '').toLowerCase() == 'admin';
    final isFirstItem = index == 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
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
            return _buildShimmerChapterCard();
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return _buildChapterContent(
              chapter: chapter,
              isFirstItem: isFirstItem,
              hasNotes: false,
              pdfUrl: '',
              isAdmin: isAdmin,
              isError: true,
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final resources = data?['resources'] as Map<String, dynamic>?;
          final pdfUrl = resources?['pdf'] as String? ?? "";

          return _buildChapterContent(
            chapter: chapter,
            isFirstItem: isFirstItem,
            hasNotes: pdfUrl.isNotEmpty,
            pdfUrl: pdfUrl,
            isAdmin: isAdmin,
            isError: false,
          );
        },
      ),
    );
  }

  Widget _buildChapterContent({
    required String chapter,
    required bool isFirstItem,
    required bool hasNotes,
    required String pdfUrl,
    required bool isAdmin,
    required bool isError,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onLongPress: isAdmin ? () => _deleteChapter(chapter) : null,
      onTap: () {
        if (hasNotes) {
          _openNotesOrUpsell(pdfUrl, chapter);
        } else if (isAdmin && !hasNotes) {
          _uploadPdfDialog(chapter);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("No notes available yet."),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      },
      splashColor: Colors.indigoAccent.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isFirstItem ? Colors.indigoAccent : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.book_outlined,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chapter,
                          style: AppTheme.subheadingStyle.copyWith(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFirstItem && hasNotes) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AVAILABLE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasNotes
                        ? 'Notes available - tap to view'
                        : isAdmin
                            ? 'Tap to upload notes'
                            : 'Notes not available yet',
                    style: AppTheme.captionStyle.copyWith(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            _buildTrailingWidget(hasNotes, isAdmin, isError),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(bool hasNotes, bool isAdmin, bool isError) {
    if (isError) {
      return const Icon(
        Icons.error_outline,
        color: Colors.red,
        size: 20,
      );
    } else if (!hasNotes && isAdmin) {
      return const Icon(
        Icons.cloud_upload,
        color: Colors.indigoAccent,
        size: 20,
      );
    } else if (hasNotes) {
      return const Icon(
        Icons.arrow_forward_ios,
        color: Colors.indigoAccent,
        size: 20,
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.lock,
          color: Colors.white,
          size: 20,
        ),
      );
    }
  }

  void _uploadPdfDialog(String chapterId) {
    final auth = context.read<AuthProvider>();
    final isAdmin = (auth.getUserType ?? '').toLowerCase() == 'admin';
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Only admins can upload notes'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    color: Colors.indigoAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Upload PDF for '${widget.chapterId}'",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Success')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage.contains('Success')
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: _statusMessage.contains('Success')
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('Success')
                              ? Colors.green
                              : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isUploading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigoAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Uploading...',
                          style: AppTheme.subheadingStyle.copyWith(
                            fontSize: 14,
                            color: Colors.indigoAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_uploadProgress.toStringAsFixed(0)}%",
                          style: AppTheme.captionStyle.copyWith(
                            fontSize: 14,
                            color: Colors.indigoAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _uploadProgress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.indigoAccent),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isUploading ? null : _pickAndUploadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload),
                  const SizedBox(width: 8),
                  Text(
                    _isUploading ? 'Uploading...' : 'Select PDF',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
        setState(() => _isUploading = false);
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
        final totalBytes = snapshot.totalBytes == 0 ? 1 : snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        final progress = (transferred / totalBytes) * 100.0;
        setState(() => _uploadProgress = progress);
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
          .set({
        "resources": {"pdf": downloadUrl},
      }, SetOptions(merge: true));

      setState(() {
        _isUploading = false;
        _statusMessage = "Uploaded Successfully!";
      });

      widget.onUploadDone();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error uploading PDF: $e";
        _isUploading = false;
      });
    }
  }
}
