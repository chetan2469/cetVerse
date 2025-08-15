import 'package:cet_verse/features/courses/study_type.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class LevelSubjects extends StatefulWidget {
  final String title;
  final String lessons;
  final String rating;
  final String image;

  const LevelSubjects({
    super.key,
    required this.title,
    required this.lessons,
    required this.rating,
    required this.image,
  });

  @override
  _LevelSubjectsState createState() => _LevelSubjectsState();
}

class _LevelSubjectsState extends State<LevelSubjects> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshSubjects() async {
    setState(() {}); // Triggers a rebuild, re-executing the FutureBuilder
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.title == '12th Standard'
        ? 'Class 12'
        : widget.title == '11th Standard'
            ? 'Class 11'
            : widget.title;

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        drawer: const MyDrawer(),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            displayTitle,
            style: AppTheme.subheadingStyle.copyWith(fontSize: 12),
          ),
          elevation: 2,
        ),
        body: RefreshIndicator(
          onRefresh: _refreshSubjects,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  displayTitle,
                  style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 8),
                _buildSubjectsColumn(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Course Header
  Widget _buildCourseHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Image.network(
              widget.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => SizedBox(
                height: 180,
                child: const Center(
                  child: Icon(Icons.error, size: 40),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: 180,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
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
    final displayTitle = widget.title == '12th Standard'
        ? 'Class 12'
        : widget.title == '11th Standard'
            ? 'Class 11'
            : widget.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayTitle,
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 22,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.book_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  widget.lessons,
                  style: AppTheme.captionStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 16),
                const SizedBox(width: 6),
                Text(
                  widget.rating,
                  style: AppTheme.captionStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 6),
                Text(
                  "5,000 Enrolled",
                  style: AppTheme.captionStyle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Subjects displayed in a vertical column
  Widget _buildSubjectsColumn(BuildContext context) {
    // Define the desired subject order
    const List<String> desiredOrder = [
      "Physics",
      "Chemistry",
      "Mathematics",
      "Mathematics Part I",
      "Mathematics Part II",
      "Biology"
    ];

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.title)
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
              style: const TextStyle(),
            ),
          );
        }

        // Get available subjects from Firestore
        List<String> availableSubjects =
            snapshot.data!.docs.map((doc) => doc.id).toList();

        // Filter subjects to only include those in desiredOrder and maintain that order
        List<String> subjects = desiredOrder
            .where((subject) => availableSubjects.contains(subject))
            .toList();

        final Map<String, IconData> subjectIcons = {
          "Physics": Icons.science_outlined,
          "Chemistry": Icons.biotech_outlined,
          "Mathematics": Icons.calculate_outlined,
          "Mathematics Part I": Icons.calculate_outlined,
          "Mathematics Part II": Icons.poll_rounded,
          "Biology": Icons.local_florist_outlined,
        };

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final icon = subjectIcons[subject] ?? Icons.subject_outlined;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildSubjectCard(
                    context,
                    title: subject,
                    icon: icon,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudyType(
                            level: widget.title,
                            subject: subject,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Subject card for column layout
  Widget _buildSubjectCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Icon
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                    ),
                  ),
                ),
                // Title
                Expanded(
                  child: Text(
                    "Practice $title",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Arrow
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
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
