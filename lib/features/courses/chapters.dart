import 'package:cet_verse/features/courses/mcq/chapter_wise_mcq.dart';
import 'package:cet_verse/features/courses/tests/chapter_wise_test.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';

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

class _ChaptersState extends State<Chapters> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<String> _allChapters = [];
  String _selectedMode = "test";
  String _statusMessage = "";
  String? _userType;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, IconData> subjectIcons = {
    "Physics": Icons.science_outlined,
    "Chemistry": Icons.biotech_outlined,
    "Mathematics": Icons.calculate_outlined,
    "Mathematics Part I": Icons.calculate_outlined,
    "Mathematics Part II": Icons.poll_rounded,
    "Biology": Icons.local_florist_outlined,
  };

  final Map<String, Color> subjectColors = {
    "Physics": Colors.blue,
    "Chemistry": Colors.green,
    "Mathematics": Colors.purple,
    "Mathematics Part I": Colors.purple,
    "Mathematics Part II": Colors.indigo,
    "Biology": Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
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
      await Future.delayed(const Duration(milliseconds: 800)); // Show shimmer

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
        _statusMessage = "";
      });

      // Start animations after loading
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error loading chapters: $e";
      });
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            const Text("Add New Chapter"),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Enter chapter name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              _addChapter(controller.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Add Chapter"),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text("Delete Chapter"),
          ],
        ),
        content: Text(
            "Are you sure you want to delete '$chapter'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text("Cancel", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteChapter(chapter);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
      backgroundColor: Colors.grey.shade50,
      drawer: const MyDrawer(),
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "${widget.subject} Chapters",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor:
            _userType == 'Admin' ? Colors.orange.shade100 : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        actions: [
          if (_userType == 'Admin')
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() => _selectedMode = value);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "practice",
                    child: Row(
                      children: [
                        Icon(Icons.quiz_outlined, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text("Practice MCQ"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "test",
                    child: Row(
                      children: [
                        Icon(Icons.assignment_outlined,
                            color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        const Text("Take Test"),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert, color: Colors.black87),
              ),
            ),
        ],
      ),
      floatingActionButton: _userType == 'Admin'
          ? FloatingActionButton.extended(
              onPressed: _showAddChapterDialog,
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text("Add Chapter"),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: handleRefresh,
                color: Colors.blue.shade600,
                backgroundColor: Colors.white,
                displacement: 40,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String displayLevel) {
    final subjectColor = subjectColors[widget.subject] ?? Colors.blue;
    final subjectIcon = subjectIcons[widget.subject] ?? Icons.book_outlined;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              subjectIcon,
              size: 32,
              color: subjectColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  displayLevel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _selectedMode == "test"
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedMode == "test"
                          ? Colors.green.shade300
                          : Colors.blue.shade300,
                    ),
                  ),
                  child: Text(
                    _selectedMode == "test" ? 'Test Mode' : 'Practice Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _selectedMode == "test"
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerContent();
    }

    if (_statusMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_allChapters.isEmpty) {
      return _buildEmptyState();
    }

    return _buildChaptersList();
  }

  Widget _buildShimmerContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
            8,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildShimmerCard(delay: 1000 + (index * 100)),
                )),
      ),
    );
  }

  Widget _buildShimmerCard({required int delay}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: Duration(milliseconds: delay),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Chapters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Chapters Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chapters will be added soon for this subject',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (_userType == 'Admin') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddChapterDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add First Chapter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _allChapters.length,
            itemBuilder: (context, index) {
              final chapter = _allChapters[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    final clampedValue = value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: clampedValue,
                        child: child,
                      ),
                    );
                  },
                  child: _buildChapterCard(chapter: chapter, index: index),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard({required String chapter, required int index}) {
    final subjectColor = subjectColors[widget.subject] ?? Colors.blue;
    final subjectIcon = subjectIcons[widget.subject] ?? Icons.book_outlined;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: subjectColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_selectedMode == "practice") {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ChapterWiseMcq(
                    level: widget.level,
                    subject: widget.subject,
                    chapter: chapter,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            } else {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ChapterWiseTest(
                    level: widget.level,
                    subject: widget.subject,
                    chapter: chapter,
                  ),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            }
          },
          onLongPress: _userType == 'Admin'
              ? () => _showDeleteConfirmationDialog(chapter)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    subjectIcon,
                    size: 24,
                    color: subjectColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedMode == "test" ? 'Take Test' : 'Practice MCQ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: subjectColor,
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
