import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class TeXViewQuizExample extends StatefulWidget {
  final String statement;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final String correctOptionId;
  final String explaination;

  const TeXViewQuizExample({
    super.key,
    required this.statement,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    required this.correctOptionId,
    required this.explaination,
  });

  @override
  State<TeXViewQuizExample> createState() => _TeXViewQuizExampleState();
}

class _TeXViewQuizExampleState extends State<TeXViewQuizExample> {
  String selectedOptionId = "";
  bool isWrong = false;
  bool isCorrect = false;

  // Function to show explanation in a popup
  void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: TeXView(
                child: TeXViewDocument(
                  "<b>Explanation: </b>${widget.explaination}",
                  style: TeXViewStyle(
                    textAlign: TeXViewTextAlign.left,
                    fontStyle: TeXViewFontStyle(
                      fontSize: 16,
                      fontFamily: 'Georgia',
                    ),
                    padding: const TeXViewPadding.all(12),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Close",
                style: TextStyle(
                  color: Colors.brown,
                  fontFamily: 'Georgia',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5), // Subtle off-white for paper feel
      body: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            // Question Section
            TeXView(
              child: TeXViewColumn(children: [
                // Question
                TeXViewDocument(
                  "<b>Question: </b>${widget.statement}",
                  style: TeXViewStyle(
                    textAlign: TeXViewTextAlign.left,
                    fontStyle: TeXViewFontStyle(
                      fontSize: 18,
                      fontFamily: 'Georgia',
                    ),
                    padding: const TeXViewPadding.all(16),
                  ),
                ),
                // Options
                TeXViewGroup(
                  children: [
                    _buildOption("id_1", "A", widget.option1),
                    _buildOption("id_2", "B", widget.option2),
                    _buildOption("id_3", "C", widget.option3),
                    _buildOption("id_4", "D", widget.option4),
                  ],
                  selectedItemStyle: TeXViewStyle(
                    borderRadius: const TeXViewBorderRadius.all(8),
                    border: TeXViewBorder.all(
                      TeXViewBorderDecoration(
                        borderWidth: 2,
                        borderColor:
                            isCorrect ? Colors.green[700]! : Colors.red[700]!,
                      ),
                    ),
                    margin: const TeXViewMargin.all(8),
                    backgroundColor: Colors.grey[100],
                  ),
                  normalItemStyle: TeXViewStyle(
                    margin: const TeXViewMargin.all(8),
                    borderRadius: const TeXViewBorderRadius.all(8),
                    border: TeXViewBorder.all(
                      TeXViewBorderDecoration(
                        borderWidth: 1,
                        borderColor: Colors.grey[300]!,
                      ),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onTap: (id) {
                    setState(() {
                      selectedOptionId = id;
                      isWrong = id != widget.correctOptionId;
                      isCorrect = id == widget.correctOptionId;
                    });
                  },
                ),
                TeXViewDocument(
                  "<b>Explaination: </b>${widget.explaination}",
                  style: TeXViewStyle(
                    textAlign: TeXViewTextAlign.left,
                    fontStyle: TeXViewFontStyle(
                      fontSize: 18,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ]),
              style: TeXViewStyle(
                margin: const TeXViewMargin.all(8),
                padding: const TeXViewPadding.all(16),
                borderRadius: const TeXViewBorderRadius.all(12),
                border: TeXViewBorder.all(
                  TeXViewBorderDecoration(
                    borderColor: Colors.grey[300]!,
                    borderStyle: TeXViewBorderStyle.solid,
                    borderWidth: 1,
                  ),
                ),
                backgroundColor: Colors.white,
              ),
              loadingWidgetBuilder: (context) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.brown,
                  ),
                );
              },
            ),
            // Feedback Messages
          ],
        ),
      ),
    );
  }

  // Helper method to build option items
  TeXViewGroupItem _buildOption(String id, String label, String content) {
    return TeXViewGroupItem(
      rippleEffect: true,
      id: id,
      child: TeXViewDocument(
        "<b>$label: </b>$content",
        style: TeXViewStyle(
          padding: const TeXViewPadding.all(12),
          fontStyle: TeXViewFontStyle(
            fontSize: 16,
            fontFamily: 'Georgia',
          ),
          border: TeXViewBorder.all(
            TeXViewBorderDecoration(
              borderWidth: 2,
              borderColor: widget.correctOptionId == id
                  ? const Color.fromARGB(255, 157, 218, 160)
                  : const Color.fromARGB(255, 251, 250, 250),
            ),
          ),
        ),
      ),
    );
  }
}
