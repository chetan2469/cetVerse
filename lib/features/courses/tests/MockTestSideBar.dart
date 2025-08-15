import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class MockTestSideBar extends StatelessWidget {
  final List<int> userAnswers;
  final Set<int> reviewedQuestions;
  final List<Map<String, dynamic>> mcqs;
  final bool hasSubmitted;
  final Function(int) onJumpToQuestion;
  final String subject;

  const MockTestSideBar({
    super.key,
    required this.userAnswers,
    required this.reviewedQuestions,
    required this.mcqs,
    required this.hasSubmitted,
    required this.onJumpToQuestion,
    required this.subject,
  });

  Color _getStatusColor(int questionIndex) {
    if (reviewedQuestions.contains(questionIndex)) {
      return Colors.orange;
    } else if (userAnswers[questionIndex] != -1) {
      return Colors.green;
    } else {
      return Color.fromARGB(255, 145, 186, 218);
    }
  }

  Map<String, int> _getSubjectAttempted() {
    Map<String, int> subjectAttempted = {};
    for (var i = 0; i < mcqs.length; i++) {
      if (userAnswers[i] != -1) {
        subjectAttempted[subject] = (subjectAttempted[subject] ?? 0) + 1;
      }
    }
    return subjectAttempted;
  }

  Map<String, int> _getSubjectTotal() {
    return {subject: mcqs.length};
  }

  @override
  Widget build(BuildContext context) {
    final attemptedCount = userAnswers.where((answer) => answer != -1).length;
    final unattemptedCount = userAnswers.where((answer) => answer == -1).length;
    final reviewCount = reviewedQuestions.length;

    final subjectAttempted = _getSubjectAttempted();
    final subjectTotal = _getSubjectTotal();

    return Drawer(
      child: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: Colors.blue[700],
                padding: const EdgeInsets.all(16.0),
                child: const Center(
                  child: Text(
                    'Question Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow(Icons.square, Colors.green, 'Attempted',
                        attemptedCount),
                    const SizedBox(height: 8),
                    _buildStatusRow(Icons.square, Colors.orange,
                        'Marked for Review', reviewCount),
                    const SizedBox(height: 8),
                    _buildStatusRow(
                        Icons.square,
                        Color.fromARGB(255, 145, 186, 218),
                        'Unattempted',
                        unattemptedCount),
                    const SizedBox(height: 16),
                    const Text(
                      'Subject Breakdown:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '$subject: ${subjectAttempted[subject] ?? 0}/${subjectTotal[subject] ?? 0}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: mcqs.length,
                  itemBuilder: (context, index) {
                    final color = _getStatusColor(index);
                    return InkWell(
                      onTap: () {
                        if (!hasSubmitted) {
                          Navigator.pop(context); // Close drawer
                          onJumpToQuestion(index);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, Color color, String label, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text('$label: $count', style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}
