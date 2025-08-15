import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl; // The direct URL to your PDF

  const PdfViewerPage({super.key, required this.pdfUrl});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool _isDownloading = true; // Are we currently downloading?
  double _downloadProgress = 0.0; // [0..100] for the progress indicator
  String _errorMessage = "";

  /// Once the PDF is downloaded, we store it here for display
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  /// Download PDF manually to track progress, then show in SfPdfViewer.memory
  Future<void> _downloadPdf() async {
    try {
      final request = http.Request('GET', Uri.parse(widget.pdfUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        // If not 200 OK, throw an error
        throw Exception(
          "HTTP Error: ${response.statusCode} ${response.reasonPhrase}",
        );
      }

      final totalBytes = response.contentLength ?? 0;
      List<int> bytes = [];

      // Listen to the response stream
      response.stream.listen(
        (chunk) {
          bytes.addAll(chunk);
          if (totalBytes > 0) {
            setState(() {
              // Convert to percentage
              _downloadProgress = (bytes.length / totalBytes) * 100;
            });
          }
        },
        onDone: () {
          setState(() {
            _isDownloading = false;
            _pdfBytes = Uint8List.fromList(bytes);
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = "Error downloading PDF: $error";
            _isDownloading = false;
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Viewer", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (!_isDownloading && _pdfBytes != null) ...[
            // Refresh or other actions as needed
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _refreshPdf(),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_isDownloading) {
      // Show download progress
      return _buildDownloadingView();
    }
    if (_pdfBytes == null) {
      // Download done but somehow no data
      return const Center(
        child: Text("PDF data not available"),
      );
    }
    // Otherwise, show the PDF
    return SfPdfViewer.memory(_pdfBytes!, key: _pdfViewerKey);
  }

  /// A widget showing the user the download progress
  Widget _buildDownloadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Downloading PDF...",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _downloadProgress / 100.0,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text("${_downloadProgress.toStringAsFixed(0)}%",
              style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// Refresh by re-downloading
  void _refreshPdf() {
    setState(() {
      _pdfBytes = null;
      _errorMessage = "";
      _downloadProgress = 0.0;
      _isDownloading = true;
    });
    _downloadPdf();
  }
}
