import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class TeXViewSimplified extends StatelessWidget {
  final String latexContent;

  const TeXViewSimplified(this.latexContent, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeXView(
          loadingWidgetBuilder: (context) => const Center(),
          child: TeXViewDocument(
            latexContent,
            style: const TeXViewStyle(
              padding: TeXViewPadding.all(2),
              textAlign: TeXViewTextAlign.left,
            ),
          ),
        ),
      ],
    );
  }
}
