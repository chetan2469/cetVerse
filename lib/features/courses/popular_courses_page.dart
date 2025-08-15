import 'package:cet_verse/features/courses/level_subjects.dart';
import 'package:cet_verse/ui/components/pyq_choice.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class PopularCoursesPage extends StatelessWidget {
  const PopularCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context),
          const SizedBox(height: 16),
          // First row with 12th and 11th Standard
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _PopularCourseCard(
                  title: "11th Standard",
                  lessons: "20% Weightage",
                  rating: "4.9",
                  image:
                      "https://firebasestorage.googleapis.com/v0/b/flutter-chedo.appspot.com/o/a-lifestyle-advertisement-for-11th-cet-p_xa12zj-fQ_Ce0nMau-6psQ_3urzCoX9TFmKehN4HGt-BA%20(1).jpg?alt=media&token=b195a8aa-e912-443c-a781-0dd0c9b7632b",
                  bgColor: AppTheme.designColor ?? Colors.green.shade100,
                  onTap: () => _navigateToCourseDetails(
                      context, "11th Standard", "20% Weightage", "4.9", ""),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PopularCourseCard(
                  title: "12th Standard",
                  lessons: "80% Weightage",
                  rating: "4.9",
                  image:
                      "https://uploads.sarvgyan.com/2024/11/MHT_CET_2025.webp",
                  bgColor: AppTheme.businessColor ?? Colors.blue.shade100,
                  onTap: () => _navigateToCourseDetails(
                      context, "12th Standard", "80% Weightage", "4.9", ""),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Full-width PYQ card
          _PopularCourseCard(
            title: "PYQ",
            lessons: "Previous Year Questions",
            rating: "4.9",
            image:
                "https://firebasestorage.googleapis.com/v0/b/cetverse-6fe07.firebasestorage.app/o/9d2dca43-026d-42d4-8730-37ebf6ca1139.jpg?alt=media&token=e2ba1c70-dbe5-482a-9847-fadf0bedd19c",
            bgColor: AppTheme.tradingColor ?? Colors.orange.shade100,
            onTap: () => _navigateToCourseDetails(
                context, "PYQ", "Previous Year Questions", "4.9", ""),
            isFullWidth: true,
          ),
          const SizedBox(height: 16),
          // Second row with Toppers Notes and Boards Solved Papers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _PopularCourseCard(
                  title: "Toppers Notes",
                  lessons: "Handwritten Notes",
                  rating: "4.8",
                  image:
                      "https://firebasestorage.googleapis.com/v0/b/cetverse-6fe07.firebasestorage.app/o/43740824a81.webp?alt=media&token=434127ee-92f1-4d85-b075-e6d9cdbcdb23",
                  bgColor: Colors.purple.shade100,
                  onTap: () => _navigateToCourseDetails(
                      context, "Toppers Notes", "Handwritten Notes", "4.8", ""),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PopularCourseCard(
                  title: "Boards Papers",
                  lessons: "Solved Papers",
                  rating: "4.7",
                  image:
                      "https://firebasestorage.googleapis.com/v0/b/cetverse-6fe07.firebasestorage.app/o/Pages-from-10-Years-MHT-CET-Chapterwise-Solutions_2025-2.jpg?alt=media&token=a1a47104-7861-4503-8bb3-aff6f00c6897",
                  bgColor: Colors.orange.shade100,
                  onTap: () => _navigateToCourseDetails(
                      context, "Boards Papers", "Solved Papers", "4.7", ""),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Practice Courses",
          style: AppTheme.subheadingStyle ??
              const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
      ],
    );
  }

  void _navigateToCourseDetails(BuildContext context, String title,
      String lessons, String rating, String image) {
    if (title == "PYQ") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PYQChoice()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LevelSubjects(
            title: title,
            lessons: lessons,
            rating: rating,
            image: image,
          ),
        ),
      );
    }
  }
}

class _PopularCourseCard extends StatelessWidget {
  final String title, lessons, rating, image;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isFullWidth;

  const _PopularCourseCard({
    required this.title,
    required this.lessons,
    required this.rating,
    required this.image,
    required this.bgColor,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image with Overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    image,
                    height: isFullWidth ? 160 : 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: isFullWidth ? 160 : 100,
                      color: Colors.grey[300],
                      child: const Center(
                          child: Icon(Icons.error, color: Colors.red)),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: isFullWidth ? 160 : 100,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.orange),
                        const SizedBox(width: 2),
                        Text(
                          rating,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Course Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.subheadingStyle.copyWith(fontSize: 16) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lessons,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
