import 'dart:async';
import 'package:cet_verse/features/BoardPapersPage.dart';
import 'package:cet_verse/features/ToppersNotesPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:cet_verse/features/courses/level_subjects.dart';
import 'package:cet_verse/ui/components/pyq_choice.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class PopularCoursesPage extends StatefulWidget {
  const PopularCoursesPage({super.key});

  @override
  State<PopularCoursesPage> createState() => _PopularCoursesPageState();
}

class _PopularCoursesPageState extends State<PopularCoursesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context),
          const SizedBox(height: 16),

          // Row 1: 11th & 12th
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _PopularCourseCard(
                  title: "11th Standard",
                  lessons: "20% Weightage",
                  rating: "4.9",
                  image:
                      "https://firebasestorage.googleapis.com/v0/b/cetverse-6fe07.firebasestorage.app/o/11thProfile.jpg?alt=media&token=95da4ee1-ca6e-4904-856f-903f5b3a3ea9",
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
                      "https://firebasestorage.googleapis.com/v0/b/cetverse-6fe07.firebasestorage.app/o/12thProfile.jpg?alt=media&token=432fee32-1549-46cb-8532-46623f241e5a",
                  bgColor: AppTheme.businessColor ?? Colors.blue.shade100,
                  onTap: () => _navigateToCourseDetails(
                      context, "12th Standard", "80% Weightage", "4.9", ""),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Full-width PYQ
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

          // Row 2: Toppers Notes & Boards Papers
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
                  onTap: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ToppersNotesPage(),
                      ),
                    )
                  },
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
                  onTap: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BoardPapersPage(),
                      ),
                    )
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Header
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
          context, MaterialPageRoute(builder: (context) => const PYQChoice()));
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

class _PopularCourseCard extends StatefulWidget {
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
  State<_PopularCourseCard> createState() => _PopularCourseCardState();
}

class _PopularCourseCardState extends State<_PopularCourseCard> {
  late final BaseCacheManager _cacheManager;

  @override
  void initState() {
    super.initState();
    _cacheManager = CacheManager(
      Config(
        'cet_verse_images',
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 200,
        repo: JsonCacheInfoRepository(databaseName: 'cet_verse_images'),
        fileService: HttpFileService(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = widget.isFullWidth ? 160.0 : 100.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: widget.bgColor.withOpacity(0.3),
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
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildCachedImage(imageHeight),
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
                          widget.rating,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: (AppTheme.subheadingStyle ??
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ))
                        .copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.lessons,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
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

  Widget _buildCachedImage(double imageHeight) {
    return CachedNetworkImage(
      imageUrl: widget.image,
      cacheManager: _cacheManager,
      height: imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: imageHeight,
        width: double.infinity,
        color: Colors.grey.shade300,
      ),
      errorWidget: (_, __, ___) => Container(
        height: imageHeight,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.error, color: Colors.red)),
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      useOldImageOnUrlChange: true,
      memCacheHeight:
          (imageHeight * MediaQuery.of(context).devicePixelRatio).round(),
    );
  }
}
