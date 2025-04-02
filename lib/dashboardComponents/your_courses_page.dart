import 'package:flutter/material.dart';
import 'package:cet_verse/constants.dart';

class YourCoursesPage extends StatelessWidget {
  const YourCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("My Courses"),
        const SizedBox(height: 16),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _MyCourseItem(
              title: "11th PCB",
              rating: "4.9",
              reviews: "112 reviews",
              progress: "65% completed",
              image: "assets/logo.png",
              progressValue: 0.65,
            ),
            SizedBox(height: 12),
            _MyCourseItem(
              title: "12 PCB",
              rating: "4.8",
              reviews: "98 reviews",
              progress: "32% completed",
              image: "assets/logo.png",
              progressValue: 0.32,
            ),
            SizedBox(height: 12),
            _MyCourseItem(
              title: "11 PCMB",
              rating: "4.8",
              reviews: "98 reviews",
              progress: "32% completed",
              image: "assets/logo.png",
              progressValue: 0.32,
            ),
            SizedBox(height: 12),
            _MyCourseItem(
              title: "12 PCMB",
              rating: "4.8",
              reviews: "98 reviews",
              progress: "62% completed",
              image: "assets/logo.png",
              progressValue: 0.62,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.subheadingStyle),
        Text(
          "See all",
          style: AppTheme.captionStyle.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MyCourseItem extends StatelessWidget {
  final String title, rating, reviews, progress, image;
  final double progressValue;

  const _MyCourseItem({
    required this.title,
    required this.rating,
    required this.reviews,
    required this.progress,
    required this.image,
    required this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.asset(image, height: 90, width: 90, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text("$rating ($reviews)", style: AppTheme.captionStyle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(progress, style: AppTheme.captionStyle),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.play_circle_filled,
                            color: AppTheme.primaryColor),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
