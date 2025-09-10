import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/courses/TimerController.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

mixin TestDialogs<T extends StatefulWidget> on State<T> {
  // These getters must be implemented by the main widget
  String get year;
  String get pyqType;
  String get docId;
  List<int> get userAnswers;
  Set<int> get reviewedQuestions;
  List<Map<String, dynamic>> get mcqs;
  TimerController get timerController;
  bool get hasSubmitted;

  // These setters must be implemented by the main widget
  set hasConfirmedStart(bool value);
  set hasSubmitted(bool value);

  // Methods that must be implemented by the main widget
  void fetchMcqs();
  void submitTest();

  void showStartConfirmation() {
    final int totalQuestions = pyqType.toLowerCase() == 'pcm' ? 150 : 200;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8F8F8),
                  Colors.white,
                  Color(0xFFF5F5F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                  color: Colors.grey.shade400, width: 2),
                            ),
                            child: const Icon(Icons.assignment,
                                color: Colors.white, size: 32),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'MHT CET $year',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${pyqType.toUpperCase()} Test',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildPaperStatColumn('$totalQuestions',
                                  'Questions', Icons.quiz, Colors.blueGrey),
                              buildPaperStatColumn('180 min', 'Duration',
                                  Icons.schedule, Colors.blueGrey),
                              buildPaperStatColumn(
                                  '200', 'Marks', Icons.star, Colors.blueGrey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
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
                            Icon(Icons.info_outline,
                                color: Colors.blueGrey, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'Test Instructions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        buildPaperInstruction(Icons.timer,
                            'Auto-submit when time expires', Colors.red),
                        const SizedBox(height: 12),
                        buildPaperInstruction(
                            Icons.radio_button_checked,
                            'Multiple choice questions with single correct answer',
                            Colors.blueGrey),
                        const SizedBox(height: 12),
                        buildPaperInstruction(
                            Icons.pause_circle_outline,
                            'Test cannot be paused for fair ranking',
                            Colors.orange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => hasConfirmedStart = true);
                        fetchMcqs();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side:
                              BorderSide(color: Colors.grey.shade300, width: 2),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        'Start Test',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                fontSize: 15, color: Colors.blueGrey, height: 1.4),
          ),
        ),
      ],
    );
  }

  void showSubmitConfirmation() {
    int attemptedCount = userAnswers.where((answer) => answer != -1).length;
    int unattemptedCount = userAnswers.where((answer) => answer == -1).length;
    int reviewCount = reviewedQuestions.length;
    String timeLeft = timerController.formatTime(timerController.timeRemaining);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 2),
          ),
          title: const Text(
            'Submit Test?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildPaperSubmitStatRow(Icons.check_circle, 'Attempted',
                    '$attemptedCount', Colors.green),
                const SizedBox(height: 8),
                buildPaperSubmitStatRow(Icons.radio_button_unchecked,
                    'Unattempted', '$unattemptedCount', Colors.red),
                const SizedBox(height: 8),
                buildPaperSubmitStatRow(Icons.bookmark, 'For Review',
                    '$reviewCount', Colors.orange),
                const SizedBox(height: 8),
                buildPaperSubmitStatRow(
                    Icons.schedule, 'Time Left', timeLeft, Colors.blueGrey),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                side: BorderSide(color: Colors.grey.shade300, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                submitTest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Colors.green, width: 1),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Submit Test'),
            ),
          ],
        );
      },
    );
  }

  Widget buildPaperSubmitStatRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
              fontWeight: FontWeight.w500, color: Colors.blueGrey),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Future<void> showBackConfirmation(BuildContext context) async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            'Are you sure you want to go back? Your progress will be lost.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

    if (shouldPop == true && context.mounted) {
      Navigator.pop(context);
    }
  }
}
