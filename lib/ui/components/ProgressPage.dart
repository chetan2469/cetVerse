import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:intl/intl.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  int totalTestsTaken = 0;
  double averageScore = 0.0; // Percentage
  double overallProgress = 0.0; // Percentage
  String level = "Beginner"; // Based on overallProgress
  Map<String, Map<String, dynamic>> subjectAnalytics = {
    'Physics': {
      'solved': 0,
      'accuracy': 0.0,
      'avgTime': 0.0,
      'correct': 0,
      'wrong': 0,
      'unattempted': 0
    }, // min/ques
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
  List<double> testTrends = []; // Last 10 scores
  List<Map<String, dynamic>> recentTests = []; // Last 3 tests
  List<Map<String, dynamic>> last10Tests = []; // Last 10 tests for line chart
  Map<String, dynamic> mockVsPyqStats = {
    'mock': {'count': 0, 'avgScore': 0.0, 'totalScore': 0.0},
    'pyq': {'count': 0, 'avgScore': 0.0, 'totalScore': 0.0},
  };
  bool _isLoading = true;

  late AnimationController _controller;
  late Map<String, Animation<double>> _performanceAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fetchProgressData();
  }

  Future<void> _fetchProgressData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;

    if (userPhoneNumber == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final testHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('testHistory')
          .orderBy('timestamp', descending: true)
          .get();

      final pyqHistorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('pyqHistory')
          .orderBy('timestamp', descending: true)
          .get();

      // Total tests taken
      totalTestsTaken =
          testHistorySnapshot.docs.length + pyqHistorySnapshot.docs.length;

      // Collect all scores and accuracies
      List<double> allScores = [];
      List<double> allAccuracies = [];
      List<Map<String, dynamic>> allTests = [];

      // Process testHistory (subject-wise)
      Map<String, List<Map<String, dynamic>>> subjectData = {
        'Physics': [],
        'Chemistry': [],
        'Maths': [],
        'Biology': [],
      };

      // Mock test stats
      double totalMockScore = 0;
      int mockCount = 0;

      for (var doc in testHistorySnapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] as String?;
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        final accuracy =
            double.tryParse(data['accuracy'] as String? ?? '0.0') ?? 0.0;
        final correct = data['correct'] as int? ?? 0;
        final wrong = data['wrong'] as int? ?? 0;
        final unattempted = data['unattempted'] as int? ?? 0;
        final totalQuestions = correct + wrong + unattempted;
        final timestamp = data['timestamp'] as Timestamp?;

        allScores.add(score);
        allAccuracies.add(accuracy);
        totalMockScore += score;
        mockCount++;

        if (timestamp != null) {
          allTests.add({
            'testId':
                '${data['subject']} ${data['chapter']} Test ${data['testnumber']}',
            'score': score,
            'date': DateFormat('MMM dd, yyyy').format(timestamp.toDate()),
            'timestamp': timestamp.toDate(),
            'type': 'mock',
          });
        }

        if (subject != null && subjectData.containsKey(subject)) {
          subjectData[subject]!.add(data);
        }
      }

      // PYQ test stats
      double totalPyqScore = 0;
      int pyqCount = 0;

      // Process pyqHistory (overall tests)
      for (var doc in pyqHistorySnapshot.docs) {
        final data = doc.data();
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        final accuracy =
            double.tryParse(data['accuracy'] as String? ?? '0.0') ?? 0.0;
        final timestamp = data['timestamp'] as Timestamp?;

        allScores.add(score);
        allAccuracies.add(accuracy);
        totalPyqScore += score;
        pyqCount++;

        if (timestamp != null) {
          allTests.add({
            'testId': 'PYQ ${data['year']} ${data['pyqType']}',
            'score': score,
            'date': DateFormat('MMM dd, yyyy').format(timestamp.toDate()),
            'timestamp': timestamp.toDate(),
            'type': 'pyq',
          });
        }
      }

      // Update mock vs pyq stats
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

      // Calculate averages
      if (allScores.isNotEmpty) {
        averageScore = allScores.reduce((a, b) => a + b) / allScores.length;
      }
      if (allAccuracies.isNotEmpty) {
        overallProgress =
            allAccuracies.reduce((a, b) => a + b) / allAccuracies.length;
      }

      _updateLevel();

      // Calculate subject analytics from testHistory
      subjectData.forEach((subject, tests) {
        if (tests.isNotEmpty) {
          int totalSolved = 0;
          double totalAccuracy = 0.0;
          double totalTime = 0.0;
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

            // Assuming timeleft is in minutes, and total questions
            final timeleft = double.tryParse(
                    (test['timeleft'] as String?)?.split(':')[0] ?? '0') ??
                0.0;
            final totalQuestions = solved + (test['unattempted'] as int? ?? 0);
            final avgTime =
                totalQuestions > 0 ? timeleft / totalQuestions : 0.0;

            totalSolved += solved;
            totalAccuracy += accuracy;
            totalTime += avgTime;
            totalCorrect += correct;
            totalWrong += wrong;
            totalUnattempted += unattempted;
            testCount++;
          }

          subjectAnalytics[subject] = {
            'solved': totalSolved,
            'accuracy': totalAccuracy / testCount,
            'avgTime': totalTime / testCount,
            'correct': totalCorrect,
            'wrong': totalWrong,
            'unattempted': totalUnattempted,
          };
        }
      });

      // Test trends: last 10 scores
      allTests.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      testTrends =
          allTests.take(10).map((test) => test['score'] as double).toList();

      // Last 10 tests for line chart
      last10Tests = allTests.take(10).toList();

      // Recent tests: last 3
      recentTests = allTests.take(3).toList();

      setState(() {
        _isLoading = false;
        _performanceAnimations = {
          'Physics': Tween<double>(
                  begin: 0,
                  end: (subjectAnalytics['Physics']?['accuracy'] ?? 0.0) / 100)
              .animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
          'Chemistry': Tween<double>(
                  begin: 0,
                  end:
                      (subjectAnalytics['Chemistry']?['accuracy'] ?? 0.0) / 100)
              .animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
          'Maths': Tween<double>(
                  begin: 0,
                  end: (subjectAnalytics['Maths']?['accuracy'] ?? 0.0) / 100)
              .animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
          'Biology': Tween<double>(
                  begin: 0,
                  end: (subjectAnalytics['Biology']?['accuracy'] ?? 0.0) / 100)
              .animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        };
        _controller.forward();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
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

  // Widget for Time-Series Line Graph
  Widget _buildTimeSeriesChart() {
    if (last10Tests.isEmpty) {
      return const Center(child: Text('No test data available'));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < last10Tests.length; i++) {
      spots.add(FlSpot(i.toDouble(), last10Tests[i]['score']));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last 10 Test Scores Trend",
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < last10Tests.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'T${index + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.indigo,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.indigo.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for Subject Radar Chart
  Widget _buildSubjectRadarChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Subject Performance Radar",
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: Colors.indigo.withOpacity(0.2),
                      borderColor: Colors.indigo,
                      borderWidth: 2,
                      dataEntries: [
                        RadarEntry(
                            value: (subjectAnalytics['Physics']?['accuracy'] ??
                                    0.0) /
                                100),
                        RadarEntry(
                            value: (subjectAnalytics['Chemistry']
                                        ?['accuracy'] ??
                                    0.0) /
                                100),
                        RadarEntry(
                            value: (subjectAnalytics['Maths']?['accuracy'] ??
                                    0.0) /
                                100),
                        RadarEntry(
                            value: (subjectAnalytics['Biology']?['accuracy'] ??
                                    0.0) /
                                100),
                      ],
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData:
                      const BorderSide(color: Colors.grey, width: 1),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0:
                        return RadarChartTitle(text: 'Physics');
                      case 1:
                        return RadarChartTitle(text: 'Chemistry');
                      case 2:
                        return RadarChartTitle(text: 'Maths');
                      case 3:
                        return RadarChartTitle(text: 'Biology');
                      default:
                        return const RadarChartTitle(text: '');
                    }
                  },
                  tickCount: 5,
                  ticksTextStyle: const TextStyle(fontSize: 10),
                  tickBorderData:
                      const BorderSide(color: Colors.grey, width: 1),
                  gridBorderData:
                      const BorderSide(color: Colors.grey, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for Stacked Bar Charts
  Widget _buildStackedBarChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question Distribution by Subject",
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxQuestions(),
                  barGroups: _buildBarGroups(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Physics',
                                  style: TextStyle(fontSize: 12));
                            case 1:
                              return const Text('Chemistry',
                                  style: TextStyle(fontSize: 12));
                            case 2:
                              return const Text('Maths',
                                  style: TextStyle(fontSize: 12));
                            case 3:
                              return const Text('Biology',
                                  style: TextStyle(fontSize: 12));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.green, 'Correct'),
                _buildLegendItem(Colors.red, 'Wrong'),
                _buildLegendItem(Colors.grey, 'Unattempted'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxQuestions() {
    double max = 0;
    subjectAnalytics.forEach((subject, data) {
      double total =
          (data['correct'] + data['wrong'] + data['unattempted']).toDouble();
      if (total > max) max = total;
    });
    return max * 1.1; // Add 10% padding
  }

  List<BarChartGroupData> _buildBarGroups() {
    List<BarChartGroupData> groups = [];
    List<String> subjects = ['Physics', 'Chemistry', 'Maths', 'Biology'];

    for (int i = 0; i < subjects.length; i++) {
      String subject = subjects[i];
      Map<String, dynamic> data = subjectAnalytics[subject]!;

      double correct = data['correct'].toDouble();
      double wrong = data['wrong'].toDouble();
      double unattempted = data['unattempted'].toDouble();

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: correct + wrong + unattempted,
              color: Colors.transparent,
              width: 40,
              rodStackItems: [
                BarChartRodStackItem(0, correct, Colors.green),
                BarChartRodStackItem(correct, correct + wrong, Colors.red),
                BarChartRodStackItem(correct + wrong,
                    correct + wrong + unattempted, Colors.grey),
              ],
            ),
          ],
        ),
      );
    }

    return groups;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Widget for Mock vs PYQ Comparison
  Widget _buildMockVsPyqChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mock vs PYQ Performance",
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: mockVsPyqStats['mock']['avgScore'],
                          color: Colors.blue,
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: mockVsPyqStats['pyq']['avgScore'],
                          color: Colors.orange,
                          width: 40,
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Mock Tests',
                                  style: TextStyle(fontSize: 12));
                            case 1:
                              return const Text('PYQ Tests',
                                  style: TextStyle(fontSize: 12));
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Mock Tests', style: AppTheme.captionStyle),
                    Text('Count: ${mockVsPyqStats['mock']['count']}',
                        style: AppTheme.captionStyle),
                    Text(
                        'Avg: ${mockVsPyqStats['mock']['avgScore'].toStringAsFixed(1)}%',
                        style: AppTheme.captionStyle),
                  ],
                ),
                Column(
                  children: [
                    Text('PYQ Tests', style: AppTheme.captionStyle),
                    Text('Count: ${mockVsPyqStats['pyq']['count']}',
                        style: AppTheme.captionStyle),
                    Text(
                        'Avg: ${mockVsPyqStats['pyq']['avgScore'].toStringAsFixed(1)}%',
                        style: AppTheme.captionStyle),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Progress Overview",
          style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.indigo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Overall Progress Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade50, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Overall Progress",
                      style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: overallProgress / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.indigo),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${overallProgress.toStringAsFixed(1)}%",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tests Taken: $totalTestsTaken | Avg. Score: ${averageScore.toStringAsFixed(1)}%",
                      style: AppTheme.captionStyle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Level: $level",
                          style: AppTheme.captionStyle
                              .copyWith(fontSize: 14, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time-Series Line Graph
            _buildTimeSeriesChart(),
            const SizedBox(height: 16),

            // Subject Radar Chart
            _buildSubjectRadarChart(),
            const SizedBox(height: 16),

            // Stacked Bar Chart
            _buildStackedBarChart(),
            const SizedBox(height: 16),

            // Mock vs PYQ Chart
            _buildMockVsPyqChart(),
            const SizedBox(height: 16),

            // Subject-wise Progress with Animated Bars
            Text(
              "Subject-wise Progress",
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ...subjectAnalytics.entries.map((entry) {
              final subject = entry.key;
              final percentage = entry.value['accuracy'] as double? ?? 0.0;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$subject Progress",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            "${percentage.toInt()}%",
                            style: TextStyle(
                              color: subject == 'Physics'
                                  ? Colors.blue
                                  : subject == 'Chemistry'
                                      ? Colors.orange
                                      : subject == 'Maths'
                                          ? Colors.green
                                          : Colors.purple,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _performanceAnimations[subject]!,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _performanceAnimations[subject]!.value,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation(
                              subject == 'Physics'
                                  ? Colors.blue
                                  : subject == 'Chemistry'
                                      ? Colors.orange
                                      : subject == 'Maths'
                                          ? Colors.green
                                          : Colors.purple,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(20),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),

            // Subject-wise Analytics Cards
            Text(
              "Subject-wise Analytics",
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ...subjectAnalytics.entries.map((entry) {
              final subject = entry.key;
              final data = entry.value;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subject,
                        style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Solved: ${data['solved']}",
                            style: AppTheme.captionStyle.copyWith(fontSize: 14),
                          ),
                          Text(
                            "Accuracy: ${data['accuracy'].toStringAsFixed(1)}%",
                            style: AppTheme.captionStyle.copyWith(fontSize: 14),
                          ),
                          Text(
                            "Avg. Time: ${data['avgTime'].toStringAsFixed(1)} min",
                            style: AppTheme.captionStyle.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),

            // Recent Tests Table
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recent Tests",
                      style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Test ID')),
                          DataColumn(label: Text('Score (%)')),
                          DataColumn(label: Text('Date')),
                        ],
                        rows: recentTests.map((test) {
                          return DataRow(
                            cells: [
                              DataCell(Text(test['testId'])),
                              DataCell(Text(test['score'].toStringAsFixed(1))),
                              DataCell(Text(test['date'])),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
