import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'PyqQuestionCard.dart';

mixin TestUIComponents<T extends StatefulWidget> on State<T> {
  // These getters must be implemented by the main widget
  List<Map<String, dynamic>> get mcqs;
  int get currentIndex;
  List<int> get userAnswers;
  bool get hasSubmitted;
  bool get isTransitioning;
  Set<int> get reviewedQuestions;
  String? get errorMessage;
  String get selectedTab; // NEW

  // Methods that must be implemented by the main widget
  void selectAnswer(String id);
  void toggleReview(int index);
  void nextQuestion();
  void previousQuestion();
  void jumpToSubject(String subject);
  void showSubmitConfirmation();
  void fetchMcqs();
  bool get canGoPrevious; // NEW
  bool get canGoNext; // NEW

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
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
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

  Widget buildErrorScreen() {
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
              errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchMcqs,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Widget buildMainContent(GlobalKey<ScaffoldState> scaffoldKey, bool isPcm,
      int attemptedCount, int totalQuestions) {
    return Column(
      children: [
        // Stats Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
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
                    'Attempted: $attemptedCount/$totalQuestions',
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
        // Subject Navigation Buttons
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildSubjectJumpButton('All', '1-$totalQuestions'),
              buildSubjectJumpButton('Physics', '1-50'),
              buildSubjectJumpButton('Chemistry', '51-100'),
              buildSubjectJumpButton(
                  isPcm ? 'Maths' : 'Biology', isPcm ? '101-150' : '101-200'),
            ],
          ),
        ),
        // Question Content
        Expanded(
          child: mcqs.isNotEmpty &&
                  currentIndex >= 0 &&
                  currentIndex < mcqs.length
              ? GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (hasSubmitted || isTransitioning) return;
                    const double swipeThreshold = 100;
                    if (details.primaryVelocity! < -swipeThreshold) {
                      nextQuestion();
                    } else if (details.primaryVelocity! > swipeThreshold) {
                      previousQuestion();
                    }
                  },
                  child: PyqQuestionCard(
                    key: ValueKey('question_${mcqs[currentIndex]['docId']}'),
                    index: currentIndex,
                    mcq: mcqs[currentIndex],
                    userAnswers: userAnswers,
                    hasSubmitted: hasSubmitted,
                    onSelectAnswer: selectAnswer,
                    reviewedQuestions: reviewedQuestions,
                    onToggleReview: toggleReview,
                    nextQuestion: nextQuestion,
                    prevQuestion: previousQuestion,
                    originalMcqs: mcqs,
                  ),
                )
              : const Center(
                  child: Text(
                    'No questions available',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                ),
        ),
      ],
    );
  }

  Widget buildBottomNavigationBar() {
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
                onPressed: canGoPrevious && !isTransitioning
                    ? previousQuestion
                    : null, // UPDATED
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildPaperNavButton(
                icon: Icons.arrow_forward_ios,
                label: 'Next',
                onPressed: canGoNext ? nextQuestion : null, // UPDATED
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildPaperNavButton(
                icon: Icons.check,
                label: 'Submit',
                onPressed: hasSubmitted || isTransitioning
                    ? null
                    : showSubmitConfirmation,
                color: Colors.green,
              ),
            ),
          ],
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
        foregroundColor:
            onPressed != null ? Colors.white : Colors.grey.shade600,
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

  // NEW: Updated subject button with highlighting and tab selection
  Widget buildSubjectJumpButton(String subject, String range) {
    final isSelected = selectedTab == subject;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: hasSubmitted || isTransitioning
              ? null
              : () => jumpToSubject(subject),
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
}
