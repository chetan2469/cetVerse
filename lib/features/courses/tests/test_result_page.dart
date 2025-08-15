import 'package:cet_verse/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'
    as webview_android;

class TestResultPage extends StatefulWidget {
  final List<Map<String, dynamic>> mcqs;
  final List<int> userAnswers;
  final int correctCount;
  final int unansweredCount;
  final String timeTaken;

  const TestResultPage({
    super.key,
    required this.mcqs,
    required this.userAnswers,
    required this.correctCount,
    required this.unansweredCount,
    required this.timeTaken,
  });

  @override
  State<TestResultPage> createState() => _TestResultPageState();
}

class _TestResultPageState extends State<TestResultPage> {
  int? _selectedQuestionIndex;
  bool _isQuestionRendered = false;
  bool _canViewResultInDetail = false;
  final Map<int, Widget> _renderedCache = {};
  bool _isWebViewInitialized = false;
  bool _isFirstOpen = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    WebViewPlatform.instance ??= webview_android.AndroidWebViewPlatform();
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isWebViewInitialized = true;
    });
    _simulateFirstOpen();
  }

  Future<void> _simulateFirstOpen() async {
    if (widget.mcqs.isEmpty) return;

    setState(() {
      _selectedQuestionIndex = 0;
      _isQuestionRendered = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _selectedQuestionIndex = null;
      _isQuestionRendered = false;
      _isFirstOpen = false;
    });
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

  String _getAnswerLetter(int index) {
    switch (index) {
      case 0:
        return 'A';
      case 1:
        return 'B';
      case 2:
        return 'C';
      case 3:
        return 'D';
      default:
        return 'A';
    }
  }

  Color _getStatusColor(int questionIndex) {
    final userAnswer = widget.userAnswers[questionIndex];
    final mcq = widget.mcqs[questionIndex];
    final correctIndex = _answerToIndex(mcq['answer'] ?? 'A');

    if (userAnswer == -1) {
      return Colors.orange;
    } else if (userAnswer == correctIndex) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText(int questionIndex) {
    final userAnswer = widget.userAnswers[questionIndex];
    final mcq = widget.mcqs[questionIndex];
    final correctIndex = _answerToIndex(mcq['answer'] ?? 'A');

    if (userAnswer == -1) {
      return 'UNATTEMPTED';
    } else if (userAnswer == correctIndex) {
      return 'CORRECT';
    } else {
      return 'WRONG';
    }
  }

  void _showQuestionDetails(int index) {
    setState(() {
      _selectedQuestionIndex = index;
      _isQuestionRendered = false; // Reset rendering state
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void _closeQuestionDetails() {
    setState(() {
      _selectedQuestionIndex = null;
      _isQuestionRendered = false;
    });
  }

  void _nextQuestionDetails() {
    if (_selectedQuestionIndex != null &&
        _selectedQuestionIndex! < widget.mcqs.length - 1) {
      _showQuestionDetails(_selectedQuestionIndex! + 1);
    }
  }

  void _previousQuestionDetails() {
    if (_selectedQuestionIndex != null && _selectedQuestionIndex! > 0) {
      _showQuestionDetails(_selectedQuestionIndex! - 1);
    }
  }

  void _onSwipeInDetails(DragEndDetails details) {
    const double swipeThreshold = 100;
    if (details.primaryVelocity! < -swipeThreshold) {
      _nextQuestionDetails();
    } else if (details.primaryVelocity! > swipeThreshold) {
      _previousQuestionDetails();
    }
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MyApp()),
      (route) => false, // This removes all routes
    );
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  Widget _buildQuestionDetails(int index) {
    if (!_isWebViewInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    try {
      final mcq = widget.mcqs[index];
      final userAnswer = widget.userAnswers[index];
      final correctIndex = _answerToIndex(mcq['answer'] ?? 'A');

      // Extract question data
      final questionMap = mcq['question'] as Map<String, dynamic>? ?? {};
      final String questionText =
          questionMap['text'] ?? 'No question provided.';
      final String questionImage = questionMap['image'] ?? '';

      // Extract options
      final optionsMap = mcq['options'] as Map<String, dynamic>? ?? {};
      final options = ['A', 'B', 'C', 'D'].map((letter) {
        final optionMap = optionsMap[letter] as Map<String, dynamic>? ?? {};
        return optionMap['text'] ?? '';
      }).toList();

      // Extract explanation
      final explanationMap = mcq['explanation'] as Map<String, dynamic>? ?? {};
      final String explanationText =
          explanationMap['text'] ?? 'No explanation provided.';
      final String explanationImage = explanationMap['image'] ?? '';

      // Combine text and image for question and explanation
      String finalQuestionText = "<b>Question ${index + 1}: </b>$questionText";
      if (questionImage.isNotEmpty) {
        finalQuestionText +=
            '<br/><img src="$questionImage" width="200" height="40"/>';
      }
      String finalExplanationText = "<b>Explanation: </b>$explanationText";
      if (explanationImage.isNotEmpty) {
        finalExplanationText +=
            '<br/><img src="$explanationImage" width="200" height="40"/>';
      }

      // Map correct answer to option ID
      final String correctOptionId = 'id_${correctIndex + 1}';
      final String userAnswerId =
          userAnswer != -1 ? 'id_${userAnswer + 1}' : '';

      final questionWidget = GestureDetector(
        onHorizontalDragEnd: _onSwipeInDetails,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(
                    top: 16, left: 16, right: 16, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TeXView(
                  child: TeXViewColumn(
                    children: [
                      TeXViewDocument(
                        finalQuestionText,
                        style: TeXViewStyle(
                          textAlign: TeXViewTextAlign.left,
                          fontStyle: TeXViewFontStyle(
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: TeXViewFontWeight.w500,
                          ),
                          padding: TeXViewPadding.all(12),
                        ),
                      ),
                      TeXViewGroup(
                        children: [
                          _buildOption('id_1', 'A', options[0], correctOptionId,
                              userAnswerId),
                          _buildOption('id_2', 'B', options[1], correctOptionId,
                              userAnswerId),
                          _buildOption('id_3', 'C', options[2], correctOptionId,
                              userAnswerId),
                          _buildOption('id_4', 'D', options[3], correctOptionId,
                              userAnswerId),
                        ],
                        selectedItemStyle: TeXViewStyle(
                          borderRadius: const TeXViewBorderRadius.all(10),
                          border: TeXViewBorder.all(
                            TeXViewBorderDecoration(
                              borderWidth: 1,
                              borderColor: userAnswerId.isNotEmpty
                                  ? (userAnswerId == correctOptionId
                                      ? Colors.green[600]!
                                      : Colors.red[600]!)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          margin: const TeXViewMargin.all(6),
                          backgroundColor: userAnswerId.isNotEmpty
                              ? (userAnswerId == correctOptionId
                                  ? Colors.green[50]!
                                  : Colors.red[50]!)
                              : Colors.grey[50]!,
                        ),
                        normalItemStyle: const TeXViewStyle(
                          margin: TeXViewMargin.all(6),
                          borderRadius: TeXViewBorderRadius.all(10),
                          border: TeXViewBorder.all(
                            TeXViewBorderDecoration(
                              borderWidth: 1,
                              borderColor: Colors.grey,
                            ),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        onTap: (String id) {},
                      ),
                      TeXViewDocument(
                        finalExplanationText,
                        style: TeXViewStyle(
                          textAlign: TeXViewTextAlign.left,
                          fontStyle: TeXViewFontStyle(
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: TeXViewFontWeight.w400,
                          ),
                          padding: TeXViewPadding.all(12),
                        ),
                      ),
                    ],
                  ),
                  style: const TeXViewStyle(
                    margin: TeXViewMargin.all(0),
                    padding: TeXViewPadding.all(12),
                    borderRadius: TeXViewBorderRadius.all(8),
                    backgroundColor: Colors.white,
                  ),
                  loadingWidgetBuilder: (context) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                      strokeWidth: 2,
                    ),
                  ),
                  onRenderFinished: (height) {
                    setState(() {
                      _isQuestionRendered = true;
                    });
                  },
                ),
              ),
            ),
            if (!_isQuestionRendered)
              Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                ),
              ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: _closeQuestionDetails,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
      );

      _renderedCache[index] = questionWidget;
      return questionWidget;
    } catch (e) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
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
        child: const Text(
          'Error rendering question details. Please try again.',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
  }

  TeXViewGroupItem _buildOption(String id, String label, String content,
      String correctOptionId, String userAnswerId) {
    return TeXViewGroupItem(
      id: id,
      child: TeXViewDocument(
        "<b>$label: </b>$content",
        style: TeXViewStyle(
          padding: const TeXViewPadding.all(8),
          fontStyle: TeXViewFontStyle(fontSize: 14),
          border: TeXViewBorder.all(
            TeXViewBorderDecoration(
              borderWidth: 2,
              borderColor: id == correctOptionId
                  ? Colors.green[300]!
                  : (id == userAnswerId && id != correctOptionId
                      ? Colors.red[300]!
                      : Colors.transparent),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = widget.mcqs.length;
    final attemptedCount = totalQuestions - widget.unansweredCount;
    final wrongCount = attemptedCount - widget.correctCount;
    final accuracy =
        (widget.correctCount / attemptedCount * 100).toStringAsFixed(1);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text(
            "Test Result",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.blue),
              onPressed: _goToHome,
              tooltip: 'Go to Home',
            ),
          ],
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scorecard',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Accuracy: $accuracy%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        '${widget.correctCount}/$totalQuestions',
                        'Score',
                        Colors.blue,
                        Icons.star,
                      ),
                      _buildStatCard(
                        '${widget.timeTaken}',
                        'Time Left',
                        Colors.purple,
                        Icons.timer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        widget.correctCount.toString(),
                        'Correct',
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildStatItem(
                        wrongCount.toString(),
                        'Wrong',
                        Colors.red,
                        Icons.cancel,
                      ),
                      _buildStatItem(
                        widget.unansweredCount.toString(),
                        'Unattempted',
                        Colors.orange,
                        Icons.help_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedQuestionIndex == null
                  ? Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.touch_app,
                              size: 20, color: Colors.grey),
                          title: Text(
                            'Tap on any question to view details',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          trailing: Switch(
                            value: _canViewResultInDetail,
                            onChanged: (value) {
                              setState(() {
                                _canViewResultInDetail = value;
                              });
                            },
                            activeColor: Colors.blue,
                            inactiveThumbColor: Colors.grey,
                          ),
                        ),
                        if (!_canViewResultInDetail)
                          Container()
                        else
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: totalQuestions,
                              itemBuilder: (context, index) {
                                final color = _getStatusColor(index);
                                return InkWell(
                                  onTap: () => _showQuestionDetails(index),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: color, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.01),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: color,
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
                      ],
                    )
                  : _buildQuestionDetails(_selectedQuestionIndex!),
            ),
            Offstage(
              offstage: true,
              child: TeXView(
                child: TeXViewDocument(r"<h1>Initializing TeXView...</h1>"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String count, String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
