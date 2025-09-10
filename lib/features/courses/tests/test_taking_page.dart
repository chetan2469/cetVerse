import 'dart:async';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'MockTestSideBar.dart';

class TestTakingPage extends StatefulWidget {
  final String level;
  final String subject;
  final String chapter;
  final int testNumber;
  final List<Map<String, dynamic>> mcqs;

  const TestTakingPage({
    super.key,
    required this.level,
    required this.subject,
    required this.chapter,
    required this.testNumber,
    required this.mcqs,
  });

  @override
  _TestTakingPageState createState() => _TestTakingPageState();
}

class _TestTakingPageState extends State<TestTakingPage> {
  late List<int> userAnswers;
  late Set<int> reviewedQuestions;
  int _currentIndex = 0;
  bool _hasSubmitted = false;
  late Timer _timer;
  late int _timeRemaining;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    userAnswers = List<int>.filled(widget.mcqs.length, -1);
    reviewedQuestions = {};
    _timeRemaining = widget.mcqs.length * 60;
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          timer.cancel();
          if (!_hasSubmitted) {
            _submitTest();
          }
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _nextQuestion() {
    if (_currentIndex < widget.mcqs.length - 1) {
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

  void _jumpToQuestion(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _scrollToCurrentQuestion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double itemWidth = 32.0;
        final double screenWidth = MediaQuery.of(context).size.width - 112;
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

  Future<void> _showBackConfirmation(BuildContext context) async {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue, size: 20),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

    // Only pop if user confirmed
    if (shouldPop == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  void _selectAnswer(String id) {
    if (_hasSubmitted) return;
    final optionIndex = int.parse(id.split('_')[1]) - 1;
    setState(() {
      userAnswers[_currentIndex] =
          userAnswers[_currentIndex] == optionIndex ? -1 : optionIndex;
    });
  }

  void _toggleReview(int index) {
    if (_hasSubmitted) return;
    setState(() {
      if (reviewedQuestions.contains(index)) {
        reviewedQuestions.remove(index);
      } else {
        reviewedQuestions.add(index);
      }
    });
  }

  void _onSwipe(DragEndDetails details) {
    if (_hasSubmitted) return;
    const double swipeThreshold = 100;
    if (details.primaryVelocity! < -swipeThreshold) {
      _nextQuestion();
    } else if (details.primaryVelocity! > swipeThreshold) {
      _previousQuestion();
    }
  }

  void _showSubmitConfirmation() {
    final int attemptedCount = widget.mcqs.length - countUnansweredQuestions();
    final int unattemptedCount = countUnansweredQuestions();
    final int reviewCount = reviewedQuestions.length;
    final String timeLeft = _formatTime(_timeRemaining);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigoAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.indigoAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Submit Test?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Card(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatRow(Icons.check_circle_outline, 'Attempted',
                      '$attemptedCount', Colors.green),
                  const SizedBox(height: 12),
                  _buildStatRow(Icons.radio_button_unchecked, 'Unattempted',
                      '$unattemptedCount', Colors.red),
                  const SizedBox(height: 12),
                  _buildStatRow(Icons.bookmark_border, 'For Review',
                      '$reviewCount', Colors.orange),
                  const SizedBox(height: 12),
                  _buildStatRow(Icons.schedule, 'Time Left', timeLeft,
                      Colors.indigoAccent),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitTest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text('Submit Test'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTheme.captionStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _submitTest() {
    if (_hasSubmitted) return;
    _timer.cancel();
    setState(() => _hasSubmitted = true);

    int correctCount = 0;
    int unansweredCount = 0;

    for (int i = 0; i < widget.mcqs.length; i++) {
      if (userAnswers[i] == -1) {
        unansweredCount++;
        continue;
      }
      final mcq = widget.mcqs[i];
      final correctIndex = _answerToIndex(mcq['answer'] ?? "A");
      if (userAnswers[i] == correctIndex) correctCount++;
    }

    final attemptedCount = widget.mcqs.length - unansweredCount;
    final wrongCount = attemptedCount - correctCount;
    final accuracy = attemptedCount > 0
        ? (correctCount / attemptedCount * 100).toStringAsFixed(1)
        : '0.0';
    final timeLeft = _formatTime(_timeRemaining);
    final score = correctCount;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;

    if (userPhoneNumber != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .collection('testHistory')
          .add({
        'score': score,
        'timeleft': timeLeft,
        'accuracy': accuracy,
        'correct': correctCount,
        'wrong': wrongCount,
        'unattempted': unansweredCount,
        'level': widget.level,
        'subject': widget.subject,
        'chapter': widget.chapter,
        'testnumber': widget.testNumber,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TestResultPage(
          mcqs: widget.mcqs,
          userAnswers: userAnswers,
          correctCount: correctCount,
          unansweredCount: unansweredCount,
          timeTaken: timeLeft,
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

  int countUnansweredQuestions() {
    return userAnswers.where((answer) => answer == -1).length;
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = widget.mcqs.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: MockTestSideBar(
        userAnswers: userAnswers,
        reviewedQuestions: reviewedQuestions,
        mcqs: widget.mcqs,
        subject: widget.subject,
        hasSubmitted: _hasSubmitted,
        onJumpToQuestion: _jumpToQuestion,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
          onPressed: () => _showBackConfirmation(context),
        ),
        title: Text(
          "Test ${widget.testNumber} - ${widget.subject}",
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.indigoAccent),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header Card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              shadowColor: Colors.grey.withOpacity(0.3),
              child: Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.quiz_outlined,
                        label: 'Attempted',
                        value:
                            '${widget.mcqs.length - countUnansweredQuestions()}/$totalQuestions',
                        color: Colors.indigoAccent,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.schedule_outlined,
                        label: 'Time Left',
                        value: _formatTime(_timeRemaining),
                        color: _timeRemaining < 60 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Question Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onHorizontalDragEnd: _onSwipe,
                child: _buildQuestionCard(
                    _currentIndex, widget.mcqs[_currentIndex]),
              ),
            ),
          ),

          // Navigation Controls
          Container(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              shadowColor: Colors.grey.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(
                    //       'Question Navigation',
                    //       style: AppTheme.subheadingStyle.copyWith(
                    //         fontSize: 14,
                    //         color: Colors.black,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //     Text(
                    //       '${_currentIndex + 1} of ${widget.mcqs.length}',
                    //       style: AppTheme.captionStyle.copyWith(
                    //         fontSize: 12,
                    //         color: Colors.black87,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNavButton(
                            icon: Icons.arrow_back_ios,
                            label: 'Previous',
                            onPressed:
                                _currentIndex > 0 ? _previousQuestion : null,
                            color: Colors.indigoAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNavButton(
                            icon: Icons.arrow_forward_ios,
                            label: 'Next',
                            onPressed: _currentIndex < widget.mcqs.length - 1
                                ? _nextQuestion
                                : null,
                            color: Colors.indigoAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildNavButton(
                            icon: Icons.send,
                            label: 'Submit',
                            onPressed:
                                _hasSubmitted ? null : _showSubmitConfirmation,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 4),
        Text(
          label + " : ",
          style: AppTheme.captionStyle.copyWith(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey.shade300,
        foregroundColor:
            onPressed != null ? Colors.white : Colors.grey.shade600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: onPressed != null ? 4 : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> mcq) {
    final questionMap = mcq['question'] as Map<String, dynamic>? ?? {};
    final String questionText = questionMap['text'] ?? 'No question provided.';
    final String questionImage = questionMap['image'] ?? '';
    final String originText = mcq['origin'] ?? '-';

    final optionsMap = mcq['options'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionA =
        optionsMap['A'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionB =
        optionsMap['B'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionC =
        optionsMap['C'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionD =
        optionsMap['D'] as Map<String, dynamic>? ?? {};

    final String aText = optionA['text'] ?? '';
    final String aImage = optionA['image'] ?? '';
    final String bText = optionB['text'] ?? '';
    final String bImage = optionB['image'] ?? '';
    final String cText = optionC['text'] ?? '';
    final String cImage = optionC['image'] ?? '';
    final String dText = optionD['text'] ?? '';
    final String dImage = optionD['image'] ?? '';

    String finalQuestionText = "<b>Q${index + 1}: </b>$questionText";
    if (questionImage.isNotEmpty) {
      finalQuestionText +=
          '<br/><img src="$questionImage" width=300 height=150/>';
    }

    String finalAText = aText;
    if (aImage.isNotEmpty) {
      finalAText += '<br/><img src="$aImage" width=300 height=150/>';
    }
    String finalBText = bText;
    if (bImage.isNotEmpty) {
      finalBText += '<br/><img src="$bImage" width=300 height=150/>';
    }
    String finalCText = cText;
    if (cImage.isNotEmpty) {
      finalCText += '<br/><img src="$cImage" width=300 height=150/>';
    }
    String finalDText = dText;
    if (dImage.isNotEmpty) {
      finalDText += '<br/><img src="$dImage" width=300 height=60/>';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Stack(
        children: [
          Column(
            children: [
              // Question Header
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigoAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            color: Colors.indigoAccent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Question ${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              TextSpan(
                                text: "  " + originText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight
                                      .bold, // Made grey text bold as requested
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Question Content
              Expanded(
                  child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false, // Hide the scrollbar
                  overscroll: false, // Optional: disable overscroll effect
                ),
                child: SingleChildScrollView(
                  child: TeXView(
                    key: ValueKey("quiz_$index"),
                    child: TeXViewColumn(
                      children: [
                        TeXViewDocument(
                          finalQuestionText,
                          style: TeXViewStyle(
                            textAlign: TeXViewTextAlign.left,
                            fontStyle: TeXViewFontStyle(fontSize: 15),
                            padding: TeXViewPadding.all(8),
                          ),
                        ),
                        TeXViewGroup(
                          children: [
                            _buildOption(index, "id_1", "A", finalAText),
                            _buildOption(index, "id_2", "B", finalBText),
                            _buildOption(index, "id_3", "C", finalCText),
                            _buildOption(index, "id_4", "D", finalDText),
                          ],
                          selectedItemStyle: const TeXViewStyle(
                            borderRadius: TeXViewBorderRadius.all(12),
                            border: TeXViewBorder.all(
                              TeXViewBorderDecoration(
                                borderWidth: 2,
                                borderColor:
                                    Colors.blue, // Changed to blue as requested
                              ),
                            ),
                            margin: TeXViewMargin.all(8),
                            backgroundColor:
                                Color(0xFFE3F2FD), // Light blue background
                            padding: TeXViewPadding.all(16),
                          ),
                          normalItemStyle: const TeXViewStyle(
                            margin: TeXViewMargin.all(8),
                            borderRadius: TeXViewBorderRadius.all(12),
                            border: TeXViewBorder.all(
                              TeXViewBorderDecoration(
                                borderWidth: 1,
                                borderColor: Colors.grey,
                              ),
                            ),
                            backgroundColor: Colors.white,
                            padding: TeXViewPadding.all(16),
                          ),
                          onTap: _hasSubmitted ? null : _selectAnswer,
                        ),
                      ],
                    ),
                    style: const TeXViewStyle(
                      margin: TeXViewMargin.all(16),
                      padding: TeXViewPadding.all(0),
                      borderRadius: TeXViewBorderRadius.all(0),
                      backgroundColor: Colors.transparent,
                    ),
                    loadingWidgetBuilder: (context) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(
                          color: Colors.blue, // Changed to blue for consistency
                        ),
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
          // Review Bookmark
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              icon: Icon(
                reviewedQuestions.contains(index)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: reviewedQuestions.contains(index)
                    ? Colors.orange
                    : Colors.grey.shade600,
                size: 30,
              ),
              onPressed: () => _toggleReview(index),
            ),
          ),
        ],
      ),
    );
  }

  TeXViewGroupItem _buildOption(
      int index, String id, String label, String content) {
    return TeXViewGroupItem(
      rippleEffect: true,
      id: id,
      child: TeXViewDocument(
        "<b>$label: </b>$content",
        style: TeXViewStyle(
          fontStyle: TeXViewFontStyle(fontSize: 14),
        ),
      ),
    );
  }
}
