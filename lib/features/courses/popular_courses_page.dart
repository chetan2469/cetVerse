import 'dart:async';
import 'package:cet_verse/features/BoardPapersPage.dart';
import 'package:cet_verse/features/ToppersNotesPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';
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

  // Track initial loading until at least some images are ready (or timeout).
  bool _initialLoading = true;

  // Track per-card image readiness to end initial skeleton ASAP.
  final Map<String, bool> _imgReady = {
    '11th Standard': false,
    '12th Standard': false,
    'PYQ': false,
    'Toppers Notes': false,
    'Boards Papers': false,
  };

  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    // Safety timeout so skeleton doesn't stay forever (e.g., slow network).
    _fallbackTimer =
        Timer(const Duration(milliseconds: 200), _endInitialLoading);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _markReady(String key) {
    if (_imgReady[key] == true) return;
    _imgReady[key] = true;
    // As soon as ANY first image is ready, drop the page skeleton.
    if (_initialLoading && _imgReady.values.any((v) => v)) {
      _endInitialLoading();
    }
    setState(() {}); // refresh to update per-card shimmer if needed
  }

  void _endInitialLoading() {
    if (!_initialLoading) return;
    _initialLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_initialLoading) {
      return _buildPageSkeleton(context);
    }

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
                  onImageReady: () => _markReady('11th Standard'),
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
                  onImageReady: () => _markReady('12th Standard'),
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
            onImageReady: () => _markReady('PYQ'),
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
                  onImageReady: () => _markReady('Toppers Notes'),
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
                  onImageReady: () => _markReady('Boards Papers'),
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

  // Initial page-level skeleton (mirrors layout)
  Widget _buildPageSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(width: 160, height: 20, radius: 8),
          const SizedBox(height: 16),

          // Row 1 skeleton
          Row(
            children: [
              Expanded(child: _cardSkeleton(isFullWidth: false)),
              const SizedBox(width: 16),
              Expanded(child: _cardSkeleton(isFullWidth: false)),
            ],
          ),
          const SizedBox(height: 16),

          // Full width skeleton
          _cardSkeleton(isFullWidth: true),
          const SizedBox(height: 16),

          // Row 2 skeleton
          Row(
            children: [
              Expanded(child: _cardSkeleton(isFullWidth: false)),
              const SizedBox(width: 16),
              Expanded(child: _cardSkeleton(isFullWidth: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardSkeleton({required bool isFullWidth}) {
    final h = isFullWidth ? 160.0 : 100.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _shimmerFill(height: h),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 120, height: 16, radius: 8),
                const SizedBox(height: 6),
                _shimmerBox(width: 160, height: 12, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerFill({required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
          height: height, width: double.infinity, color: Colors.white),
    );
  }

  Widget _shimmerBox(
      {double width = double.infinity,
      required double height,
      double radius = 8}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
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
  final VoidCallback? onImageReady;

  const _PopularCourseCard({
    required this.title,
    required this.lessons,
    required this.rating,
    required this.image,
    required this.bgColor,
    required this.onTap,
    this.isFullWidth = false,
    this.onImageReady,
  });

  @override
  State<_PopularCourseCard> createState() => _PopularCourseCardState();
}

class _PopularCourseCardState extends State<_PopularCourseCard> {
  bool _isCached = false;
  bool _notifiedReady = false;
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
    _precheckCache();
  }

  Future<void> _precheckCache() async {
    final entry = await _cacheManager.getFileFromCache(widget.image);
    if (!mounted) return;
    if (entry != null && await entry.file.exists()) {
      setState(() => _isCached = true);
      _notifyReadyOnce();
    }
  }

  void _notifyReadyOnce() {
    if (_notifiedReady) return;
    _notifiedReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onImageReady?.call();
    });
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
    // If we already know it’s cached, render directly with provider.
    if (_isCached) {
      return Image(
        image: CachedNetworkImageProvider(
          widget.image,
          cacheManager: _cacheManager,
        ),
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        // Prevent “blink” when parent rebuilds:
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

    // Otherwise use CachedNetworkImage with shimmer only during first fetch.
    return CachedNetworkImage(
      imageUrl: widget.image,
      cacheManager: _cacheManager,
      height: imageHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      // Show shimmer only while downloading (no shimmer after cached).
      placeholder: (_, __) => _imageShimmer(height: imageHeight),
      errorWidget: (_, __, ___) => Container(
        height: imageHeight,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.error, color: Colors.red)),
      ),
      // Kill cross-fade to avoid flicker:
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      // Keep previous frame when rebuilding:
      useOldImageOnUrlChange: true,
      memCacheHeight:
          (imageHeight * MediaQuery.of(context).devicePixelRatio).round(),
      imageBuilder: (ctx, provider) {
        _notifyReadyOnce();
        // After first successful load, we consider it cached for future rebuilds.
        if (!_isCached) {
          // Do not call setState synchronously during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isCached = true);
          });
        }
        return Image(
          image: provider,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }

  Widget _imageShimmer({required double height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
          height: height, width: double.infinity, color: Colors.white),
    );
  }
}
