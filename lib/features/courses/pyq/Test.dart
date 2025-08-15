import 'dart:async';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/courses/TimerController.dart';
import 'package:cet_verse/courses/TimerWidget.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:provider/provider.dart';

import 'PyqQuestionCard.dart';
import 'TestSideBar.dart';

class Test extends StatefulWidget {
  final String year;
  final String pyqType;
  final String docId;

  const Test({
    super.key,
    required this.year,
    required this.pyqType,
    required this.docId,
  });

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  List<int> userAnswers = [];
  Set<int> reviewedQuestions = {};
  int _currentIndex = 0;
  bool _hasSubmitted = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _mcqs = [];
  List<Map<String, dynamic>> _filteredMcqs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, Widget> _questionCache = {};
  final TimerController _timerController = TimerController();
  String _selectedSubject = 'All';
  bool _hasConfirmedStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartConfirmation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _questionCache.clear();
    _timerController.dispose();
    super.dispose();
  }

  void _showStartConfirmation() {
    final int totalQuestions =
        widget.pyqType.toLowerCase() == 'pcm' ? 150 : 200;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'MHT CET ${widget.year} Test',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatColumn('$totalQuestions', 'Question'),
                    const SizedBox(width: 24),
                    _buildStatColumn('180 min', 'Duration'),
                    const SizedBox(width: 24),
                    _buildStatColumn('200', 'Marks'),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(
                    color: Colors.grey,
                    thickness: 1,
                    indent: 20,
                    endIndent: 20),
                const SizedBox(height: 32),
                const Text(
                  'Instructions :-',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 16),
                _buildInstruction('1. Test will auto submit when time is up'),
                const SizedBox(height: 8),
                _buildInstruction(
                    '2. This test is multiple choice questions (MCQ) with one or more correct answers'),
                const SizedBox(height: 8),
                _buildInstruction(
                    '3. Test cannot be paused to ensure fair ranking. It can be attempted in practice mode'),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _hasConfirmedStart = true);
                    _fetchMcqs();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Test',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 16, color: Colors.black87))),
        ],
      ),
    );
  }

  Future<void> _fetchMcqs() async {
    try {
      setState(() => _isLoading = true);
      final snapshot = await FirebaseFirestore.instance
          .collection('pyq')
          .doc(widget.docId)
          .collection('test')
          .get();

      _mcqs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'docId': doc.id,
          'subject': data['subject'] ?? 'Unknown',
        };
      }).toList();

      // Sort _mcqs by docId assuming docId is string representation of question number
      _mcqs.sort(
          (a, b) => int.parse(a['docId']).compareTo(int.parse(b['docId'])));

      setState(() {
        if (_mcqs.isEmpty) {
          _errorMessage = 'No MCQs found for ${widget.docId}';
        } else {
          userAnswers = List<int>.filled(_mcqs.length, -1);
          _filteredMcqs = _mcqs;
          _timerController.initialize(10800, _submitTest); // 180 minutes
        }
        _isLoading = false;
      });
      print('Fetched MCQs for ${widget.docId}: ${_mcqs.length} items');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading MCQs: $e';
      });
      print('Error fetching MCQs for ${widget.docId}: $e');
    }
  }

  void _filterQuestions(String subject) {
    setState(() {
      _selectedSubject = subject;
      _questionCache.clear();
      if (subject == 'All') {
        _filteredMcqs = List.from(_mcqs);
      } else {
        _filteredMcqs =
            _mcqs.where((mcq) => mcq['subject'] == subject).toList();
      }
      // Reset current index to 0 or the first valid index
      _currentIndex = _filteredMcqs.isNotEmpty ? 0 : -1;
    });
    if (_filteredMcqs.isNotEmpty) {
      _scrollToCurrentQuestion();
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _filteredMcqs.length - 1) {
      setState(() => _currentIndex++);
      _scrollToCurrentQuestion();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _scrollToCurrentQuestion();
    }
  }

  void _jumpToQuestion(int originalIndex) {
    if (originalIndex < 0 || originalIndex >= _mcqs.length) return;

    final targetMcq = _mcqs[originalIndex];
    int filteredIndex = _filteredMcqs.indexOf(targetMcq);

    if (filteredIndex != -1) {
      setState(() => _currentIndex = filteredIndex);
      _scrollToCurrentQuestion();
    } else {
      // Switch to the subject of the target question
      final subject = targetMcq['subject'] as String? ?? 'All';
      _filterQuestions(subject);
      // After filtering, find the new index
      filteredIndex = _filteredMcqs.indexOf(targetMcq);
      if (filteredIndex != -1) {
        setState(() => _currentIndex = filteredIndex);
        _scrollToCurrentQuestion();
      }
    }
  }

  void _scrollToCurrentQuestion() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && _currentIndex >= 0) {
        final double itemWidth = 48.0; // Adjusted for item width + margins
        final double screenWidth = MediaQuery.of(context).size.width -
            112; // Adjusted for visible area (56px per button + padding)
        final double offset =
            _currentIndex * itemWidth - (screenWidth / 2) + (itemWidth / 2);
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _selectAnswer(String id) {
    if (_hasSubmitted) return;
    final optionIndex = int.parse(id.split('_')[1]) - 1;
    setState(() {
      final originalIndex = _mcqs.indexOf(_filteredMcqs[_currentIndex]);
      if (originalIndex != -1) {
        if (userAnswers[originalIndex] == optionIndex) {
          userAnswers[originalIndex] = -1;
        } else {
          userAnswers[originalIndex] = optionIndex;
        }
        _questionCache.remove(_currentIndex);
      }
    });
  }

  void _showSubmitConfirmation() {
    int attemptedCount = userAnswers.where((answer) => answer != -1).length;
    int unattemptedCount = userAnswers.where((answer) => answer == -1).length;
    int reviewCount = reviewedQuestions.length;
    String timeLeft =
        _timerController.formatTime(_timerController.timeRemaining);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Are you sure you want to submit your test?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                  leading: const Icon(Icons.check_box, color: Colors.green),
                  title: const Text('Attempted : '),
                  trailing: Text('$attemptedCount')),
              ListTile(
                  leading:
                      const Icon(Icons.crop_square_sharp, color: Colors.red),
                  title: const Text('Unattempted :'),
                  trailing: Text('$unattemptedCount')),
              ListTile(
                  leading: const Icon(Icons.bookmark,
                      color: Color.fromARGB(255, 213, 193, 15)),
                  title: const Text('Save for Review :'),
                  trailing: Text('$reviewCount')),
              ListTile(
                  leading:
                      const Icon(Icons.lock_clock_outlined, color: Colors.blue),
                  title: const Text('Total Time Left :'),
                  trailing: Text(timeLeft)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 58, 157, 233),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Cancel", style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitTest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Submit", style: TextStyle(fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  void _submitTest() {
    if (_hasSubmitted) return;
    setState(() => _hasSubmitted = true);
    _timerController.stop();

    int totalScore = 0;
    int correctCount = 0;
    int unansweredCount = 0;
    Map<String, Map<String, int>> subjectBreakdown = {};

    for (int i = 0; i < _mcqs.length; i++) {
      final mcq = _mcqs[i];
      final subject = mcq['subject'] as String?;
      if (subject == null) {
        continue; // Skip if subject is null
      }
      subjectBreakdown[subject] ??= {'correct': 0, 'incorrect': 0};

      if (userAnswers[i] == -1) {
        unansweredCount++;
        continue;
      }
      final correctIndex = _answerToIndex(mcq['answer'] as String? ?? "A");
      if (userAnswers[i] == correctIndex) {
        correctCount++;
        if (widget.pyqType?.toLowerCase() == 'pcm' && subject == 'Maths') {
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

    final totalQuestions = _mcqs.length;
    final attemptedCount = totalQuestions - unansweredCount;
    final wrongCount = attemptedCount - correctCount;
    final accuracy = attemptedCount > 0
        ? (correctCount / attemptedCount * 100).toStringAsFixed(1)
        : '0.0';
    final timeleft =
        _timerController.formatTime(_timerController.timeRemaining) ?? '00:00';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;

    if (userPhoneNumber != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('pyqHistory')
          .add({
        'year': widget.year,
        'pyqType': widget.pyqType,
        'accuracy': accuracy,
        'correct': correctCount,
        'score': totalScore,
        'timeleft': timeleft,
        'timestamp': FieldValue.serverTimestamp(),
        'unattempted': unansweredCount,
        'wrong': wrongCount,
      }).then((_) {
        print('PYQ history saved successfully');
      }).catchError((error) {
        print('Failed to save PYQ history: $error');
      });
    } else {
      print('User phone number is null. Cannot save PYQ history.');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestResultPage(
          mcqs: _mcqs,
          userAnswers: userAnswers,
          correctCount: totalScore,
          unansweredCount: unansweredCount,
          timeTaken: timeleft,
        ),
      ),
    );
  }

  int _answerToIndex(String answer) {
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

  void _toggleReview(int index) {
    if (_hasSubmitted) return;
    setState(() {
      final originalIndex = _mcqs.indexOf(_filteredMcqs[index]);
      if (originalIndex != -1) {
        if (reviewedQuestions.contains(originalIndex)) {
          reviewedQuestions.remove(originalIndex);
        } else {
          reviewedQuestions.add(originalIndex);
        }
        _questionCache.remove(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final isPcm = widget.pyqType.toLowerCase() == 'pcm';
    final thirdSubject = isPcm ? 'Maths' : 'Biology';
    final attemptedCount = userAnswers.where((answer) => answer != -1).length;
    final totalQuestions =
        _mcqs.isNotEmpty ? _mcqs.length : (isPcm ? 150 : 200);

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        drawer: const MyDrawer(),
        endDrawer: TestSideBar(
          pyqType: widget.pyqType,
          userAnswers: userAnswers,
          reviewedQuestions: reviewedQuestions,
          mcqs: _mcqs,
          hasSubmitted: _hasSubmitted,
          onJumpToQuestion: _jumpToQuestion,
        ),
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          leading: Builder(
              builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => scaffoldKey.currentState?.openDrawer())),
          title: Text('PYQ ${widget.year} Test',
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            if (!_isLoading && _mcqs.isNotEmpty && _hasConfirmedStart)
              TimerWidget(controller: _timerController),
          ],
        ),
        body: !_hasConfirmedStart
            ? const Center(
                child: Text('Please confirm to start the test.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)))
            : _isLoading
                ? const Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading MCQs...',
                            style: TextStyle(color: Colors.grey))
                      ]))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(_errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchMcqs,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            color: Colors.blue.shade50,
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Attempted Questions: $attemptedCount/$totalQuestions',
                                  style: AppTheme.subheadingStyle
                                      .copyWith(fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.menu),
                                  onPressed: () =>
                                      scaffoldKey.currentState?.openEndDrawer(),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            color: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildFilterButton('All'),
                                _buildFilterButton('Physics'),
                                _buildFilterButton('Chemistry'),
                                _buildFilterButton(isPcm ? 'Maths' : 'Biology'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _filteredMcqs.isNotEmpty &&
                                    _currentIndex >= 0 &&
                                    _currentIndex < _filteredMcqs.length
                                ? GestureDetector(
                                    onHorizontalDragEnd: (details) {
                                      if (_hasSubmitted) return;
                                      const double swipeThreshold = 100;
                                      if (details.primaryVelocity! <
                                          -swipeThreshold) {
                                        _nextQuestion();
                                      } else if (details.primaryVelocity! >
                                          swipeThreshold) {
                                        _previousQuestion();
                                      }
                                    },
                                    child: PyqQuestionCard(
                                      index: _currentIndex,
                                      mcq: _filteredMcqs[_currentIndex],
                                      userAnswers: userAnswers,
                                      hasSubmitted: _hasSubmitted,
                                      onSelectAnswer: _selectAnswer,
                                      reviewedQuestions: reviewedQuestions,
                                      onToggleReview: _toggleReview,
                                      nextQuestion: _nextQuestion,
                                      prevQuestion: _previousQuestion,
                                      originalMcqs: _mcqs,
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                        'No questions available or invalid selection.',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.grey))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: _currentIndex > 0
                                      ? _previousQuestion
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                ElevatedButton(
                                  onPressed:
                                      _currentIndex < _filteredMcqs.length - 1
                                          ? _nextQuestion
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
        floatingActionButton: ElevatedButton(
          onPressed: _hasSubmitted ? null : _showSubmitConfirmation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text("Submit", style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String subject) {
    final isSelected = _selectedSubject == subject;
    return ElevatedButton(
      onPressed: _hasSubmitted ? null : () => _filterQuestions(subject),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(subject,
          style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
    );
  }
}
