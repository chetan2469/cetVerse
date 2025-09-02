import 'dart:async';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:shimmer/shimmer.dart'; // Add this import
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

class _TestTakingPageState extends State<TestTakingPage>
    with TickerProviderStateMixin {
  late List<int> userAnswers;
  late Set<int> reviewedQuestions;
  int _currentIndex = 0;
  bool _hasSubmitted = false;
  bool _isLoading = false; // Add loading state
  bool _isTransitioning = false; // Add transition state
  late Timer _timer;
  late int _timeRemaining;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Animation controllers for smooth transitions
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    userAnswers = List<int>.filled(widget.mcqs.length, -1);
    reviewedQuestions = {};
    _timeRemaining = widget.mcqs.length * 60;
    _isLoading = true; // Start with loading state

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _startTimer();

    // Simulate initial loading
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _fadeController.dispose();
    _slideController.dispose();
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
    if (_currentIndex < widget.mcqs.length - 1 && !_isTransitioning) {
      _transitionToQuestion(_currentIndex + 1);
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0 && !_isTransitioning) {
      _transitionToQuestion(_currentIndex - 1);
    }
  }

  void _jumpToQuestion(int index) {
    if (index != _currentIndex && !_isTransitioning) {
      _transitionToQuestion(index);
    }
  }

  void _transitionToQuestion(int newIndex) async {
    setState(() => _isTransitioning = true);

    // Fade out current question
    await _fadeController.reverse();

    // Update index
    setState(() => _currentIndex = newIndex);

    // Slide in new question
    _slideController.reset();
    await Future.wait([
      _fadeController.forward(),
      _slideController.forward(),
    ]);

    setState(() => _isTransitioning = false);
    _scrollToCurrentQuestion();
  }

  void _scrollToCurrentQuestion() {
    Future.delayed(const Duration(milliseconds: 100), () {
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

  void _selectAnswer(String id) {
    if (_hasSubmitted || _isTransitioning) return;
    final optionIndex = int.parse(id.split('_')[1]) - 1;
    setState(() {
      userAnswers[_currentIndex] =
          userAnswers[_currentIndex] == optionIndex ? -1 : optionIndex;
    });
  }

  void _toggleReview(int index) {
    if (_hasSubmitted || _isTransitioning) return;
    setState(() {
      if (reviewedQuestions.contains(index)) {
        reviewedQuestions.remove(index);
      } else {
        reviewedQuestions.add(index);
      }
    });
  }

  void _onSwipe(DragEndDetails details) {
    if (_hasSubmitted || _isTransitioning) return;
    const double swipeThreshold = 100;
    if (details.primaryVelocity! < -swipeThreshold) {
      _nextQuestion();
    } else if (details.primaryVelocity! > swipeThreshold) {
      _previousQuestion();
    }
  }

  // Show submit confirmation dialog - keeping existing code
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
          title: const Text(
            'Submit Test?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatRow(Icons.check_circle, 'Attempted',
                    '$attemptedCount', Colors.green),
                const SizedBox(height: 8),
                _buildStatRow(Icons.radio_button_unchecked, 'Unattempted',
                    '$unattemptedCount', Colors.red),
                const SizedBox(height: 8),
                _buildStatRow(Icons.bookmark, 'For Review', '$reviewCount',
                    Colors.orange),
                const SizedBox(height: 8),
                _buildStatRow(
                    Icons.schedule, 'Time Left', timeLeft, Colors.blue),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel'),
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
                  borderRadius: BorderRadius.circular(8),
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

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Submit test - keeping existing logic
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Test ${widget.testNumber} - ${widget.subject}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Attempted: ${widget.mcqs.length - countUnansweredQuestions()}/$totalQuestions",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _timeRemaining < 60
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: _timeRemaining < 60
                            ? Colors.red
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(_timeRemaining),
                        style: TextStyle(
                          color: _timeRemaining < 60
                              ? Colors.red
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Question Area
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: _onSwipe,
              child:
                  _isLoading ? _buildLoadingShimmer() : _buildQuestionContent(),
            ),
          ),

          // Navigation Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavButton(
                  icon: Icons.arrow_back_ios,
                  label: ' ',
                  onPressed: _currentIndex > 0 && !_isTransitioning
                      ? _previousQuestion
                      : null,
                  color: Colors.blue,
                ),
                Text(
                  '${_currentIndex + 1} / ${widget.mcqs.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _buildNavButton(
                  icon: Icons.arrow_forward_ios,
                  label: ' ',
                  onPressed: _currentIndex < widget.mcqs.length - 1 &&
                          !_isTransitioning
                      ? _nextQuestion
                      : null,
                  color: Colors.blue,
                ),
                _buildNavButton(
                    icon: Icons.done,
                    label: "Submit",
                    onPressed: _hasSubmitted || _isTransitioning
                        ? null
                        : _showSubmitConfirmation,
                    color: Colors.green)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey.shade300,
        foregroundColor:
            onPressed != null ? Colors.white : Colors.grey.shade600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: onPressed != null ? 2 : 0,
      ),
    );
  }

  Widget _buildQuestionContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildQuestionCard(_currentIndex, widget.mcqs[_currentIndex]),
      ),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: child,
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question number and origin
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Question text placeholder
              Container(
                width: double.infinity,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 32),

              // Options placeholder
              for (int i = 0; i < 4; i++) ...[
                Container(
                  width: double.infinity,
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ],
          ),
        ),
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        originText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
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
                      selectedItemStyle: TeXViewStyle(
                        borderRadius: const TeXViewBorderRadius.all(8),
                        border: TeXViewBorder.all(
                          TeXViewBorderDecoration(
                            borderWidth: 2,
                            borderColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        margin: const TeXViewMargin.all(8),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                        padding: const TeXViewPadding.all(12),
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
                        padding: TeXViewPadding.all(12),
                      ),
                      onTap: _hasSubmitted ? null : _selectAnswer,
                    ),
                  ],
                ),
                style: const TeXViewStyle(
                  margin: TeXViewMargin.all(16),
                  padding: TeXViewPadding.all(16),
                  borderRadius: TeXViewBorderRadius.all(12),
                  backgroundColor: Colors.white,
                ),
                loadingWidgetBuilder: (context) => _buildTeXViewShimmer(),
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: reviewedQuestions.contains(index)
                    ? Colors.orange.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.bookmark,
                  color: reviewedQuestions.contains(index)
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                  size: 24,
                ),
                onPressed: () => _toggleReview(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeXViewShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question shimmer
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),

            // Options shimmer
            for (int i = 0; i < 4; i++) ...[
              Container(
                width: double.infinity,
                height: 40,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ],
        ),
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
          padding: TeXViewPadding.all(12),
          fontStyle: TeXViewFontStyle(fontSize: 14),
        ),
      ),
    );
  }
}
