// PyqQuestionCard.dart
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class PyqQuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> mcq;
  final List<int> userAnswers;
  final bool hasSubmitted;
  final Function(String) onSelectAnswer;
  final Set<int> reviewedQuestions;
  final Function(int) onToggleReview;
  final Function() nextQuestion;
  final Function() prevQuestion;
  final List<Map<String, dynamic>> originalMcqs;

  const PyqQuestionCard({
    super.key,
    required this.index,
    required this.mcq,
    required this.userAnswers,
    required this.hasSubmitted,
    required this.onSelectAnswer,
    required this.reviewedQuestions,
    required this.onToggleReview,
    required this.nextQuestion,
    required this.prevQuestion,
    required this.originalMcqs,
  });

  @override
  Widget build(BuildContext context) {
    final originalIndex = originalMcqs.indexOf(mcq);

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

    String finalQuestionText = "<b>Q${mcq['docId']}: </b>$questionText";
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
                key: ValueKey("quiz_${mcq['docId']}"),
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
                        _buildOption(originalIndex, "id_1", "A", finalAText),
                        _buildOption(originalIndex, "id_2", "B", finalBText),
                        _buildOption(originalIndex, "id_3", "C", finalCText),
                        _buildOption(originalIndex, "id_4", "D", finalDText),
                      ],
                      onTap: hasSubmitted ? null : onSelectAnswer,
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
                loadingWidgetBuilder: (context) => const SizedBox.shrink(),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.bookmark,
                color: reviewedQuestions.contains(originalIndex)
                    ? const Color.fromARGB(255, 228, 210, 42)
                    : Colors.grey,
                size: 24,
              ),
              onPressed: () => onToggleReview(originalIndex),
            ),
          ),
          // Swipe indicators
          if (index > 0)
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
          if (index < originalMcqs.length - 1)
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

  TeXViewGroupItem _buildOption(
      int originalIndex, String id, String label, String content) {
    final isSelected =
        userAnswers[originalIndex] == int.parse(id.split('_')[1]) - 1;
    return TeXViewGroupItem(
      rippleEffect: true,
      id: id,
      child: TeXViewDocument(
        "<b>$label: </b>$content",
        style: isSelected
            ? TeXViewStyle(
                borderRadius: TeXViewBorderRadius.all(8),
                border: TeXViewBorder.all(
                  TeXViewBorderDecoration(
                    borderWidth: 2,
                    borderColor: Colors.blue,
                  ),
                ),
                margin: TeXViewMargin.all(8),
                backgroundColor: Colors.transparent,
                padding: TeXViewPadding.all(10),
                fontStyle: TeXViewFontStyle(fontSize: 14),
              )
            : TeXViewStyle(
                margin: const TeXViewMargin.all(8),
                borderRadius: const TeXViewBorderRadius.all(8),
                border: const TeXViewBorder.all(
                  TeXViewBorderDecoration(
                    borderWidth: 1,
                    borderColor: Colors.grey,
                  ),
                ),
                backgroundColor: Colors.white,
                padding: const TeXViewPadding.all(10),
                fontStyle: TeXViewFontStyle(fontSize: 14),
              ),
      ),
    );
  }
}
