import 'package:flutter/material.dart';

class QuestionTestPage extends StatefulWidget {
  final String level;
  final String subject;
  final String chapter;
  final int testNumber;
  final List<Map<String, dynamic>> mcqs;

  /// We assume mcqs is up to 20 questions for a single test.
  const QuestionTestPage({
    super.key,
    required this.level,
    required this.subject,
    required this.chapter,
    required this.testNumber,
    required this.mcqs,
  });

  @override
  State<QuestionTestPage> createState() => _QuestionTestPageState();
}

class _QuestionTestPageState extends State<QuestionTestPage> {
  late PageController _pageController;

  /// Tracks user’s selected option for each question: -1 if none selected, else 0..3 for op1..op4.
  late List<int> userAnswers;

  int _currentIndex = 0; // Current question
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    userAnswers =
        List<int>.filled(widget.mcqs.length, -1); // -1 => not answered
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Next question
  void _nextQuestion() {
    if (_currentIndex < widget.mcqs.length - 1) {
      setState(() => _currentIndex++);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Previous question
  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Jump to question i
  void _jumpToQuestion(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  /// Select an answer for current question
  void _selectAnswer(int questionIndex, int optionIndex) {
    if (_hasSubmitted) return; // If test is submitted, no changes
    setState(() => userAnswers[questionIndex] = optionIndex);
  }

  /// Submit test -> calculate result -> navigate to TestResult page
  void _submitTest() {
    if (_hasSubmitted) return;
    setState(() => _hasSubmitted = true);

    // Calculate how many correct and how many unanswered
    int correctCount = 0;
    int unansweredCount = 0;

    for (int i = 0; i < widget.mcqs.length; i++) {
      if (userAnswers[i] == -1) {
        unansweredCount++;
        continue;
      }
      final mcq = widget.mcqs[i];
      final correctIndex = _convertKeyToIndex(mcq['ans'] ?? "");
      if (userAnswers[i] == correctIndex) {
        correctCount++;
      }
    }

    // Navigate to TestResult page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestResult(
          mcqs: widget.mcqs,
          userAnswers: userAnswers,
          correctCount: correctCount,
          unansweredCount: unansweredCount,
        ),
      ),
    );
  }

  /// Convert "op1"/"op2"/"op3"/"op4" => 0..3
  int _convertKeyToIndex(String key) {
    switch (key) {
      case 'op1':
        return 0;
      case 'op2':
        return 1;
      case 'op3':
        return 2;
      case 'op4':
        return 3;
      default:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mcqs = widget.mcqs;
    final totalQuestions = mcqs.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Test #${widget.testNumber} - ${widget.subject}"),
        centerTitle: true,
      ),
      body: mcqs.isEmpty
          ? const Center(child: Text("No questions available."))
          : Column(
              children: [
                // Horizontal row of question boxes
                Container(
                  height: 40,
                  color: Colors.grey[100],
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: totalQuestions,
                    itemBuilder: (context, index) {
                      final isAnswered = userAnswers[index] != -1;
                      final isCurrent = index == _currentIndex;
                      return _buildQuestionBox(index, isAnswered, isCurrent);
                    },
                  ),
                ),

                // PageView for actual questions
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemCount: totalQuestions,
                    itemBuilder: (context, index) {
                      final questionData = mcqs[index];
                      return _buildQuestionCard(index, questionData);
                    },
                  ),
                ),

