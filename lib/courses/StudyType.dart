import 'package:flutter/material.dart';
import 'package:cet_verse/courses/Chapters.dart';
import 'package:cet_verse/courses/NotesPage.dart';
import 'package:cet_verse/constants.dart';

class StudyType extends StatelessWidget {
  final String level; // e.g., "11th Standard"
  final String subject; // e.g., "Physics"

  const StudyType({
    super.key,
    required this.level,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// A gradient behind the entire screen
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              const SizedBox(height: 16),
              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          "Select Your Study Type",
                          style: AppTheme.subheadingStyle.copyWith(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Big Card for Mock Test
                        _buildOptionCard(
                          context,
                          icon: Icons.list_alt_outlined,
                          title: "Mock Test",
                          description:
                              "Attempt full-length or chapter-wise tests.\nTrack your progress & scores!",
                          color1: Colors.blueAccent,
                          color2: Colors.deepPurpleAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Chapters(
                                  level: level,
                                  subject: subject,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Big Card for Notes
                        _buildOptionCard(
                          context,
                          icon: Icons.menu_book_rounded,
                          title: "Notes",
                          description:
                              "Access study materials, summaries,\nand important formula sheets.",
                          color1: Colors.teal,
                          color2: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotesPage(
                                  level: level,
                                  subject: subject,
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
      ),
    );
  }

  /// Builds a custom "AppBar" at the top with a back button
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            "Study Type",
            style: AppTheme.subheadingStyle.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// A fancy card-like button for each option
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
      splashColor: Colors.white24,
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
              color: Colors.black54.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon
            Hero(
              tag: title, // If you want a hero animation
              child: Icon(
                icon,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              title,
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              description,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
