import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/ui/components/ProgressPage.dart';

enum StreamFilter { pcm, pcb, both }

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Animation for progress bars
  late final AnimationController _controller;

  // Canonical map of subjects -> % (0..100)
  Map<String, double> _subjectPerformance = const {
    'Physics': 0.0,
    'Chemistry': 0.0,
    'Maths': 0.0,
    'Biology': 0.0,
  };

  // UI state
  bool _isLoading = true;
  String? _error;
  StreamFilter _selected = StreamFilter.both;

  // Cache: avoid refetch if widget kept alive
  bool _fetchedOnce = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    // Fetch immediately
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
    if (_fetchedOnce) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = context.read<AuthProvider>();
    final userPhoneNumber = authProvider.userPhoneNumber;

    if (userPhoneNumber == null || userPhoneNumber.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'User not detected.';
      });
      return;
    }

    try {
      // Limit reads; if list is big consider pagination or server aggregation.
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('testHistory')
          .get(const GetOptions(source: Source.serverAndCache));

      // Aggregate generically
      final Map<String, Map<String, int>> agg = {
        'Physics': {'correct': 0, 'total': 0},
        'Chemistry': {'correct': 0, 'total': 0},
        'Maths': {'correct': 0, 'total': 0},
        'Biology': {'correct': 0, 'total': 0},
      };

      for (final doc in snap.docs) {
        final data = doc.data();
        final subject = (data['subject'] as String?)?.trim();
        if (subject != null && agg.containsKey(subject)) {
          final correct = (data['correct'] as int?) ?? 0;
          final wrong = (data['wrong'] as int?) ?? 0;
          final unattempted = (data['unattempted'] as int?) ?? 0;
          final total = correct + wrong + unattempted;

          final m = agg[subject]!;
          m['correct'] = (m['correct'] ?? 0) + correct;
          m['total'] = (m['total'] ?? 0) + total;
        }
      }

      final Map<String, double> computed = {
        for (final e in agg.entries)
          e.key: (e.value['total'] ?? 0) > 0
              ? ((e.value['correct'] ?? 0) / (e.value['total']!.toDouble())) *
                  100.0
              : 0.0
      };

      setState(() {
        _subjectPerformance = computed;
        _isLoading = false;
        _fetchedOnce = true;
        _error = null;
      });

      _controller
        ..reset()
        ..forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load. Tap to retry.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _visibleSubjects {
    switch (_selected) {
      case StreamFilter.pcm:
        return const ['Physics', 'Chemistry', 'Maths'];
      case StreamFilter.pcb:
        return const ['Physics', 'Chemistry', 'Biology'];
      case StreamFilter.both:
        return const ['Physics', 'Chemistry', 'Maths', 'Biology'];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return Center(
        child: GestureDetector(
          onTap: _fetchPerformanceData,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSubjectGrid(),
            const SizedBox(height: 16),
            _buildAnalysisButton(),
          ],
        ),
      ),
    );
  }

  // -----------------------
  // UI: Header
  // -----------------------
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.analytics_outlined, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<StreamFilter>(
            value: _selected,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w600,
            ),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selected = v);
              _controller
                ..reset()
                ..forward();
            },
            items: const [
              DropdownMenuItem(value: StreamFilter.pcm, child: Text('PCM')),
              DropdownMenuItem(value: StreamFilter.pcb, child: Text('PCB')),
              DropdownMenuItem(value: StreamFilter.both, child: Text('Both')),
            ],
          ),
        ),
      ],
    );
  }

  // -----------------------
  // UI: Grid of subject cards
  // -----------------------
  Widget _buildSubjectGrid() {
    final subjects = _visibleSubjects;

    if (subjects.length <= 3) {
      return Row(
        children: subjects
            .map(
              (s) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: s == subjects.last ? 0 : 8),
                  child: _compactCard(s),
                ),
              ),
            )
            .toList(),
      );
    }

    // 2x2 for four subjects
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _compactCard(subjects[0]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _compactCard(subjects[1]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _compactCard(subjects[2]),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _compactCard(subjects[3]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _compactCard(String subject) {
    final pct = (_subjectPerformance[subject] ?? 0.0).clamp(0.0, 100.0);
    final colors = _subjectColors(subject);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors['border']!, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Subject + %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  subject,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors['text'],
                  ),
                ),
              ),
              Text(
                '${pct.toInt()}%',
                style: TextStyle(
                  color: colors['progress'],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Animated progress bar
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final value = (_controller.value * (pct / 100)).clamp(0.0, 1.0);
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colors['progress']!),
                  minHeight: 12,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, Color> _subjectColors(String subject) {
    switch (subject) {
      case 'Physics':
        return {
          'background': const Color(0xFFF3F8FF),
          'border': const Color(0xFFE3F2FD),
          'progress': Colors.blue.shade600,
          'text': Colors.blue.shade800,
        };
      case 'Chemistry':
        return {
          'background': const Color(0xFFFFF8F0),
          'border': const Color(0xFFFFE0B2),
          'progress': Colors.orange.shade600,
          'text': Colors.orange.shade800,
        };
      case 'Maths':
        return {
          'background': const Color(0xFFF1F8E9),
          'border': const Color(0xFFDCEDC8),
          'progress': Colors.green.shade600,
          'text': Colors.green.shade800,
        };
      case 'Biology':
        return {
          'background': const Color(0xFFE0F2F1),
          'border': const Color(0xFFB2DFDB),
          'progress': Colors.teal.shade600,
          'text': Colors.teal.shade800,
        };
      default:
        return {
          'background': Colors.grey.shade100,
          'border': Colors.grey.shade300,
          'progress': Colors.blueGrey,
          'text': Colors.blueGrey.shade800,
        };
    }
  }

  // -----------------------
  // UI: CTA Button
  // -----------------------
  Widget _buildAnalysisButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: MaterialButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProgressPage()),
            );
          },
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'View Detailed Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------
  // Shimmer Loading Skeleton
  // -----------------------
  Widget _buildLoadingSkeleton() {
    // While loading, show 4 cards layout (worst case) for visual stability
    final isFour = true;

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerHeader(),
            const SizedBox(height: 16),
            if (!isFour)
              Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                      child: _shimmerCard(),
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _shimmerCard(),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _shimmerCard(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _shimmerCard(),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _shimmerCard(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _shimmerButton(),
          ],
        ),
      ),
    );
  }

  Widget _shimmerHeader() {
    return Row(
      children: [
        _shimmerBox(width: 18, height: 18, radius: 4),
        const SizedBox(width: 8),
        _shimmerBox(width: 110, height: 16, radius: 6),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _shimmerBox(width: 60, height: 14, radius: 8),
        ),
      ],
    );
  }

  Widget _shimmerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 70, height: 12, radius: 6),
              _shimmerBox(width: 26, height: 14, radius: 6),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 12,
                width: double.infinity,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Center(child: _shimmerBox(width: 160, height: 16, radius: 8)),
      ),
    );
  }

  Widget _shimmerBox({
    double width = double.infinity,
    required double height,
    double radius = 8,
  }) {
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
}
