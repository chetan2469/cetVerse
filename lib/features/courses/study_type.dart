import 'package:cet_verse/features/courses/chapters.dart';
import 'package:cet_verse/features/courses/notes/notes_page.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class StudyType extends StatefulWidget {
  final String level;
  final String subject;

  const StudyType({
    super.key,
    required this.level,
    required this.subject,
  });

  @override
  _StudyTypeState createState() => _StudyTypeState();
}

class _StudyTypeState extends State<StudyType> {
  Future<void> _refresh() async {
    setState(() {}); // Rebuilds the UI
    // Add dynamic data fetching here if needed (e.g., Firestore queries)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                backgroundColor: Colors.white,
                color: Colors.indigoAccent, // Matches theme
                strokeWidth: 3.0,
                displacement: 40.0,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Practice ${widget.subject}",
                        style: AppTheme.subheadingStyle.copyWith(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildOptionCard(
                        context,
                        icon: Icons.list_alt_outlined,
                        title: "Mock Test",
                        description:
                            "Attempt full-length PYQ Tests or chapter-wise tests.\nTrack your progress & scores!",
                        color1: Colors.white,
                        color2: Colors.white,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Chapters(
                                level: widget.level,
                                subject: widget.subject,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildOptionCard(
                        context,
                        icon: Icons.menu_book_rounded,
                        title: "Notes",
                        description:
                            "Access study materials, summaries,\nand important formula sheets.",
                        color1: Colors.white,
                        color2: Colors.white,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotesPage(
                                level: widget.level,
                                subject: widget.subject,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      splashColor: Colors.grey.shade200,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 33, 32, 32), size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 20,
                color: const Color.fromARGB(255, 33, 32, 32),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: const Color.fromARGB(179, 59, 58, 58),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
