import 'package:cet_verse/courses/LevelSubjects.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/constants.dart'; // Assuming this contains AppTheme

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
          const SizedBox(height: 32),
          // Row for 12th and 11th Standard (2 half-width cards)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _PopularCourseCard(
                  title: "12th Standard",
                  lessons: "3500 Questions",
                  instructor: "CET Verse",
                  rating: "4.9",
                  image:
                      "https://uploads.sarvgyan.com/2024/11/MHT_CET_2025.webp",
                  bgColor: AppTheme?.businessColor ?? Colors.blue.shade100,
                  onTap: () => _navigateToCourseDetails(
                      context,
                      "12th Standard",
                      "3500 Questions",
                      "CET Verse",
                      "4.9",
                      "https://uploads.sarvgyan.com/2024/11/MHT_CET_2025.webp"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PopularCourseCard(
                  title: "11th Standard",
                  lessons: "3500 Questions",
                  instructor: "CET Verse",
                  rating: "4.9",
                  image:
                      "https://firebasestorage.googleapis.com/v0/b/flutter-chedo.appspot.com/o/a-lifestyle-advertisement-for-11th-cet-p_xa12zj-fQ_Ce0nMau-6psQ_3urzCoX9TFmKehN4HGt-BA%20(1).jpg?alt=media&token=b195a8aa-e912-443c-a781-0dd0c9b7632b",
                  bgColor: AppTheme?.designColor ?? Colors.green.shade100,
                  onTap: () => _navigateToCourseDetails(
                      context,
                      "11th Standard",
                      "3500 Questions",
                      "CET Verse",
                      "4.9",
                      "https://firebasestorage.googleapis.com/v0/b/flutter-chedo.appspot.com/o/a-lifestyle-advertisement-for-11th-cet-p_xa12zj-fQ_Ce0nMau-6psQ_3urzCoX9TFmKehN4HGt-BA%20(1).jpg?alt=media&token=b195a8aa-e912-443c-a781-0dd0c9b7632b"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Single full-width PYQ card
          _PopularCourseCard(
            title: "PYQ",
            lessons: "Previous Year Questions",
            instructor: "CET Verse",
            rating: "4.9",
            image:
                "https://firebasestorage.googleapis.com/v0/b/cetverse-6fe07.firebasestorage.app/o/9d2dca43-026d-42d4-8730-37ebf6ca1139.jpg?alt=media&token=e2ba1c70-dbe5-482a-9847-fadf0bedd19c", // Example PYQ image
            bgColor: AppTheme?.tradingColor ?? Colors.orange.shade100,
            onTap: () => _navigateToCourseDetails(
                context,
                "PYQ",
                "Previous Year Questions",
                "CET Verse",
                "4.9",
                "https://firebasestorage.googleapis.com/v0/b/cetverse-6fe07.firebasestorage.app/o/9d2dca43-026d-42d4-8730-37ebf6ca1139.jpg?alt=media&token=e2ba1c70-dbe5-482a-9847-fadf0bedd19c"),
            isFullWidth: true, // New parameter to adjust styling
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
          style: AppTheme?.subheadingStyle ??
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
      String lessons, String instructor, String rating, String image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelSubjects(
          title: title,
          lessons: lessons,
          instructor: instructor,
          rating: rating,
          image: image,
        ),
      ),
    );
  }
}

class _PopularCourseCard extends StatelessWidget {
  final String title, lessons, instructor, rating, image;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isFullWidth; // New parameter to control width styling

  const _PopularCourseCard({
    required this.title,
    required this.lessons,
    required this.instructor,
    required this.rating,
    required this.image,
    required this.bgColor,
    required this.onTap,
    this.isFullWidth = false, // Default to false for half-width cards
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    height:
                        isFullWidth ? 120 : 80, // Larger height for full-width
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: isFullWidth ? 120 : 80,
                      color: Colors.grey[300],
                      child: const Center(
                          child: Icon(Icons.error, color: Colors.red)),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: isFullWidth ? 120 : 80,
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
                    style: AppTheme?.subheadingStyle.copyWith(fontSize: 16) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 14,
                        color: AppTheme?.textSecondary ?? Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lessons,
                          style:
                              AppTheme?.captionStyle.copyWith(fontSize: 12) ??
                                  const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppTheme?.textSecondary ?? Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          instructor,
                          style:
                              AppTheme?.captionStyle.copyWith(fontSize: 12) ??
                                  const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
