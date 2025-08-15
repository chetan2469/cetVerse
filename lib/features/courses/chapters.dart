import 'package:cet_verse/features/courses/mcq/chapter_wise_mcq.dart';
import 'package:cet_verse/features/courses/tests/chapter_wise_test.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
      // Fetch userType from AuthProvider
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

  Future<void> handleRefresh() async {
    // Simulate a network call or data reload with a delay
    await Future.delayed(const Duration(seconds: 2));
    // Optionally, trigger specific reloads here, e.g.:
    // - authProvider.fetchUserData(user?.phoneNumber ?? '');
    // - Reload images or data in PopularCoursesPage via a provider
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
        _statusMessage = "";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error loading chapters: $e";
      });
    }
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
        const SnackBar(content: Text("Chapter deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting chapter: $e")),
      );
    }
  }

  Future<void> _addChapter(String chapterName) async {
    if (chapterName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chapter name cannot be empty")),
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
        const SnackBar(content: Text("Chapter added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding chapter: $e")),
      );
    }
  }

  void _showAddChapterDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Chapter"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter chapter name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _addChapter(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Chapter"),
        content: Text("Are you sure you want to delete '$chapter'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _deleteChapter(chapter);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
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

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        drawer: const MyDrawer(),
        appBar: AppBar(
          backgroundColor: _userType == 'Admin'
              ? const Color.fromARGB(255, 219, 218, 213)
              : null,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "${widget.subject} Chapters ($displayLevel)",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 14),
          ),
          elevation: 2,
          actions: [
            _userType == 'Admin'
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _selectedMode = value;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "practice",
                        child: Text("Practice MCQ"),
                      ),
                      const PopupMenuItem(
                        value: "test",
                        child: Text("Take Test"),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  )
                : Container(),
          ],
        ),
        floatingActionButton: _userType == 'Admin'
            ? FloatingActionButton(
                onPressed: _showAddChapterDialog,
                tooltip: "Add Chapter",
                child: const Icon(Icons.add),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: handleRefresh, // Called when user pulls down to refresh
          color: AppTheme.primaryColor ?? Colors.blue, // Spinner color
          backgroundColor: Colors.white, // Background of the spinner
          displacement: 40,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _statusMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _statusMessage,
                        style: AppTheme.captionStyle,
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
                          padding: const EdgeInsets.all(12.0),
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _allChapters.length,
                            itemBuilder: (context, index) {
                              final chapter = _allChapters[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildChapterCard(
                                  chapter: chapter,
                                  icon: subjectIcons[widget.subject] ??
                                      Icons.book_outlined,
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildChapterCard({
    required String chapter,
    required IconData icon,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28),
            ),
            title: Text(
              chapter,
              style: AppTheme.subheadingStyle.copyWith(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      ),
    );
  }
}
