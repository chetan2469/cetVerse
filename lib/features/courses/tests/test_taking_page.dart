import 'dart:async';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
  late int _timeRemaining; // time in seconds
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    userAnswers = List<int>.filled(widget.mcqs.length, -1); // -1 = unanswered
    reviewedQuestions = {};
    _timeRemaining = widget.mcqs.length * 60; // 1 minute per question
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
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer.cancel();
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
    setState(() => _currentIndex = index);
    _scrollToCurrentQuestion();
  }

  void _scrollToCurrentQuestion() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        final double itemWidth = 32.0; // Adjusted for smaller size + margins
        final double screenWidth = MediaQuery.of(context).size.width -
            112; // Adjusted for visible area
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
    const double swipeThreshold = 100; // pixels per second
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
          title: const Text(
            'Are you sure you want to submit?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.check_box, color: Colors.green),
                title: const Text('Attempted: '),
                trailing: Text('$attemptedCount'),
              ),
              ListTile(
                leading: const Icon(Icons.crop_square_sharp, color: Colors.red),
                title: const Text('Unattempted:'),
                trailing: Text('$unattemptedCount'),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark,
                    color: Color.fromARGB(255, 213, 193, 15)),
                title: const Text('Save for Review:'),
                trailing: Text('$reviewCount'),
              ),
              ListTile(
                leading: const Icon(Icons.lock_clock_outlined,
                    color: Colors.blueAccent),
                title: const Text('Time Left:'),
                trailing: Text('$timeLeft'),
              ),
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
      }).then((_) {
        print('Test history saved successfully');
      }).catchError((error) {
        print('Failed to save test history: $error');
      });
    } else {
      print('User phone number is null. Cannot save test history.');
    }

    Navigator.push(
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
      endDrawer: MockTestSideBar(
        userAnswers: userAnswers,
        reviewedQuestions: reviewedQuestions,
        mcqs: widget.mcqs,
        subject: widget.subject,
        hasSubmitted: _hasSubmitted,
        onJumpToQuestion: _jumpToQuestion,
      ),
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          "Test ${widget.testNumber} - ${widget.subject}",
          style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Attempted: ${widget.mcqs.length - countUnansweredQuestions()}/$totalQuestions",
                  ),
                ),
                Expanded(
                  child: Text(
                    "Time Left: ${_formatTime(_timeRemaining)}",
                    style: TextStyle(
                      color: _timeRemaining < 60 ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                ),
              ],
            ),
          ),
          Container(
            width: MediaQuery.sizeOf(context).width,
            height: 1,
            color: Colors.black,
          ),
          Expanded(
            child: GestureDetector(
                onHorizontalDragEnd: _onSwipe,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (details) {
                    if (_hasSubmitted) return;

                    const swipeThreshold = 50; // Adjust sensitivity as needed

                    if (details.primaryVelocity! > swipeThreshold) {
                      // Swiped right - previous question
                      if (_currentIndex > 0) {
                        _previousQuestion();
                      }
                    } else if (details.primaryVelocity! < -swipeThreshold) {
                      // Swiped left - next question
                      if (_currentIndex < widget.mcqs.length - 1) {
                        _nextQuestion();
                      }
                    }
                  },
                  child: _buildQuestionCard(
                      _currentIndex, widget.mcqs[_currentIndex]),
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0 ? _previousQuestion : null,
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
                  onPressed: _currentIndex < widget.mcqs.length - 1
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text("Submit", style: TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildSwipeableQuestionCard() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (_hasSubmitted) return;

        const swipeThreshold = 100; // Minimum swipe distance to trigger

        if (details.primaryVelocity! > swipeThreshold) {
          // Swipe right - previous question
          if (_currentIndex > 0) {
            setState(() {
              _currentIndex--;
              _scrollToCurrentQuestion();
            });
          }
        } else if (details.primaryVelocity! < -swipeThreshold) {
          // Swipe left - next question
          if (_currentIndex < widget.mcqs.length - 1) {
            setState(() {
              _currentIndex++;
              _scrollToCurrentQuestion();
            });
          }
        }
      },
      child: Stack(
        children: [
          _buildQuestionCard(_currentIndex, widget.mcqs[_currentIndex]),

          // Visual feedback for swiping
          if (_currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.chevron_left,
                  size: 36,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
            ),

          if (_currentIndex < widget.mcqs.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.chevron_right,
                  size: 36,
                  color: Colors.grey.withOpacity(0.5),
                ),
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
    final explanationMap = mcq['explanation'] as Map<String, dynamic>? ?? {};
    final String explanationText =
        explanationMap['text'] ?? 'No explanation provided.';
    final String explanationImage = explanationMap['image'] ?? '';

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

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  originText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              TeXView(
                key: ValueKey("quiz_$index"),
                child: TeXViewColumn(
                  children: [
                    TeXViewDocument(
                      finalQuestionText,
                      style: TeXViewStyle(
                        textAlign: TeXViewTextAlign.left,
                        fontStyle: TeXViewFontStyle(fontSize: 16),
                        padding: TeXViewPadding.all(16),
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
                        borderRadius: TeXViewBorderRadius.all(8),
                        border: TeXViewBorder.all(
                          TeXViewBorderDecoration(
                            borderWidth: 2,
                            borderColor:
                                Colors.blue, // Blue border for selected
                          ),
                        ),
                        margin: TeXViewMargin.all(8),
                        backgroundColor:
                            Colors.transparent, // No background color
                        padding: TeXViewPadding.all(10),
                      ),
                      normalItemStyle: const TeXViewStyle(
                        margin: TeXViewMargin.all(8),
                        borderRadius: TeXViewBorderRadius.all(8),
                        border: TeXViewBorder.all(
                          TeXViewBorderDecoration(
                            borderWidth: 1,
                            borderColor: Colors.grey,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        padding: TeXViewPadding.all(10),
                      ),
                      onTap: _hasSubmitted ? null : _selectAnswer,
                    ),
                  ],
                ),
                style: const TeXViewStyle(
                  margin: TeXViewMargin.all(10),
                  padding: TeXViewPadding.all(10),
                  borderRadius: TeXViewBorderRadius.all(10),
                  border: TeXViewBorder.all(
                    TeXViewBorderDecoration(
                      borderColor: Colors.grey,
                      borderStyle: TeXViewBorderStyle.solid,
                      borderWidth: 1,
                    ),
                  ),
                  backgroundColor: Colors.white,
                ),
                loadingWidgetBuilder: (context) => const Center(
                  child: Center(),
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.bookmark,
                color: reviewedQuestions.contains(index)
                    ? const Color.fromARGB(255, 228, 210, 42)
                    : Colors.grey,
                size: 24,
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
    final isSelected = userAnswers[index] == int.parse(id.split('_')[1]) - 1;
    return TeXViewGroupItem(
      rippleEffect: true,
      id: id,
      child: TeXViewDocument(
        "<b>$label: </b>$content",
        style: TeXViewStyle(
          padding: const TeXViewPadding.all(12),
          fontStyle: TeXViewFontStyle(fontSize: 14),
        ),
      ),
    );
  }
}
