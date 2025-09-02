import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/tests/test_confirmation_page.dart';
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

class _ChapterWiseTestState extends State<ChapterWiseTest>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMcqs = [];
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      await _fetchMcqs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Error initializing data: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error initializing data: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
        _slideController.forward();
      }
    }
  }

  Future<void> _fetchMcqs() async {
    try {
      // Add delay to show shimmer effect
      await Future.delayed(const Duration(milliseconds: 1000));

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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = "Error loading MCQs: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading MCQs: $e"),
          backgroundColor: Colors.red.shade600,
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
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Upgrade',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to pricing page
            },
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            TestConfirmationPage(
          level: widget.level,
          subject: widget.subject,
          chapter: widget.chapter,
          testNumber: testIndexZeroBased + 1,
          mcqs: testMcqs,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "${widget.chapter} Tests",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Fixed header - this won't scroll
            _buildHeader(auth, displayLevel),

            // ✅ FIX: Wrap the scrollable content with Expanded
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: Colors.blue.shade600,
                backgroundColor: Colors.white,
                displacement: 40,
                child: _buildContent(auth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, String displayLevel) {
    final subtitleText = auth.fullMockTestSeries
        ? 'Unlimited tests (Pro)'
        : 'First ${auth.mockTestsPerSubject} tests available';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chapter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.subject} • $displayLevel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: auth.fullMockTestSeries
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: auth.fullMockTestSeries
                    ? Colors.green.shade300
                    : Colors.orange.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  auth.fullMockTestSeries ? Icons.verified : Icons.lock_outline,
                  size: 16,
                  color: auth.fullMockTestSeries
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  subtitleText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: auth.fullMockTestSeries
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuthProvider auth) {
    if (_isLoading) {
      return _buildShimmerContent();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final tests = _groupMcqsIntoTests();

    if (tests.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTestsList(tests, auth);
  }

  Widget _buildTestsList(
      List<List<Map<String, dynamic>>> tests, AuthProvider auth) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        // ✅ FIX: Use ListView.builder instead of Column + ListView
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16), // Add padding here instead
          itemCount: tests.length,
          itemBuilder: (context, index) {
            final testMcqs = tests[index];
            final locked = !_isTestAccessible(context, index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 600 + (index * 100)),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  final clampedValue = value.clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(
                      opacity: clampedValue,
                      child: child,
                    ),
                  );
                },
                child: _buildTestCard(index, testMcqs, locked),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
            2,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildShimmerCard(delay: 1000 + (index * 150)),
                )),
      ),
    );
  }

  Widget _buildShimmerCard({required int delay}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: Duration(milliseconds: delay),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Tests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Tests Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No MCQs found for this chapter.\nTests will be available once content is added.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(
      int index, List<Map<String, dynamic>> testMcqs, bool locked) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: locked
            ? Border.all(color: Colors.orange.shade300, width: 1)
            : Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleTestTap(context, index, testMcqs),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        locked ? Colors.orange.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: locked
                      ? Image.asset(
                          "assets/crown.png",
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.lock,
                            size: 24,
                            color: Colors.orange.shade600,
                          ),
                        )
                      : Icon(
                          Icons.auto_fix_high,
                          size: 24,
                          color: Colors.green.shade600,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mock Test ${index + 1}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: locked ? Colors.grey.shade700 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${testMcqs.length} Questions • ${testMcqs.length} Marks",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Upgrade to access',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        locked ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: locked
                          ? Colors.orange.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locked ? 'Locked' : 'Start',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: locked
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        locked ? Icons.lock_outline : Icons.arrow_forward,
                        size: 14,
                        color: locked
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ],
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
