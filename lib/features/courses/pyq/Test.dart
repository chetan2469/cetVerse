import 'dart:async';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cet_verse/courses/TimerController.dart';
import 'package:cet_verse/courses/TimerWidget.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
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

class _TestState extends State<Test> with TickerProviderStateMixin {
  List<int> userAnswers = [];
  Set<int> reviewedQuestions = {};
  int _currentIndex = 0;
  bool _hasSubmitted = false;
  bool _isTransitioning = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _mcqs = [];
  List<Map<String, dynamic>> _filteredMcqs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, Widget> _questionCache = {}; // Keep question cache
  final TimerController _timerController = TimerController();
  String _selectedSubject = 'All';
  bool _hasConfirmedStart = false;

  // Animation controllers - simplified
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    // Only keep loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _loadingController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartConfirmation();
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.purple.shade50,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.purple.shade400
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'MHT CET ${widget.year}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.pyqType.toUpperCase()} Test',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildModernStatColumn('$totalQuestions', 'Questions',
                              Icons.quiz, Colors.blue),
                          _buildModernStatColumn('180 min', 'Duration',
                              Icons.schedule, Colors.green),
                          _buildModernStatColumn(
                              '200', 'Marks', Icons.star, Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade600, size: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Test Instructions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildModernInstruction(
                        Icons.timer,
                        'Auto-submit when time expires',
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildModernInstruction(
                        Icons.radio_button_checked,
                        'Multiple choice questions with single correct answer',
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildModernInstruction(
                        Icons.pause_circle_outline,
                        'Test cannot be paused for fair ranking',
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _hasConfirmedStart = true);
                      _fetchMcqs();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Start Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernStatColumn(
      String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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

  Widget _buildModernInstruction(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
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

      _mcqs.sort(
          (a, b) => int.parse(a['docId']).compareTo(int.parse(b['docId'])));

      setState(() {
        if (_mcqs.isEmpty) {
          _errorMessage = 'No MCQs found for ${widget.docId}';
        } else {
          userAnswers = List<int>.filled(_mcqs.length, -1);
          _filteredMcqs = _mcqs;
          _timerController.initialize(10800, _submitTest);
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
    if (_isTransitioning) return;

    setState(() {
      _selectedSubject = subject;
      _questionCache.clear(); // Clear cache when filtering
      if (subject == 'All') {
        _filteredMcqs = List.from(_mcqs);
      } else {
        _filteredMcqs =
            _mcqs.where((mcq) => mcq['subject'] == subject).toList();
      }
      _currentIndex = _filteredMcqs.isNotEmpty ? 0 : -1;
    });

    if (_filteredMcqs.isNotEmpty) {
      _scrollToCurrentQuestion();
    }
  }

  // Simplified navigation without animations
  void _nextQuestion() {
    if (_currentIndex < _filteredMcqs.length - 1 && !_isTransitioning) {
      setState(() {
        _currentIndex++;
      });
      _scrollToCurrentQuestion();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0 && !_isTransitioning) {
      setState(() {
        _currentIndex--;
      });
      _scrollToCurrentQuestion();
    }
  }

  void _jumpToQuestion(int originalIndex) {
    if (originalIndex < 0 || originalIndex >= _mcqs.length || _isTransitioning)
      return;

    final targetMcq = _mcqs[originalIndex];
    int filteredIndex = _filteredMcqs.indexOf(targetMcq);

    if (filteredIndex != -1) {
      setState(() {
        _currentIndex = filteredIndex;
      });
      _scrollToCurrentQuestion();
    } else {
      final subject = targetMcq['subject'] as String? ?? 'All';
      _filterQuestions(subject);
      filteredIndex = _filteredMcqs.indexOf(targetMcq);
      if (filteredIndex != -1) {
        setState(() {
          _currentIndex = filteredIndex;
        });
        _scrollToCurrentQuestion();
      }
    }
  }

  void _scrollToCurrentQuestion() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && _currentIndex >= 0) {
        final double itemWidth = 48.0;
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

    // Update only the answer, don't rebuild the entire widget
    final originalIndex = _mcqs.indexOf(_filteredMcqs[_currentIndex]);
    if (originalIndex != -1) {
      if (userAnswers[originalIndex] == optionIndex) {
        userAnswers[originalIndex] = -1;
      } else {
        userAnswers[originalIndex] = optionIndex;
      }

      // Only update the specific question cache, not rebuild
      _questionCache.remove(_currentIndex);

      // Minimal state update to avoid rebuild
      if (mounted) {
        setState(() {
          // Just trigger a minimal rebuild for answer selection
        });
      }
    }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Submit Test?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                _buildSubmitStatRow(Icons.check_circle, 'Attempted',
                    '$attemptedCount', Colors.green),
                const SizedBox(height: 8),
                _buildSubmitStatRow(Icons.radio_button_unchecked, 'Unattempted',
                    '$unattemptedCount', Colors.red),
                const SizedBox(height: 8),
                _buildSubmitStatRow(Icons.bookmark, 'For Review',
                    '$reviewCount', Colors.orange),
                const SizedBox(height: 8),
                _buildSubmitStatRow(
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

  Widget _buildSubmitStatRow(
      IconData icon, String label, String value, Color color) {
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
      if (subject == null) continue;

      subjectBreakdown[subject] ??= {'correct': 0, 'incorrect': 0};

      if (userAnswers[i] == -1) {
        unansweredCount++;
        continue;
      }
      final correctIndex = _answerToIndex(mcq['answer'] as String? ?? "A");
      if (userAnswers[i] == correctIndex) {
        correctCount++;
        if (widget.pyqType.toLowerCase() == 'pcm' && subject == 'Maths') {
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
      });
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
    if (_hasSubmitted || _isTransitioning) return;

    final originalIndex = _mcqs.indexOf(_filteredMcqs[index]);
    if (originalIndex != -1) {
      if (reviewedQuestions.contains(originalIndex)) {
        reviewedQuestions.remove(originalIndex);
      } else {
        reviewedQuestions.add(originalIndex);
      }

      // Minimal state update
      if (mounted) {
        setState(() {
          // Just trigger update for review status
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final isPcm = widget.pyqType.toLowerCase() == 'pcm';
    final attemptedCount = userAnswers.where((answer) => answer != -1).length;
    final totalQuestions =
        _mcqs.isNotEmpty ? _mcqs.length : (isPcm ? 150 : 200);

    return Scaffold(
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ),
        title: Text(
          'PYQ ${widget.year} Test',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        actions: [
          if (!_isLoading && _mcqs.isNotEmpty && _hasConfirmedStart)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TimerWidget(controller: _timerController),
            ),
        ],
      ),
      body: !_hasConfirmedStart
          ? _buildWaitingScreen()
          : _isLoading
              ? _buildLoadingScreen()
              : _errorMessage != null
                  ? _buildErrorScreen()
                  : _buildMainContent(
                      scaffoldKey, isPcm, attemptedCount, totalQuestions),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: _hasSubmitted || _isTransitioning
              ? null
              : _showSubmitConfirmation,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.check),
          label: const Text(
            'Submit Test',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Please confirm to start the test',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(
                        4,
                        (index) => Expanded(
                              child: Container(
                                height: 40,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
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
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading Questions...',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMcqs,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(GlobalKey<ScaffoldState> scaffoldKey, bool isPcm,
      int attemptedCount, int totalQuestions) {
    return Column(
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
                    'Attempted: $attemptedCount/$totalQuestions',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
                ),
              ),
            ],
          ),
        ),

        // Subject Filter
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
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

        // Question Content - Remove animations, use direct widget
        Expanded(
          child: _filteredMcqs.isNotEmpty &&
                  _currentIndex >= 0 &&
                  _currentIndex < _filteredMcqs.length
              ? GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (_hasSubmitted || _isTransitioning) return;
                    const double swipeThreshold = 100;
                    if (details.primaryVelocity! < -swipeThreshold) {
                      _nextQuestion();
                    } else if (details.primaryVelocity! > swipeThreshold) {
                      _previousQuestion();
                    }
                  },
                  child: PyqQuestionCard(
                    key: ValueKey(
                        'question_${_filteredMcqs[_currentIndex]['docId']}'), // Stable key
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
                    'No questions available for selected filter',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
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
                label: 'Previous',
                onPressed: _currentIndex > 0 && !_isTransitioning
                    ? _previousQuestion
                    : null,
                color: Colors.blue,
              ),
              Text(
                '${_currentIndex + 1} / ${_filteredMcqs.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              _buildNavButton(
                icon: Icons.arrow_forward_ios,
                label: 'Next',
                onPressed: _currentIndex < _filteredMcqs.length - 1 &&
                        !_isTransitioning
                    ? _nextQuestion
                    : null,
                color: Colors.blue,
              ),
            ],
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

  Widget _buildFilterButton(String subject) {
    final isSelected = _selectedSubject == subject;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: _hasSubmitted || _isTransitioning
              ? null
              : () => _filterQuestions(subject),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}
