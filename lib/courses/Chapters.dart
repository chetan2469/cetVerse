import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/MyDrawer.dart';
import 'package:cet_verse/constants.dart'; // Contains AppTheme definitions
import 'package:cet_verse/courses/ChapterWiseMcq.dart';
import 'package:cet_verse/courses/ChapterWiseTest.dart';

class Chapters extends StatefulWidget {
  final String level; // e.g., "11th Standard"
  final String subject; // e.g., "Biology"

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
  List<String> _allChapters = []; // Holds all chapters for listing
  String _selectedMode = "test"; // "practice" or "test"
  String _statusMessage = "";

  // Example color/icon maps from your code
  final Map<String, Color> subjectColors = {
    "Physics": Colors.blue.shade200,
    "Chemistry": Colors.green.shade200,
    "Mathematics": Colors.orange.shade300,
    "Mathematics Part I": Color.fromARGB(255, 95, 228, 179),
    "Mathematics Part II": Color.fromARGB(255, 234, 176, 89),
    "Biology": Colors.purple.shade200,
  };
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
        _isLoading = false;
        _statusMessage = "Error loading chapters: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final subjectColor = subjectColors[widget.subject] ?? Colors.grey.shade200;

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
            "${widget.subject} Chapters",
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
          ),
          elevation: 2,
          backgroundColor: Colors.white,
          // Overflow menu to pick practice or test
          actions: [
            PopupMenuButton<String>(
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
              icon: const Icon(Icons.more_vert, color: Colors.black),
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
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _allChapters.length,
                          itemBuilder: (context, index) {
                            final chapter = _allChapters[index];
                            return _buildChapterCard(
                              chapter: chapter,
                              color: subjectColor,
                              icon: subjectIcons[widget.subject] ??
                                  Icons.book_outlined,
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  /// Builds each chapter card. Tapping it navigates either to
  /// ChapterWiseMcq or ChapterWiseTest depending on _selectedMode
  Widget _buildChapterCard({
    required String chapter,
    required Color color,
    required IconData icon,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withOpacity(0.2),
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
        splashColor: color.withOpacity(0.3),
        highlightColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.1),
              ],
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            title: Text(
              chapter,
              style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
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
