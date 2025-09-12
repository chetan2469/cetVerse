import 'package:cet_verse/courses/TimerController.dart';
import 'package:cet_verse/features/courses/pyq/tests/new_test_view/logic.dart';
import 'package:cet_verse/features/courses/pyq/tests/new_test_view/pyqquestioncard.dart';
import 'package:cet_verse/features/courses/pyq/tests/new_test_view/test_provider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Future<bool?> showBackConfirmation2(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blueGrey, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Go Back?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to go back? will be lost.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Go Back',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}

Widget buildMainContent(
    GlobalKey<ScaffoldState> scaffoldKey, TestProvider provider, bool isPcm) {
  final attemptedCount = provider.userAnswers.where((a) => a != -1).length;
  return Column(
    children: [
      // Stats Header
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Text(
                  'Attempted: $attemptedCount/${provider.mcqs.length}',
                  style: const TextStyle(
                      color: Colors.blueGrey, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.blueGrey),
                onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
              ),
            ),
          ],
        ),
      ),
      // Subject Filter
      // Subject Navigation Buttons
      Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildSubjectJumpButton(
                provider, 'All', '1-${provider.mcqs.length}'),
            buildSubjectJumpButton(provider, 'Physics', '1-50'),
            buildSubjectJumpButton(provider, 'Chemistry', '51-100'),
            buildSubjectJumpButton(provider, isPcm ? 'Maths' : 'Biology',
                isPcm ? '101-150' : '101-200'),
          ],
        ),
      ),
      // Question Content
      Expanded(
        child: provider.filteredMcqs.isNotEmpty && provider.currentIndex >= 0
            ? GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (provider.hasSubmitted) return;

                  const double swipeThreshold = 100;

                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -swipeThreshold) {
                      provider.nextQuestion();
                    } else if (details.primaryVelocity! > swipeThreshold) {
                      provider.previousQuestion();
                    }
                  }
                },
                child: PyqQuestionCard2(
                  key: ValueKey(
                      'question_${provider.filteredMcqs[provider.currentIndex]['docId']}'),
                  index: provider.currentIndex,
                ),
              )
            : const Center(
                child: Text(
                  'No questions for this filter',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),
              ),
      )
    ],
  );
}

Widget buildPaperFilterButton(String subject, TestProvider provider) {
  final isSelected = provider.selectedSubject == subject;
  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: provider.hasSubmitted
            ? null
            : () => provider.filterQuestions(subject),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blueGrey : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.blueGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          elevation: isSelected ? 2 : 0,
        ),
        child: Text(
          subject,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

Widget buildPaperNavButton({
  required IconData icon,
  required String label,
  required VoidCallback? onPressed,
  required Color color,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 12),
    label: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: onPressed != null ? color : Colors.grey.shade300,
      foregroundColor: onPressed != null ? Colors.white : Colors.grey.shade600,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: onPressed != null ? color : Colors.grey.shade300,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      elevation: onPressed != null ? 2 : 0,
    ),
  );
}

Widget buildWaitingScreen() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.schedule, size: 80, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          'Please confirm to start the test',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    ),
  );
}

Widget buildLoadingScreen() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: List.generate(
                    4,
                    (index) => Expanded(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Loading Questions...',
                style: TextStyle(
                    color: Colors.blueGrey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildErrorScreen(TestProvider provider) {
  return Center(
    child: Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
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
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Error",
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.fetchMcqs,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildBottomNavigationBar(BuildContext context, TestProvider provider,
    TimerController timerController) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
        child: Row(
      children: [
        Expanded(
            child: buildPaperNavButton(
                icon: Icons.arrow_back_ios,
                label: 'Previous',
                onPressed: provider.currentIndex > 0
                    ? provider.previousQuestion
                    : null,
                color: Colors.blueGrey)),
        const SizedBox(width: 12),
        Expanded(
            child: buildPaperNavButton(
                icon: Icons.arrow_forward_ios,
                label: 'Next',
                onPressed:
                    provider.currentIndex < provider.filteredMcqs.length - 1
                        ? provider.nextQuestion
                        : null,
                color: Colors.blueGrey)),
        const SizedBox(width: 12),
        Expanded(
          child: buildPaperNavButton(
            icon: Icons.check,
            label: 'Submit',
            onPressed: provider.hasSubmitted
                ? null
                : () =>
                    showSubmitConfirmation(context, provider, timerController),
            color: Colors.green,
          ),
        ),
      ],
    )),
  );
}

// NEW: Updated subject button with highlighting and tab selection
Widget buildSubjectJumpButton(
    TestProvider provider, String subject, String range) {
  final isSelected = provider.selectedSubject == subject;

  return Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: provider.hasSubmitted
            ? null
            : () => provider.jumpToSubject(subject),
        style: ElevatedButton.styleFrom(
          // NEW: Dynamic styling based on selection
          backgroundColor: isSelected ? Colors.blueGrey : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.blueGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isSelected ? Colors.blueGrey : Colors.grey.shade300,
              width: isSelected ? 2 : 1, // Thicker border when selected
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          elevation: isSelected ? 4 : 0, // Elevation when selected
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subject,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            Text(
              range,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildPaperStatColumn(
    String value, String label, IconData icon, Color color) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 8),
      Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
    ],
  );
}

Widget buildPaperInstruction(IconData icon, String text, Color color) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.blueGrey,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

/// Helper for stats row
Widget buildPaperSubmitStatRow(
    IconData icon, String label, String value, Color color) {
  return Row(
    children: [
      Icon(icon, color: color),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      Text(
        value,
        style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    ],
  );
}
