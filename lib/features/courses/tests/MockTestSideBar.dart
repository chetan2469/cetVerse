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
      return Colors.grey.shade400;
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
              // Header Card
              Container(
                margin: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.indigoAccent,
                  shadowColor: Colors.grey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.quiz,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Question Status',
                          style: AppTheme.subheadingStyle.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Status Overview Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  shadowColor: Colors.grey.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: AppTheme.subheadingStyle.copyWith(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatusRow(
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          label: 'Attempted',
                          count: attemptedCount,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                          icon: Icons.bookmark_border,
                          color: Colors.orange,
                          label: 'For Review',
                          count: reviewCount,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow(
                          icon: Icons.radio_button_unchecked,
                          color: Colors.grey.shade400,
                          label: 'Unattempted',
                          count: unattemptedCount,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.indigoAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.subject,
                                color: Colors.indigoAccent,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Subject Progress',
                              style: AppTheme.subheadingStyle.copyWith(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                subject,
                                style: AppTheme.captionStyle.copyWith(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.indigoAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${subjectAttempted[subject] ?? 0}/${subjectTotal[subject] ?? 0}',
                                  style: AppTheme.subheadingStyle.copyWith(
                                    fontSize: 12,
                                    color: Colors.indigoAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Questions Grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    shadowColor: Colors.grey.withOpacity(0.3),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.indigoAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.grid_view,
                                  color: Colors.indigoAccent,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Question Navigator',
                                style: AppTheme.subheadingStyle.copyWith(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: mcqs.length,
                              itemBuilder: (context, index) {
                                final color = _getStatusColor(index);
                                final isSelected = userAnswers[index] != -1;
                                final isReviewed =
                                    reviewedQuestions.contains(index);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: hasSubmitted
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                            onJumpToQuestion(index);
                                          },
                                    borderRadius: BorderRadius.circular(8),
                                    splashColor:
                                        Colors.indigoAccent.withOpacity(0.2),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: color,
                                          width:
                                              isSelected || isReviewed ? 2 : 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: AppTheme.subheadingStyle
                                                  .copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                          if (isReviewed)
                                            Positioned(
                                              top: 2,
                                              right: 2,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: Colors.orange,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTheme.captionStyle.copyWith(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: AppTheme.subheadingStyle.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
