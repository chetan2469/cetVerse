import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with TickerProviderStateMixin {
  int totalTestsTaken = 0;
  double averageScore = 0.0;
  double overallProgress = 0.0;
  String level = "Beginner";

  Map<String, Map<String, dynamic>> subjectAnalytics = {
    'Physics': {
      'solved': 0,
      'accuracy': 0.0,
      'avgTime': 0.0,
      'correct': 0,
      'wrong': 0,
      'unattempted': 0
    },
    'Chemistry': {
      'solved': 0,
      'accuracy': 0.0,
      'avgTime': 0.0,
      'correct': 0,
      'wrong': 0,
      'unattempted': 0
    },
    'Maths': {
      'solved': 0,
      'accuracy': 0.0,
      'avgTime': 0.0,
      'correct': 0,
      'wrong': 0,
      'unattempted': 0
    },
    'Biology': {
      'solved': 0,
      'accuracy': 0.0,
      'avgTime': 0.0,
      'correct': 0,
      'wrong': 0,
      'unattempted': 0
    },
  };

  List<Map<String, dynamic>> recentTests = [];
  List<Map<String, dynamic>> last10Tests = [];
  Map<String, dynamic> mockVsPyqStats = {
    'mock': {'count': 0, 'avgScore': 0.0, 'totalScore': 0.0},
    'pyq': {'count': 0, 'avgScore': 0.0, 'totalScore': 0.0},
  };

  // Individual loading states for each component
  bool _isLoadingOverall = true;
  bool _isLoadingSubjects = true;
  bool _isLoadingCharts = true;
  bool _isLoadingRecent = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchProgressData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchProgressData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;

    if (userPhoneNumber == null) {
      setState(() {
        _isLoadingOverall = false;
        _isLoadingSubjects = false;
        _isLoadingCharts = false;
        _isLoadingRecent = false;
        _errorMessage = 'Please log in to view progress';
      });
      return;
    }

    try {
      // Load each component with different delays for staggered effect
      _loadOverallProgress(userPhoneNumber);
      _loadSubjectProgress(userPhoneNumber);
      _loadChartsData(userPhoneNumber);
      _loadRecentTests(userPhoneNumber);
    } catch (e) {
      setState(() {
        _isLoadingOverall = false;
        _isLoadingSubjects = false;
        _isLoadingCharts = false;
        _isLoadingRecent = false;
        _errorMessage = 'Error loading progress data: $e';
      });
    }
  }

  Future<void> _loadOverallProgress(String userPhoneNumber) async {
    await Future.delayed(
        const Duration(milliseconds: 1000)); // Simulate network delay

    try {
      final testHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('testHistory')
          .get();

      final pyqHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('pyqHistory')
          .get();

      // Process overall statistics
      totalTestsTaken =
          testHistorySnapshot.docs.length + pyqHistorySnapshot.docs.length;

      List<double> allScores = [];
      List<double> allAccuracies = [];

      for (var doc in testHistorySnapshot.docs) {
        final data = doc.data();
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        final accuracy =
            double.tryParse(data['accuracy'] as String? ?? '0.0') ?? 0.0;
        allScores.add(score);
        allAccuracies.add(accuracy);
      }

      for (var doc in pyqHistorySnapshot.docs) {
        final data = doc.data();
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        final accuracy =
            double.tryParse(data['accuracy'] as String? ?? '0.0') ?? 0.0;
        allScores.add(score);
        allAccuracies.add(accuracy);
      }

      if (allScores.isNotEmpty) {
        averageScore = allScores.reduce((a, b) => a + b) / allScores.length;
      }
      if (allAccuracies.isNotEmpty) {
        overallProgress =
            allAccuracies.reduce((a, b) => a + b) / allAccuracies.length;
      }

      _updateLevel();

      setState(() => _isLoadingOverall = false);
    } catch (e) {
      setState(() => _isLoadingOverall = false);
    }
  }

  Future<void> _loadSubjectProgress(String userPhoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Different delay

    try {
      final testHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('testHistory')
          .get();

      Map<String, List<Map<String, dynamic>>> subjectData = {
        'Physics': [],
        'Chemistry': [],
        'Maths': [],
        'Biology': [],
      };

      for (var doc in testHistorySnapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] as String?;
        if (subject != null && subjectData.containsKey(subject)) {
          subjectData[subject]!.add(data);
        }
      }

      _calculateSubjectAnalytics(subjectData);
      setState(() => _isLoadingSubjects = false);
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
    }
  }

  Future<void> _loadChartsData(String userPhoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 2000)); // Different delay

    try {
      final testHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('testHistory')
          .get();

      final pyqHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('pyqHistory')
          .get();

      double totalMockScore = 0;
      int mockCount = testHistorySnapshot.docs.length;

      for (var doc in testHistorySnapshot.docs) {
        final data = doc.data();
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        totalMockScore += score;
      }

      double totalPyqScore = 0;
      int pyqCount = pyqHistorySnapshot.docs.length;

      for (var doc in pyqHistorySnapshot.docs) {
        final data = doc.data();
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        totalPyqScore += score;
      }

      mockVsPyqStats = {
        'mock': {
          'count': mockCount,
          'avgScore': mockCount > 0 ? totalMockScore / mockCount : 0.0,
          'totalScore': totalMockScore,
        },
        'pyq': {
          'count': pyqCount,
          'avgScore': pyqCount > 0 ? totalPyqScore / pyqCount : 0.0,
          'totalScore': totalPyqScore,
        },
      };

      setState(() => _isLoadingCharts = false);
    } catch (e) {
      setState(() => _isLoadingCharts = false);
    }
  }

  Future<void> _loadRecentTests(String userPhoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 2500)); // Different delay

    try {
      final testHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('testHistory')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      final pyqHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('pyqHistory')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      List<Map<String, dynamic>> allTests = [];

      for (var doc in testHistorySnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          allTests.add({
            'testId':
                '${data['subject']} ${data['chapter']} Test ${data['testnumber']}',
            'score': (data['score'] as num?)?.toDouble() ?? 0.0,
            'date': DateFormat('MMM dd, yyyy').format(timestamp.toDate()),
            'timestamp': timestamp.toDate(),
            'type': 'mock',
          });
        }
      }

      for (var doc in pyqHistorySnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          allTests.add({
            'testId': 'PYQ ${data['year']} ${data['pyqType']}',
            'score': (data['score'] as num?)?.toDouble() ?? 0.0,
            'date': DateFormat('MMM dd, yyyy').format(timestamp.toDate()),
            'timestamp': timestamp.toDate(),
            'type': 'pyq',
          });
        }
      }

      allTests.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      recentTests = allTests.take(3).toList();

      setState(() => _isLoadingRecent = false);
    } catch (e) {
      setState(() => _isLoadingRecent = false);
    }
  }

  void _calculateSubjectAnalytics(
      Map<String, List<Map<String, dynamic>>> subjectData) {
    subjectData.forEach((subject, tests) {
      if (tests.isNotEmpty) {
        int totalSolved = 0;
        double totalAccuracy = 0.0;
        int testCount = 0;
        int totalCorrect = 0;
        int totalWrong = 0;
        int totalUnattempted = 0;

        for (var test in tests) {
          final solved =
              (test['correct'] as int? ?? 0) + (test['wrong'] as int? ?? 0);
          final accuracy =
              double.tryParse(test['accuracy'] as String? ?? '0.0') ?? 0.0;
          final correct = test['correct'] as int? ?? 0;
          final wrong = test['wrong'] as int? ?? 0;
          final unattempted = test['unattempted'] as int? ?? 0;

          totalSolved += solved;
          totalAccuracy += accuracy;
          totalCorrect += correct;
          totalWrong += wrong;
          totalUnattempted += unattempted;
          testCount++;
        }

        subjectAnalytics[subject] = {
          'solved': totalSolved,
          'accuracy': totalAccuracy / testCount,
          'avgTime': 0.0,
          'correct': totalCorrect,
          'wrong': totalWrong,
          'unattempted': totalUnattempted,
        };
      }
    });
  }

  void _updateLevel() {
    if (overallProgress >= 75) {
      level = "Advanced";
    } else if (overallProgress >= 50) {
      level = "Intermediate";
    } else {
      level = "Beginner";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Progress Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overall Progress Card with individual shimmer
            _isLoadingOverall
                ? _buildOverallProgressShimmer()
                : _buildOverallProgressCard(),
            const SizedBox(height: 16),

            // Subject Progress Cards with individual shimmer
            _isLoadingSubjects
                ? _buildSubjectProgressShimmer()
                : _buildSubjectProgressCards(),
            const SizedBox(height: 16),

            // Charts Section with individual shimmer
            _isLoadingCharts ? _buildChartsShimmer() : _buildChartsSection(),
            const SizedBox(height: 16),

            // Recent Tests with individual shimmer
            _isLoadingRecent
                ? _buildRecentTestsShimmer()
                : _buildRecentTestsCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Individual Shimmer Widgets for each component

  Widget _buildOverallProgressShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1000),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.purple.shade50],
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectProgressShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 200,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1400),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTestsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1600),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 120,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(
                3,
                (index) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 100,
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
                            width: 60,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  // Actual content widgets (same as before)
  Widget _buildOverallProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.purple.shade50],
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
              Icon(
                Icons.trending_up,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${overallProgress.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: overallProgress / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.orange.shade600,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                  'Tests Taken', totalTestsTaken.toString(), Icons.quiz),
              const SizedBox(width: 20),
              _buildStatItem('Avg. Score',
                  '${averageScore.toStringAsFixed(1)}%', Icons.grade),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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

  Widget _buildSubjectProgressCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject-wise Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: subjectAnalytics.length,
          itemBuilder: (context, index) {
            final subject = subjectAnalytics.keys.elementAt(index);
            final data = subjectAnalytics[subject]!;
            final colors = [
              Colors.blue,
              Colors.orange,
              Colors.green,
              Colors.purple
            ];
            final color = colors[index];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.science,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(data['accuracy'] as double).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (data['accuracy'] as double) / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data['solved']} questions solved',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mock vs PYQ Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildComparisonCard(
                  'Mock Tests',
                  mockVsPyqStats['mock']['count'].toString(),
                  '${mockVsPyqStats['mock']['avgScore'].toStringAsFixed(1)}%',
                  Colors.blue,
                  Icons.quiz,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildComparisonCard(
                  'PYQ Tests',
                  mockVsPyqStats['pyq']['count'].toString(),
                  '${mockVsPyqStats['pyq']['avgScore'].toStringAsFixed(1)}%',
                  Colors.orange,
                  Icons.history_edu,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
      String title, String count, String average, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'Avg: $average',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTestsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Tests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Navigate to full history
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentTests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tests taken yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentTests.map((test) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: test['type'] == 'mock'
                              ? Colors.blue.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          test['type'] == 'mock'
                              ? Icons.quiz
                              : Icons.history_edu,
                          size: 16,
                          color: test['type'] == 'mock'
                              ? Colors.blue.shade600
                              : Colors.orange.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              test['testId'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              test['date'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${test['score'].toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}
