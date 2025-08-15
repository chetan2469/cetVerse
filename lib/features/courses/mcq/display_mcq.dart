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
      backgroundColor: AppTheme.scaffoldBackground,
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

  /// Builds the AppBar with a consistent style.
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'MCQ Details',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  /// Builds the main body of the page with a scrollable card layout.
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
        explaination: finalExplaination);
  }

  Widget _latexView(String val) {
    return TeXView(
      loadingWidgetBuilder: (context) => const Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      child: TeXViewDocument(
        val,
        style: const TeXViewStyle(
          padding: TeXViewPadding.all(2),
          textAlign: TeXViewTextAlign.left,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.subheadingStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Builds an option row with LaTeX text and an optional image.
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

    return ListTile(
      leading: Text(
        '$label:',
        style: TextStyle(
          color: isCorrect ? Colors.green : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      title: hasText ? TeXViewSimplified(text) : null,
      subtitle: hasImage
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: _buildImage(imageUrl),
            )
          : null,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
    );
  }

  /// Builds an image widget with error handling and consistent styling.
  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        height: 70,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 70,
          width: double.infinity,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(
              Icons.error,
              color: Colors.red,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
