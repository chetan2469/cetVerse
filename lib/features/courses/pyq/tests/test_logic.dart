import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/courses/TimerController.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';

mixin TestLogic<T extends StatefulWidget> on State<T> {
  // These getters must be implemented by the main widget
  String get year;
  String get pyqType;
  String get docId;
  List<int> get userAnswers;
  Set<int> get reviewedQuestions;
  List<Map<String, dynamic>> get mcqs;
  int get currentIndex;
  bool get hasSubmitted;
  bool get isTransitioning;
  TimerController get timerController;
  ScrollController get scrollController;
  Map<int, Widget> get questionCache;
  String get selectedTab; // NEW

  // These setters must be implemented by the main widget
  set mcqs(List<Map<String, dynamic>> value);
  set userAnswers(List<int> value);
  set isLoading(bool value);
  set errorMessage(String? value);
  set currentIndex(int value);
  set hasSubmitted(bool value);
  set isTransitioning(bool value);
  set selectedTab(String value); // NEW

  Future<void> fetchMcqs() async {
    try {
      setState(() => isLoading = true);

      final snapshot = await FirebaseFirestore.instance
          .collection('pyq')
          .doc(docId)
          .collection('test')
          .get();

      mcqs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'docId': doc.id,
          'subject': data['subject'] ?? 'Unknown',
        };
      }).toList();

      mcqs.sort(
          (a, b) => int.parse(a['docId']).compareTo(int.parse(b['docId'])));

      setState(() {
        if (mcqs.isEmpty) {
          errorMessage = 'No MCQs found for $docId';
        } else {
          userAnswers = List<int>.filled(mcqs.length, -1);
          timerController.initialize(10800, submitTest);
        }
        isLoading = false;
      });

      print('Fetched MCQs for $docId: ${mcqs.length} items');
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading MCQs: $e';
      });
      print('Error fetching MCQs for $docId: $e');
    }
  }

  // NEW: Updated method with tab selection and navigation
  void jumpToSubject(String subject) {
    if (isTransitioning) return;

    setState(() {
      selectedTab = subject;
      int targetIndex = 0;
      switch (subject) {
        case 'Physics':
          targetIndex = 0; // Question 1
          break;
        case 'Chemistry':
          targetIndex = 50; // Question 51
          break;
        case 'Maths':
        case 'Biology':
          targetIndex = 100; // Question 101
          break;
        default:
          targetIndex = 0; // All - go to first question
      }

      // Ensure the target index is within bounds
      if (targetIndex >= mcqs.length) {
        targetIndex = mcqs.length - 1;
      }

      currentIndex = targetIndex;
    });

    scrollToCurrentQuestion();
  }

  // NEW: Check if previous button should be enabled based on selected tab
  bool get canGoPrevious {
    if (selectedTab == 'Chemistry') {
      return currentIndex > 50; // Disabled on question 51 (index 50)
    } else if (selectedTab == 'Maths' || selectedTab == 'Biology') {
      return currentIndex > 100; // Disabled on question 101 (index 100)
    } else {
      return currentIndex > 0; // Normal behavior for All/Physics
    }
  }

  bool get canGoNext {
    return currentIndex < mcqs.length - 1 && !isTransitioning;
  }

  void nextQuestion() {
    if (canGoNext) {
      setState(() {
        currentIndex++;
      });
      scrollToCurrentQuestion();
    }
  }

  void previousQuestion() {
    if (canGoPrevious) {
      setState(() {
        currentIndex--;
      });
      scrollToCurrentQuestion();
    }
  }

  void jumpToQuestion(int questionIndex) {
    if (questionIndex < 0 || questionIndex >= mcqs.length || isTransitioning)
      return;

    setState(() {
      currentIndex = questionIndex;
    });
    scrollToCurrentQuestion();
  }

  void scrollToCurrentQuestion() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients && currentIndex >= 0) {
        final double itemWidth = 48.0;
        final double screenWidth = MediaQuery.of(context).size.width - 112;
        final double offset =
            currentIndex * itemWidth - (screenWidth / 2) + (itemWidth / 2);
        scrollController.animateTo(
          offset.clamp(0.0, scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void selectAnswer(String id) {
    if (hasSubmitted || isTransitioning) return;
    final optionIndex = int.parse(id.split('_')[1]) - 1;

    // Only update the userAnswers array, don't call setState immediately
    if (userAnswers[currentIndex] == optionIndex) {
      userAnswers[currentIndex] = -1;
    } else {
      userAnswers[currentIndex] = optionIndex;
    }

    // Clear cache for this question
    questionCache.remove(currentIndex);

    // Minimal setState call - only update if mounted
    if (mounted) {
      setState(() {
        // This setState is now minimal and only updates necessary parts
      });
    }
  }

  void submitTest() {
    if (hasSubmitted) return;
    setState(() => hasSubmitted = true);
    timerController.stop();

    int totalScore = 0;
    int correctCount = 0;
    int unansweredCount = 0;
    Map<String, Map<String, int>> subjectBreakdown = {};

    for (int i = 0; i < mcqs.length; i++) {
      final mcq = mcqs[i];
      final subject = mcq['subject'] as String?;
      if (subject == null) continue;

      subjectBreakdown[subject] ??= {'correct': 0, 'incorrect': 0};

      if (userAnswers[i] == -1) {
        unansweredCount++;
        continue;
      }

      final correctIndex = answerToIndex(mcq['answer'] as String? ?? "A");
      if (userAnswers[i] == correctIndex) {
        correctCount++;
        if (pyqType.toLowerCase() == 'pcm' && subject == 'Maths') {
          totalScore += 2;
        } else {
          totalScore += 1;
        }
        subjectBreakdown[subject]!['correct'] =
            (subjectBreakdown[subject]!['correct'] ?? 0) + 1;
      } else {
        subjectBreakdown[subject]!['incorrect'] =
            (subjectBreakdown[subject]!['incorrect'] ?? 0) + 1;
      }
    }

    final totalQuestions = mcqs.length;
    final attemptedCount = totalQuestions - unansweredCount;
    final wrongCount = attemptedCount - correctCount;
    final accuracy = attemptedCount > 0
        ? (correctCount / attemptedCount * 100).toStringAsFixed(1)
        : '0.0';
    final timeleft =
        timerController.formatTime(timerController.timeRemaining) ?? '00:00';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;

    if (userPhoneNumber != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('pyqHistory')
          .add({
        'year': year,
        'pyqType': pyqType,
        'accuracy': accuracy,
        'correct': correctCount,
        'score': totalScore,
        'timeleft': timeleft,
        'timestamp': FieldValue.serverTimestamp(),
        'unattempted': unansweredCount,
        'wrong': wrongCount,
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestResultPage(
          mcqs: mcqs,
          userAnswers: userAnswers,
          correctCount: totalScore,
          unansweredCount: unansweredCount,
          timeTaken: timeleft,
        ),
      ),
    );
  }

  int answerToIndex(String answer) {
    switch (answer.toUpperCase()) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return 0;
    }
  }

  void toggleReview(int index) {
    if (hasSubmitted || isTransitioning) return;

    if (reviewedQuestions.contains(index)) {
      reviewedQuestions.remove(index);
    } else {
      reviewedQuestions.add(index);
    }

    if (mounted) {
      setState(() {});
    }
  }
}
