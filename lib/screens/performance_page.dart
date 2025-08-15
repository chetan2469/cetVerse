import 'package:cet_verse/ui/components/ProgressPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  _PerformancePageState createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Map<String, double> subjectPerformance = {
    'Physics': 0.0,
    'Chemistry': 0.0,
    'Maths': 0.0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fetchPerformanceData();
  }

  Future<void> _fetchPerformanceData() async {
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
          .get();

      Map<String, Map<String, int>> subjectData = {
        'Physics': {'correct': 0, 'total': 0},
        'Chemistry': {'correct': 0, 'total': 0},
        'Maths': {'correct': 0, 'total': 0},
      };

      for (var doc in testHistorySnapshot.docs) {
        final data = doc.data();
        final subject = data['subject'] as String?;
        if (subject != null && subjectData.containsKey(subject)) {
          final correct = data['correct'] as int? ?? 0;
          final wrong = data['wrong'] as int? ?? 0;
          final unattempted = data['unattempted'] as int? ?? 0;
          final total = correct + wrong + unattempted;

          subjectData[subject]!['correct'] =
              (subjectData[subject]!['correct'] ?? 0) + correct;
          subjectData[subject]!['total'] =
              (subjectData[subject]!['total'] ?? 0) + total;
        }
      }

      setState(() {
        subjectPerformance = {
          'Physics': subjectData['Physics']!['total']! > 0
              ? (subjectData['Physics']!['correct']! /
                      subjectData['Physics']!['total']!) *
                  100
              : 0.0,
          'Chemistry': subjectData['Chemistry']!['total']! > 0
              ? (subjectData['Chemistry']!['correct']! /
                      subjectData['Chemistry']!['total']!) *
                  100
              : 0.0,
          'Maths': subjectData['Maths']!['total']! > 0
              ? (subjectData['Maths']!['correct']! /
                      subjectData['Maths']!['total']!) *
                  100
              : 0.0,
        };
        _isLoading = false;
        _controller.forward();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error appropriately
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromARGB(44, 158, 158, 158), width: 5),
        ),
        child: Column(
          children: [
            _buildProgressBar(
              label: "Physics Progress",
              percentage: subjectPerformance['Physics']!,
              bgColor: const Color(0xFFE6F2FC),
              progressColor: Colors.blue,
              percentageColor: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildProgressBar(
              label: "Chemistry Progress",
              percentage: subjectPerformance['Chemistry']!,
              bgColor: const Color(0xFFFFF7E6),
              progressColor: Colors.orange,
              percentageColor: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildProgressBar(
              label: "Mathematics Progress",
              percentage: subjectPerformance['Maths']!,
              bgColor: const Color(0xFFF2FCF2),
              progressColor: Colors.green,
              percentageColor: Colors.green,
            ),
            const SizedBox(height: 20),
            _buildAnalysisButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double percentage,
    required Color bgColor,
    required Color progressColor,
    required Color percentageColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                "${percentage.toInt()}%",
                style: TextStyle(
                  color: percentageColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _controller.value * (percentage / 100),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(progressColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisButton() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFFFFC107)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: MaterialButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProgressPage()),
          );
        },
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: const Text(
          "View Your Analysis",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