                _buildBottomNav(totalQuestions),
              ],
            ),
    );
  }

  Widget _buildQuestionBox(int index, bool isAnswered, bool isCurrent) {
    final color = isAnswered ? Colors.green : Colors.grey[300];
    final borderColor = isCurrent ? Colors.blue : Colors.transparent;

    return GestureDetector(
      onTap: () => _jumpToQuestion(index),
      child: Container(
        width: 30,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          "${index + 1}",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> mcq) {
    final questionText = mcq['question'] ?? "No question provided";
    final options = [mcq['op1'], mcq['op2'], mcq['op3'], mcq['op4']];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                "Q${index + 1}. $questionText",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < options.length; i++)
                _buildOption(
                  questionIndex: index,
                  optionIndex: i,
                  optionText: options[i] ?? "",
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required int questionIndex,
    required int optionIndex,
    required String optionText,
  }) {
    final isSelected = userAnswers[questionIndex] == optionIndex;

    return InkWell(
      onTap: () => _selectAnswer(questionIndex, optionIndex),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildOptionCircle(isSelected, optionIndex),
            const SizedBox(width: 8),
            Expanded(
              child: Text(optionText, style: const TextStyle(fontSize: 14)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCircle(bool isSelected, int optionIndex) {
    final labels = ["A", "B", "C", "D"];
    final label = (optionIndex >= 0 && optionIndex < labels.length)
        ? labels[optionIndex]
        : "?";

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(int totalQuestions) {
    final isFirstQuestion = _currentIndex == 0;
    final isLastQuestion = _currentIndex == totalQuestions - 1;

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: isFirstQuestion ? null : _previousQuestion,
            child: const Text("Prev"),
          ),
          const Spacer(),
          isLastQuestion
              ? ElevatedButton(
                  onPressed: _hasSubmitted ? null : _submitTest,
                  child: const Text("Submit"),
                )
              : ElevatedButton(
                  onPressed: _nextQuestion,
                  child: const Text("Next"),
                )
        ],
      ),
    );
  }
}

/// TestResult page

class TestResult extends StatelessWidget {
  final List<Map<String, dynamic>> mcqs;
  final List<int> userAnswers; // 0..3 or -1
  final int correctCount;
  final int unansweredCount;

  const TestResult({
    super.key,
    required this.mcqs,
    required this.userAnswers,
    required this.correctCount,
    required this.unansweredCount,
  });

  @override
  Widget build(BuildContext context) {
    final totalQuestions = mcqs.length;
    final wrongCount = totalQuestions - correctCount - unansweredCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Result"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            // Summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text("Total Questions: $totalQuestions",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("Correct: $correctCount",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.green)),
                    Text("Wrong: $wrongCount",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.red)),
                    Text("Unanswered: $unansweredCount",
                        style: const TextStyle(
                            fontSize: 16, color: Colors.orange)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Detailed question list
            ...List.generate(mcqs.length, (index) {
              final mcq = mcqs[index];
              final userIndex = userAnswers[index]; // 0..3 or -1
              final correctIndex = _convertKeyToIndex(mcq['ans'] ?? "");
              return _buildResultCard(index, mcq, userIndex, correctIndex);
            }),
          ],
        ),
      ),
    );
  }

  /// Convert "op1"/"op2"/"op3"/"op4" => 0..3
  int _convertKeyToIndex(String key) {
    switch (key) {
      case 'op1':
        return 0;
      case 'op2':
        return 1;
      case 'op3':
        return 2;
      case 'op4':
        return 3;
      default:
        return -1;
    }
  }

  /// Build a card showing question, user answer, correct answer
  Widget _buildResultCard(
    int index,
    Map<String, dynamic> mcq,
    int userIndex,
    int correctIndex,
  ) {
    final questionText = mcq['question'] ?? "No question";
    final explanation = mcq['explanation'] ?? "No explanation.";
    final options = [mcq['op1'], mcq['op2'], mcq['op3'], mcq['op4']];

    // "A/B/C/D" labels
    final labels = ["A", "B", "C", "D"];

    // Determine user answer text or "Unanswered"
    String userAnswerText = "Unanswered";
    if (userIndex >= 0 && userIndex < options.length) {
      userAnswerText = "${labels[userIndex]}. ${options[userIndex]}";
    }
    // Correct answer text
    String correctAnswerText = "None";
    if (correctIndex >= 0 && correctIndex < options.length) {
      correctAnswerText = "${labels[correctIndex]}. ${options[correctIndex]}";
    }

    // Color logic for result
    Color resultColor;
    if (userIndex == -1) {
      resultColor = Colors.orange.shade100; // Unanswered
    } else if (userIndex == correctIndex) {
      resultColor = Colors.green.shade100; // Correct
    } else {
      resultColor = Colors.red.shade100; // Wrong
    }

    return Card(
      color: resultColor,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q${index + 1}: $questionText",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Your Answer: $userAnswerText"),
            Text("Correct Answer: $correctAnswerText",
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text("Explanation: $explanation"),
          ],
        ),
      ),
    );
  }
}
