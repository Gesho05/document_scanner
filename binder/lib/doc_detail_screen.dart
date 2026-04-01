import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocDetailScreen extends StatefulWidget {
  const DocDetailScreen({
    super.key,
    required this.documentFile,
    required this.documentName,
  });

  final File documentFile;
  final String documentName;

  @override
  State<DocDetailScreen> createState() => _DocDetailScreenState();
}

class _DocDetailScreenState extends State<DocDetailScreen> {
  String _extractedText = '';
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _extractTextFromImage();
  }

  Future<void> _extractTextFromImage() async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFile(widget.documentFile);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _extractedText = recognizedText.text;
        _isScanning = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _extractedText = 'Could not extract text.';
        _isScanning = false;
      });
    } finally {
      await textRecognizer.close();
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _extractedText));

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Copied!'),
        content: const Text('Document text copied to clipboard.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        title: Text(
          widget.documentName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(widget.documentFile, fit: BoxFit.contain),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recognized Text',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isScanning && _extractedText.isNotEmpty)
                        GestureDetector(
                          onTap: _copyToClipboard,
                          child: const Icon(
                            CupertinoIcons.doc_on_clipboard_fill,
                            color: Color(0xFFC48B3F),
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: _isScanning
                        ? const Center(
                            child: CupertinoActivityIndicator(color: Colors.white),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              _extractedText.isEmpty
                                  ? 'No text found in this document.'
                                  : _extractedText,
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}