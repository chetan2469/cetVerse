import 'package:cet_verse/features/courses/mcq/chapter_wise_mcq.dart';
import 'package:cet_verse/features/courses/tests/chapter_wise_test.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:shimmer/shimmer.dart';

class Chapters extends StatefulWidget {
  final String level;
  final String subject;

  const Chapters({
    super.key,
    required this.level,
    required this.subject,
  });

  @override
  _ChaptersState createState() => _ChaptersState();
}

class _ChaptersState extends State<Chapters> {
  bool _isLoading = true;
  List<String> _allChapters = [];
  String _selectedMode = "test";
  String _statusMessage = "";
  String? _userType;

  final Map<String, IconData> subjectIcons = {
    "Physics": Icons.science_outlined,
    "Chemistry": Icons.biotech_outlined,
    "Mathematics": Icons.calculate_outlined,
    "Mathematics Part I": Icons.calculate_outlined,
    "Mathematics Part II": Icons.poll_rounded,
    "Biology": Icons.local_florist_outlined,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() => _isLoading = true);

      // Get user type
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phoneNumber = authProvider.userPhoneNumber;

      if (phoneNumber == null) {
        throw Exception("User phone number is not available");
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _userType = userData['userType'] as String?;
      } else {
        throw Exception("User data not found");
      }

      // Fetch chapters
      await _fetchChapters();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error initializing data: $e";
      });
    }
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
        // Sort chapters numerically
        _allChapters.sort((a, b) {
          final aNum = _extractChapterNumber(a);
          final bNum = _extractChapterNumber(b);
          return aNum.compareTo(bNum);
        });
        _isLoading = false;
        _statusMessage = "";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error loading chapters: $e";
      });
    }
  }

  // Helper function to extract chapter number
  int _extractChapterNumber(String chapterName) {
    final match = RegExp(r'^(\d+)-').firstMatch(chapterName);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    // Return a large number for non-matching chapters to appear at the end
    return 999999;
  }

  Future<void> handleRefresh() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });
    await _fetchChapters();
  }

  Future<void> _deleteChapter(String chapter) async {
    try {
      await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(chapter)
          .delete();

      await _fetchChapters();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Chapter '$chapter' deleted successfully"),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting chapter: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _addChapter(String chapterName) async {
    if (chapterName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Chapter name cannot be empty"),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(chapterName)
          .set({});

      await _fetchChapters();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Chapter '$chapterName' added successfully"),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding chapter: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showAddChapterDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.add_circle_outline,
                color: Colors.indigoAccent, size: 20),
            const SizedBox(width: 8),
            const Text("Add New Chapter", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter chapter name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () {
              _addChapter(controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text("Add Chapter", style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text("Delete Chapter", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
            "Are you sure you want to delete '$chapter'? This action cannot be undone.",
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteChapter(chapter);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text("Delete", style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final displayLevel = widget.level == '12th Standard'
        ? 'Class 12'
        : widget.level == '11th Standard'
            ? 'Class 11'
            : widget.level;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const MyDrawer(),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.subject} Chapters",
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 48,
        actions: [
          if (_userType == 'Admin')
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() => _selectedMode = value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "practice",
                  child: Row(
                    children: [
                      Icon(Icons.quiz_outlined,
                          color: Colors.indigoAccent, size: 18),
                      const SizedBox(width: 8),
                      const Text("Practice MCQ",
                          style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "test",
                  child: Row(
                    children: [
                      Icon(Icons.assignment_outlined,
                          color: Colors.indigoAccent, size: 18),
                      const SizedBox(width: 8),
                      const Text("Take Test", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.black, size: 20),
            ),
        ],
      ),
      floatingActionButton: _userType == 'Admin'
          ? FloatingActionButton.extended(
              onPressed: _showAddChapterDialog,
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add Chapter", style: TextStyle(fontSize: 14)),
              heroTag: "addChapter",
            )
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(displayLevel),
                  const SizedBox(height: 16),
                  Text(
                    "Choose Chapter",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String displayLevel) {
    final subjectIcon = subjectIcons[widget.subject] ?? Icons.book_outlined;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                subjectIcon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subject,
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayLevel,
                    style: AppTheme.captionStyle.copyWith(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _selectedMode == "test"
                          ? Colors.green.withOpacity(0.1)
                          : Colors.indigoAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _selectedMode == "test" ? 'Test Mode' : 'Practice Mode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _selectedMode == "test"
                            ? Colors.green
                            : Colors.indigoAccent,
                      ),
                    ),
                  ),
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

    return _buildChaptersList();
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(6, (index) => _buildShimmerChapterCard()),
    );
  }

  Widget _buildShimmerChapterCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 100,
                        height: 12,
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
                  width: 20,
                  height: 20,
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Error loading chapters',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _statusMessage,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: handleRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 14,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.grey,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No chapters available',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chapters will be added soon for this subject',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (_userType == 'Admin') ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showAddChapterDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Add First Chapter',
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildChaptersList() {
    return Column(
      children: _allChapters.map((chapter) {
        final index = _allChapters.indexOf(chapter);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildChapterCard(chapter: chapter, index: index),
        );
      }).toList(),
    );
  }

  Widget _buildChapterCard({required String chapter, required int index}) {
    final subjectIcon = subjectIcons[widget.subject] ?? Icons.book_outlined;
    final isFirstItem = index == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_selectedMode == "practice") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChapterWiseMcq(
                  level: widget.level,
                  subject: widget.subject,
                  chapter: chapter,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChapterWiseTest(
                  level: widget.level,
                  subject: widget.subject,
                  chapter: chapter,
                ),
              ),
            );
          }
        },
        onLongPress: _userType == 'Admin'
            ? () => _showDeleteConfirmationDialog(chapter)
            : null,
        splashColor: Colors.indigoAccent.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isFirstItem ? Colors.indigoAccent : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  subjectIcon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
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
                        if (isFirstItem) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'POPULAR',
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
                      _selectedMode == "test"
                          ? 'Take chapter test'
                          : 'Practice chapter MCQs',
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.indigoAccent,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
