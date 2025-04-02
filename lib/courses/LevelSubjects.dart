import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/MyDrawer.dart';
import 'package:cet_verse/constants.dart'; // Contains AppTheme definitions
import 'package:cet_verse/courses/StudyType.dart'; // The intermediate page

class LevelSubjects extends StatelessWidget {
  final String title;
  final String lessons;
  final String instructor;
  final String rating;
  final String image;

  const LevelSubjects({
    super.key,
    required this.title,
    required this.lessons,
    required this.instructor,
    required this.rating,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        drawer: const MyDrawer(),
        // CETverse UI: background can remain white or some subtle color
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          title: Text(
            title,
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
          ),
          elevation: 2,
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header Section with a bold gradient & hero-style card
              _buildCourseHeader(context),
              const SizedBox(height: 24),
              Text(
                "Practice",
                style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              // Grid of subjects
              _buildSubjectsGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  /// CETverse UI header: bold gradient overlay on image
  Widget _buildCourseHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background image
          SizedBox(
            height: 180, // Slightly bigger for a more immersive feel
            width: double.infinity,
            child: Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 40),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
          // Gradient overlay from top to bottom
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Text content near bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildHeaderText(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 22,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(1, 1),
                blurRadius: 3,
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Row with Lessons & Instructor
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.book_outlined,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  lessons,
                  style: AppTheme.captionStyle.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  instructor,
                  style: AppTheme.captionStyle.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 6),
        // Row with rating & enrolled
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  rating,
                  style: AppTheme.captionStyle.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  "5,000 Enrolled",
                  style: AppTheme.captionStyle.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Grid of subjects (CETverse UI style with gradient or color pops)
  Widget _buildSubjectsGrid(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('levels')
          .doc(title)
          .collection('subjects')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading subjects: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No subjects found."));
        }

        List<String> subjects =
            snapshot.data!.docs.map((doc) => doc.id).toList();

        final Map<String, Color> subjectColors = {
          "Physics": Colors.blue.shade200,
          "Chemistry": Colors.green.shade200,
          "Mathematics": Colors.orange.shade300,
          "Mathematics Part I": const Color.fromARGB(255, 95, 228, 179),
          "Mathematics Part II": const Color.fromARGB(255, 234, 176, 89),
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

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: subjects.map((subject) {
            final color = subjectColors[subject] ?? Colors.grey.shade300;
            final icon = subjectIcons[subject] ?? Icons.subject_outlined;

            return _buildSubjectCard(
              context,
              title: subject,
              icon: icon,
              color: color,
              onTap: () {
                // Navigate to StudyType
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudyType(
                      level: title,
                      subject: subject,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// Each subject card with a gradient border or highlight
  Widget _buildSubjectCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: color.withOpacity(0.3),
          highlightColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              // Subtle gradient
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  color.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with colored background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.25),
                  ),
                  child: Icon(
                    icon,
                    size: 42,
                    color: color,
                  ),
                ),
                const SizedBox(height: 10),
                // Subject Title
                Text(
                  title,
                  style: AppTheme.subheadingStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
