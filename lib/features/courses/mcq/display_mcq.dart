import 'package:cet_verse/ui/latex/quiz.dart';
import 'package:cet_verse/ui/latex/tex_view_simplified.dart';
import 'package:flutter/material.dart';

import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter_tex/flutter_tex.dart';

class QuizOption {
  final String id;
  final String option;

  QuizOption(this.id, this.option);
}

/// A page to display a single MCQ with LaTeX rendering for question, options, and explanation.
class DisplayMcq extends StatelessWidget {
  final Map<String, dynamic> mcq;

  const DisplayMcq({super.key, required this.mcq});

  // Paper theme colors
  static const Color _paperBackground = Color(0xFFF8F5F0); // Creamy paper color
  static const Color _cardColor = Color(0xFFFFFEFA); // Slightly off-white
  static const Color _textColor = Color(0xFF3E2723); // Dark brown for text
  static const Color _accentColor = Color(0xFF8D6E63); // Muted brown
  static const Color _correctColor = Color(0xFF66BB6A); // Soft green
  static const Color _dividerColor = Color(0xFFD7CCC8); // Light brown

  @override
  Widget build(BuildContext context) {
    // Extract MCQ data with null safety
    final questionMap = mcq['question'] as Map<String, dynamic>? ?? {};
    final String questionText = questionMap['text'] ?? 'No question provided.';
    final String questionImage = questionMap['image'] ?? '';

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

    final String answer = mcq['answer'] ?? 'A';
    final explanationMap = mcq['explanation'] as Map<String, dynamic>? ?? {};
    final String explanationText =
        explanationMap['text'] ?? 'No explanation provided.';
    final String explanationImage = explanationMap['image'] ?? '';

    return Scaffold(
      backgroundColor: _paperBackground,
      appBar: _buildAppBar(),
      body: _buildBody(
        context,
        questionText: questionText,
        questionImage: questionImage,
        aText: aText,
        aImage: aImage,
        bText: bText,
        bImage: bImage,
        cText: cText,
        cImage: cImage,
        dText: dText,
        dImage: dImage,
        answer: answer,
        explanationText: explanationText,
        explanationImage: explanationImage,
      ),
    );
  }

  /// Builds the AppBar with paper theme styling.
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'MCQ Details',
        style: TextStyle(
          color: _textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: _cardColor,
      elevation: 0, // Removed shadow
      iconTheme: const IconThemeData(color: _textColor),
    );
  }

  /// Builds the main body with paper theme styling, utilizing maximum space.
  Widget _buildBody(
    BuildContext context, {
    required String questionText,
    required String questionImage,
    required String aText,
    required String aImage,
    required String bText,
    required String bImage,
    required String cText,
    required String cImage,
    required String dText,
    required String dImage,
    required String answer,
    required String explanationText,
    required String explanationImage,
  }) {
    String finalQuestionText = questionText;
    if (questionImage.isNotEmpty) {
      finalQuestionText +=
          r'<br/><img src="' + questionImage + r'" width=300 height=60/>';
    }

    // Append images to options if their image strings are not empty
    String finalAText = aText;
    if (aImage.isNotEmpty) {
      finalAText += r'<br/><img src="' + aImage + r'" width=300 height=60/>';
    }

    String finalBText = bText;
    if (bImage.isNotEmpty) {
      finalBText += r'<br/><img src="' + bImage + r'" width=300 height=60/>';
    }

    String finalCText = cText;
    if (cImage.isNotEmpty) {
      finalCText += r'<br/><img src="' + cImage + r'" width=300 height=60/>';
    }

    String finalDText = dText;
    if (dImage.isNotEmpty) {
      finalDText += r'<br/><img src="' + dImage + r'" width=300 height=60/>';
    }

    String finalExplaination = explanationText;
    if (explanationImage.isNotEmpty) {
      finalExplaination +=
          r'<br/><img src="' + explanationImage + r'" width=300 height=60/>';
    }

    // Map answer to correctOptionId
    String correctOptionId;
    switch (answer) {
      case 'A':
        correctOptionId = 'id_1';
        break;
      case 'B':
        correctOptionId = 'id_2';
        break;
      case 'C':
        correctOptionId = 'id_3';
        break;
      case 'D':
        correctOptionId = 'id_4';
        break;
      default:
        correctOptionId = 'id_1'; // Fallback to A
    }

    return TeXViewQuizExample(
      statement: finalQuestionText,
      option1: finalAText,
      option2: finalBText,
      option3: finalCText,
      option4: finalDText,
      correctOptionId: correctOptionId,
      explaination: finalExplaination,
      paperThemeColors: const PaperThemeColors(
        backgroundColor: _cardColor,
        textColor: _textColor,
        accentColor: _accentColor,
        correctColor: _correctColor,
        dividerColor: _dividerColor,
      ),
    );
  }

  Widget _latexView(String val) {
    return TeXView(
      loadingWidgetBuilder: (context) => Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        ),
      ),
      child: TeXViewDocument(
        val,
        style: TeXViewStyle(
          padding: TeXViewPadding.all(0), // Removed padding
          textAlign: TeXViewTextAlign.left,
          backgroundColor: _cardColor,
          fontStyle: TeXViewFontStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _textColor,
        ),
      ),
    );
  }

  /// Builds an option row with paper theme styling, utilizing maximum space.
  Widget _buildOptionRow(
    String label,
    String text,
    String imageUrl,
    String correctAnswer,
  ) {
    final bool isCorrect = label == correctAnswer;
    final bool hasText = text.isNotEmpty;
    final bool hasImage = imageUrl.isNotEmpty;

    // Return an empty widget if neither text nor image is present
    if (!hasText && !hasImage) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero, // Removed margin
      padding: EdgeInsets.zero, // Removed padding
      decoration: BoxDecoration(
        color: isCorrect ? _correctColor.withOpacity(0.1) : _cardColor,
        border: Border.all(
          color: isCorrect ? _correctColor : _dividerColor,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.all(8), // Small margin for the label
            decoration: BoxDecoration(
              color: isCorrect ? _correctColor : _accentColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasText)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 8, right: 8, bottom: 4), // Minimal padding
                    child: TeXViewSimplified(text),
                  ),
                if (hasImage)
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 4, right: 8, bottom: 8), // Minimal padding
                    child: _buildImage(imageUrl),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an image widget with paper theme styling, utilizing maximum space.
  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        height: 70,
        width: double.infinity,
        fit: BoxFit.cover, // Changed to cover to utilize space
        errorBuilder: (context, error, stackTrace) => Container(
          height: 70,
          width: double.infinity,
          color: _dividerColor,
          child: Center(
            child: Icon(
              Icons.error,
              color: _accentColor,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

/// Theme colors for the paper theme
class PaperThemeColors {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final Color correctColor;
  final Color dividerColor;

  const PaperThemeColors({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.correctColor,
    required this.dividerColor,
  });
}
