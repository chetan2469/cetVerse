// PyqQuestionCard2.dart
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:provider/provider.dart';

import 'test_provider.dart';

class PyqQuestionCard2 extends StatelessWidget {
  final int index;

  const PyqQuestionCard2({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final testProvider = Provider.of<TestProvider>(context, listen: false);

    // Select the current question and original index
    final mcq = context.select((TestProvider p) => p.filteredMcqs[index]);
    final originalIndex =
        context.select((TestProvider p) => p.mcqs.indexOf(mcq));
    final hasSubmitted = context.select((TestProvider p) => p.hasSubmitted);
    final isReviewed = context.select(
        (TestProvider p) => p.reviewedQuestions.contains(originalIndex));

    // Extract question and option data
    final questionMap = mcq['question'] as Map<String, dynamic>? ?? {};
    final String questionText = questionMap['text'] ?? 'No question provided.';
    final String questionImage = questionMap['image'] ?? '';
    // final String originText = mcq['origin'] ?? '-';
    final optionsMap = mcq['options'] as Map<String, dynamic>? ?? {};

    final Map<String, dynamic> optionA =
        optionsMap['A'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionB =
        optionsMap['B'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionC =
        optionsMap['C'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> optionD =
        optionsMap['D'] as Map<String, dynamic>? ?? {};

    // Build final question and options with images
    String finalQuestionText = "<b>Q${mcq['docId']}: </b>$questionText";
    if (questionImage.isNotEmpty) {
      finalQuestionText +=
          '<br/><img src="$questionImage" width=300 height=150/>';
    }

    String finalAText = optionA['text'] ?? '';
    if ((optionA['image'] ?? '').isNotEmpty) {
      finalAText +=
          '<br/><img src="${optionA['image']}" width=300 height=150/>';
    }

    String finalBText = optionB['text'] ?? '';
    if ((optionB['image'] ?? '').isNotEmpty) {
      finalBText +=
          '<br/><img src="${optionB['image']}" width=300 height=150/>';
    }

    String finalCText = optionC['text'] ?? '';
    if ((optionC['image'] ?? '').isNotEmpty) {
      finalCText +=
          '<br/><img src="${optionC['image']}" width=300 height=150/>';
    }

    String finalDText = optionD['text'] ?? '';
    if ((optionD['image'] ?? '').isNotEmpty) {
      finalDText += '<br/><img src="${optionD['image']}" width=300 height=60/>';
    }

    return Container(
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
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Selector<TestProvider, int>(
              selector: (_, provider) {
                if (originalIndex < 0 ||
                    originalIndex >= provider.userAnswers.length) return -1;
                return provider.userAnswers[originalIndex];
              },
              builder: (context, selectedAnswerIndex, _) {
                return TeXView(
                  onRenderFinished: (height) {},
                  key: ValueKey("quiz_${mcq['docId']}"),
                  // style: const TeXViewStyle.fromCSS("""
                  //   *::-webkit-scrollbar {
                  //     display: none;
                  //   }
                  //   * {
                  //     -ms-overflow-style: none;  /* IE and Edge */
                  //     scrollbar-width: none;     /* Firefox */
                  //   }
                  // """),
                  child: TeXViewColumn(
                    children: [
                      TeXViewDocument(
                        finalQuestionText,
                        style: TeXViewStyle(
                            textAlign: TeXViewTextAlign.left,
                            fontStyle: TeXViewFontStyle(fontSize: 16),
                            padding: TeXViewPadding.all(16)),
                      ),
                      TeXViewGroup(
                        children: [
                          _buildOption("id_1", "A", finalAText,
                              selectedAnswerIndex == 0),
                          _buildOption("id_2", "B", finalBText,
                              selectedAnswerIndex == 1),
                          _buildOption("id_3", "C", finalCText,
                              selectedAnswerIndex == 2),
                          _buildOption("id_4", "D", finalDText,
                              selectedAnswerIndex == 3),
                        ],
                        onTap: hasSubmitted ? null : testProvider.selectAnswer,
                      ),
                    ],
                  ),
                  style: const TeXViewStyle(
                    margin: TeXViewMargin.only(top: 8),
                    padding: TeXViewPadding.all(5),
                    backgroundColor: Colors.white,
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: -8,
            right: 2,
            child: IconButton(
              icon: Icon(
                Icons.bookmark,
                color: isReviewed ? Colors.yellow.shade700 : Colors.grey,
                size: 24,
              ),
              onPressed: () => testProvider.toggleReview(),
            ),
          ),
        ],
      ),
    );
  }

  TeXViewGroupItem _buildOption(
      String id, String label, String content, bool isSelected) {
    return TeXViewGroupItem(
      id: id,
      rippleEffect: true,
      child: TeXViewDocument(
        "<b>$label: </b>$content",
        style: isSelected
            ? TeXViewStyle(
                borderRadius: TeXViewBorderRadius.all(8),
                border: TeXViewBorder.all(TeXViewBorderDecoration(
                    borderWidth: 2, borderColor: Colors.blue)),
                margin: TeXViewMargin.all(4),
                backgroundColor: Colors.transparent,
                padding: TeXViewPadding.all(12),
                fontStyle: TeXViewFontStyle(fontSize: 14),
              )
            : TeXViewStyle(
                margin: const TeXViewMargin.all(8),
                borderRadius: const TeXViewBorderRadius.all(8),
                border: const TeXViewBorder.all(TeXViewBorderDecoration(
                  borderWidth: 1,
                  borderColor: Colors.grey,
                )),
                backgroundColor: Colors.white,
                padding: const TeXViewPadding.all(12),
                fontStyle: TeXViewFontStyle(fontSize: 14),
              ),
      ),
    );
  }
}
