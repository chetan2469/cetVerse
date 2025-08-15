import 'package:cet_verse/ui/latex/tex_view_simplified.dart';
import 'package:flutter/material.dart';

class DisplayMCQExample extends StatelessWidget {
  const DisplayMCQExample({super.key});

  @override
  Widget build(BuildContext context) {
    // LaTeX content for the question and solution
    String latexContent = r"""
    \textbf{Question:} Solve the equation \( 2x + 3 = 7 \).

    \subsection*{Solution:}
    To solve the equation \( 2x + 3 = 7 \), we need to isolate \( x \) on one side of the equation. Here are the steps:

    """;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Display MCQ Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TeXViewSimplified(latexContent),
      ),
    );
  }
}
