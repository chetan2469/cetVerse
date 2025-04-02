import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LatexRenderer extends StatefulWidget {
  final String latex;

  const LatexRenderer({super.key, required this.latex});

  @override
  _LatexRendererState createState() => _LatexRendererState();
}

class _LatexRendererState extends State<LatexRenderer> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildHtml(widget.latex));
  }

  String _buildHtml(String latex) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
        <style>
          body { 
            margin: 0; 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            background: transparent; 
            color: white; 
            font-size: 16px; 
          }
          .mjx-chtml { 
            padding: 8px; 
          }
        </style>
      </head>
      <body>
        <div id="math">\$\$${latex}\$\$</div>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100, // Adjust height based on your needs
      child: WebViewWidget(controller: _controller),
    );
  }

  @override
  void didUpdateWidget(LatexRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latex != widget.latex) {
      _controller.loadHtmlString(_buildHtml(widget.latex));
    }
  }
}
