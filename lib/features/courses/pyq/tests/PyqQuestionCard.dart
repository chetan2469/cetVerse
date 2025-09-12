// // PyqQuestionCard.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_tex/flutter_tex.dart';

// class PyqQuestionCard extends StatelessWidget {
//   final int index;
//   final Map<String, dynamic> mcq;
//   final List<int> userAnswers;
//   final bool hasSubmitted;
//   final Function(String) onSelectAnswer;
//   final Set<int> reviewedQuestions;
//   final Function(int) onToggleReview;
//   final Function() nextQuestion;
//   final Function() prevQuestion;
//   final List<Map<String, dynamic>> originalMcqs;

//   const PyqQuestionCard({
//     super.key,
//     required this.index,
//     required this.mcq,
//     required this.userAnswers,
//     required this.hasSubmitted,
//     required this.onSelectAnswer,
//     required this.reviewedQuestions,
//     required this.onToggleReview,
//     required this.nextQuestion,
//     required this.prevQuestion,
//     required this.originalMcqs,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final originalIndex = originalMcqs.indexOf(mcq);

//     final questionMap = mcq['question'] as Map<String, dynamic>? ?? {};
//     final String questionText = questionMap['text'] ?? 'No question provided.';
//     final String questionImage = questionMap['image'] ?? '';
//     final String originText = mcq['origin'] ?? '-';

//     final optionsMap = mcq['options'] as Map<String, dynamic>? ?? {};
//     final Map<String, dynamic> optionA =
//         optionsMap['A'] as Map<String, dynamic>? ?? {};
//     final Map<String, dynamic> optionB =
//         optionsMap['B'] as Map<String, dynamic>? ?? {};
//     final Map<String, dynamic> optionC =
//         optionsMap['C'] as Map<String, dynamic>? ?? {};
//     final Map<String, dynamic> optionD =
//         optionsMap['D'] as Map<String, dynamic>? ?? {};

//     final String aText = optionA['text'] ?? '';
//     final String aImage = optionA['image'] ?? '';
//     final String bText = optionB['text'] ?? '';
//     final String bImage = optionB['image'] ?? '';
//     final String cText = optionC['text'] ?? '';
//     final String cImage = optionC['image'] ?? '';
//     final String dText = optionD['text'] ?? '';
//     final String dImage = optionD['image'] ?? '';

//     String finalQuestionText = "<b>Q${mcq['docId']}: </b>$questionText";
//     if (questionImage.isNotEmpty) {
//       finalQuestionText +=
//           '<br/><img src="$questionImage" width=300 height=150/>';
//     }

//     String finalAText = aText;
//     if (aImage.isNotEmpty) {
//       finalAText += '<br/><img src="$aImage" width=300 height=150/>';
//     }
//     String finalBText = bText;
//     if (bImage.isNotEmpty) {
//       finalBText += '<br/><img src="$bImage" width=300 height=150/>';
//     }
//     String finalCText = cText;
//     if (cImage.isNotEmpty) {
//       finalCText += '<br/><img src="$cImage" width=300 height=150/>';
//     }
//     String finalDText = dText;
//     if (dImage.isNotEmpty) {
//       finalDText += '<br/><img src="$dImage" width=300 height=60/>';
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           ListView(
//             physics: const BouncingScrollPhysics(),
//             children: [
//               TeXView(
//                 key: ValueKey("quiz_${mcq['docId']}"),
//                 child: TeXViewColumn(
//                   children: [
//                     TeXViewDocument(
//                       finalQuestionText,
//                       style: TeXViewStyle(
//                         textAlign: TeXViewTextAlign.left,
//                         fontStyle: TeXViewFontStyle(fontSize: 16),
//                         padding: TeXViewPadding.all(16),
//                       ),
//                     ),
//                     TeXViewGroup(
//                       children: [
//                         _buildOption(originalIndex, "id_1", "A", finalAText),
//                         _buildOption(originalIndex, "id_2", "B", finalBText),
//                         _buildOption(originalIndex, "id_3", "C", finalCText),
//                         _buildOption(originalIndex, "id_4", "D", finalDText),
//                       ],
//                       onTap: hasSubmitted ? null : onSelectAnswer,
//                     ),
//                   ],
//                 ),
//                 style: const TeXViewStyle(
//                   margin: TeXViewMargin.all(10),
//                   padding: TeXViewPadding.all(10),
//                   backgroundColor: Colors.white,
//                 ),
//                 loadingWidgetBuilder: (context) => const SizedBox.shrink(),
//               ),
//             ],
//           ),
//           Positioned(
//             top: 2,
//             right: 2,
//             child: IconButton(
//               icon: Icon(
//                 Icons.bookmark,
//                 color: reviewedQuestions.contains(originalIndex)
//                     ? const Color.fromARGB(255, 228, 210, 42)
//                     : Colors.grey,
//                 size: 24,
//               ),
//               onPressed: () => onToggleReview(originalIndex),
//             ),
//           ),
//           // Swipe indicators
//         ],
//       ),
//     );
//   }

//   TeXViewGroupItem _buildOption(
//       int originalIndex, String id, String label, String content) {
//     final isSelected =
//         userAnswers[originalIndex] == int.parse(id.split('_')[1]) - 1;
//     return TeXViewGroupItem(
//       rippleEffect: true,
//       id: id,
//       child: TeXViewDocument(
//         "<b>$label: </b>$content",
//         style: isSelected
//             ? TeXViewStyle(
//                 borderRadius: TeXViewBorderRadius.all(8),
//                 border: TeXViewBorder.all(
//                   TeXViewBorderDecoration(
//                     borderWidth: 2,
//                     borderColor: Colors.blue,
//                   ),
//                 ),
//                 margin: TeXViewMargin.all(4),
//                 backgroundColor: Colors.transparent,
//                 padding: TeXViewPadding.all(12),
//                 fontStyle: TeXViewFontStyle(fontSize: 14),
//               )
//             : TeXViewStyle(
//                 margin: const TeXViewMargin.all(8),
//                 borderRadius: const TeXViewBorderRadius.all(8),
//                 border: const TeXViewBorder.all(
//                   TeXViewBorderDecoration(
//                     borderWidth: 1,
//                     borderColor: Colors.grey,
//                   ),
//                 ),
//                 backgroundColor: Colors.white,
//                 padding: const TeXViewPadding.all(12),
//                 fontStyle: TeXViewFontStyle(fontSize: 14),
//               ),
//       ),
//     );
//   }
// }
