import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/tests/test_confirmation_page.dart';
import 'package:cet_verse/screens/pricing_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class ChapterWiseTest extends StatefulWidget {
  final String level;
  final String subject;
  final String chapter;

  const ChapterWiseTest({
    super.key,
    required this.level,
    required this.subject,
    required this.chapter,
  });

  @override
  State<ChapterWiseTest> createState() => _ChapterWiseTestState();
}

class _ChapterWiseTestState extends State<ChapterWiseTest> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMcqs = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMcqs();
  }

  Future<void> _fetchMcqs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level)
          .collection('subjects')
          .doc(widget.subject)
          .collection('chapters')
          .doc(widget.chapter)
          .collection('mcqs')
          .get();

      setState(() {
        _allMcqs = snapshot.docs.map((doc) {
          final data = doc.data();
          return {...data, 'docId': doc.id};
        }).toList();
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Error loading MCQs: $e";
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading MCQs: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    await _fetchMcqs();
  }

  // Split MCQs into tests of 20 each
  List<List<Map<String, dynamic>>> _groupMcqsIntoTests() {
    const int testSize = 20;
    final tests = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < _allMcqs.length; i += testSize) {
      tests.add(_allMcqs.sublist(i,
          (i + testSize > _allMcqs.length) ? _allMcqs.length : i + testSize));
    }
    return tests;
  }

  bool _isTestAccessible(BuildContext context, int testIndexZeroBased) {
    final auth = context.read<AuthProvider>();
    if (auth.fullMockTestSeries) return true;
    final max = auth.mockTestsPerSubject;
    return testIndexZeroBased < max;
  }

  void _handleTestTap(BuildContext context, int testIndexZeroBased,
      List<Map<String, dynamic>> testMcqs) {
    if (!_isTestAccessible(context, testIndexZeroBased)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Upgrade plan to unlock more chapter-wise tests"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Upgrade',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PricingPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestConfirmationPage(
          level: widget.level,
          subject: widget.subject,
          chapter: widget.chapter,
          testNumber: testIndexZeroBased + 1,
          mcqs: testMcqs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayLevel = widget.level == '12th Standard'
        ? 'Class 12'
        : widget.level == '11th Standard'
            ? 'Class 11'
            : widget.level;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 48, // Reduced height
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.chapter} Tests",
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 18, // Updated to 18
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16), // Reduced padding
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(auth, displayLevel),
                  const SizedBox(height: 16), // Reduced spacing
                  Text(
                    "Available Tests",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 16, // Updated to 16
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16), // Reduced spacing
                  _buildContent(auth),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, String displayLevel) {
    final subtitleText = auth.fullMockTestSeries
        ? 'Unlimited tests available'
        : 'First ${auth.mockTestsPerSubject} tests available';

    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Reduced radius
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2), // Minimized shadow opacity
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(8), // Reduced radius
              ),
              child: const Icon(
                Icons.quiz,
                color: Colors.white,
                size: 24, // Reduced size
              ),
            ),
            const SizedBox(width: 16), // Reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chapter,
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 16, // Updated to 16
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4), // Reduced spacing
                  Text(
                    '${widget.subject} • $displayLevel',
                    style: AppTheme.captionStyle.copyWith(
                      fontSize: 14, // Updated to 14
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4), // Reduced padding
                    decoration: BoxDecoration(
                      color: auth.fullMockTestSeries
                          ? Colors.indigoAccent.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8), // Reduced radius
                    ),
                    child: Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 12, // Updated to 12
                        fontWeight: FontWeight.w500,
                        color: auth.fullMockTestSeries
                            ? Colors.indigoAccent
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AuthProvider auth) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return _buildErrorCard();
    }

    final tests = _groupMcqsIntoTests();

    if (tests.isEmpty) {
      return _buildEmptyCard();
    }

    return Column(
      children: tests.asMap().entries.map((entry) {
        final index = entry.key;
        final testMcqs = entry.value;
        final locked = !_isTestAccessible(context, index);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
          child: _buildTestCard(index, testMcqs, locked),
        );
      }).toList(),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(3, (index) => _buildShimmerTestCard()),
    );
  }

  Widget _buildShimmerTestCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
      child: Card(
        elevation: 2, // Reduced elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Reduced radius
        ),
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.2), // Minimized shadow opacity
        child: Padding(
          padding: const EdgeInsets.all(16), // Reduced padding
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 40, // Reduced size
                  height: 40, // Reduced size
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8), // Reduced radius
                  ),
                ),
              ),
              const SizedBox(width: 16), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 100, // Reduced width
                        height: 16, // Reduced height
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 140, // Reduced width
                        height: 12, // Reduced height
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 50, // Reduced width
                  height: 28, // Reduced height
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6), // Reduced radius
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Reduced radius
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2), // Minimized shadow opacity
      child: Padding(
        padding: const EdgeInsets.all(20), // Reduced padding
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40, // Reduced size
            ),
            const SizedBox(height: 12), // Reduced spacing
            Text(
              'Error loading tests',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16, // Updated to 16
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              _errorMessage!,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14, // Updated to 14
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12), // Reduced spacing
            ElevatedButton(
              onPressed: _fetchMcqs,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8), // Reduced padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Reduced radius
                ),
                elevation: 2, // Reduced elevation
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 14, // Updated to 14
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Reduced radius
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2), // Minimized shadow opacity
      child: Padding(
        padding: const EdgeInsets.all(20), // Reduced padding
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.grey,
              size: 40, // Reduced size
            ),
            const SizedBox(height: 12), // Reduced spacing
            Text(
              'No tests available',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16, // Updated to 16
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              'No MCQs found for this chapter.\nTests will be available once content is added.',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14, // Updated to 14
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(
      int index, List<Map<String, dynamic>> testMcqs, bool locked) {
    final isFirstItem = index == 0;

    return Card(
      elevation: 2, // Reduced elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Reduced radius
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2), // Minimized shadow opacity
      child: InkWell(
        borderRadius: BorderRadius.circular(12), // Reduced radius
        onTap: () => _handleTestTap(context, index, testMcqs),
        splashColor: Colors.indigoAccent.withOpacity(0.2),
        child: Opacity(
          opacity: locked ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16), // Reduced padding
            child: Row(
              children: [
                Container(
                  width: 40, // Reduced size
                  height: 40, // Reduced size
                  decoration: BoxDecoration(
                    color: isFirstItem && !locked
                        ? Colors.indigoAccent
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8), // Reduced radius
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 14, // Updated to 14
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Mock Test ${index + 1}",
                              style: AppTheme.subheadingStyle.copyWith(
                                fontSize: 14, // Updated to 14
                                color: locked ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isFirstItem && !locked) ...[
                            const SizedBox(width: 6), // Reduced spacing
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2, // Reduced padding
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius:
                                    BorderRadius.circular(4), // Reduced radius
                              ),
                              child: const Text(
                                'FREE',
                                style: TextStyle(
                                  fontSize: 10, // Updated to 10
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      Text(
                        "${testMcqs.length} Questions • ${testMcqs.length} Marks",
                        style: AppTheme.captionStyle.copyWith(
                          fontSize: 12, // Updated to 12
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrailingWidget(locked),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(bool locked) {
    if (locked) {
      return Container(
        padding: const EdgeInsets.all(6), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(6), // Reduced radius
        ),
        child: const Icon(
          Icons.lock,
          color: Colors.white,
          size: 18, // Reduced size
        ),
      );
    } else {
      return const Icon(
        Icons.arrow_forward_ios,
        color: Colors.indigoAccent,
        size: 18, // Reduced size
      );
    }
  }
}
