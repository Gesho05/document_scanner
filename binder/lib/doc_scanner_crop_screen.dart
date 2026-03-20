import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class DocScannerCropScreen extends StatefulWidget {
  final File imageFile;

  const DocScannerCropScreen({super.key, required this.imageFile});

  @override
  State<DocScannerCropScreen> createState() => _DocScannerCropScreenState();
}

class _DocScannerCropScreenState extends State<DocScannerCropScreen> {
  Future<File> _saveImagePermanently(File tempFile, String chosenName) async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String safeFileName = '${chosenName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return tempFile.copy('$path/$safeFileName');
  }

  void _showNamingDialog() {
    final TextEditingController nameController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Name Document'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: 'Enter filename',
            placeholderStyle: const TextStyle(color: Colors.black26),
            autofocus: true,
            style: const TextStyle(color: Colors.black),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () async {
              final String fileName = nameController.text.trim();
              if (fileName.isEmpty) {
                return;
              }

              final savedFile = await _saveImagePermanently(widget.imageFile, fileName);

              if (!mounted) return;
              Navigator.pop(dialogContext);
              Navigator.pop(context, {
                'name': fileName,
                'file': savedFile,
                'category': 'Scanned',
                'savedAt': DateTime.now(),
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  const Text(
                    'Edit Scan',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showNamingDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC48B3F),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(widget.imageFile, fit: BoxFit.cover),
                        ),
                        const Positioned(
                          top: 15,
                          left: 15,
                          child: Icon(CupertinoIcons.clear, color: Color(0xFFC48B3F), size: 30),
                        ),
                        const Positioned(
                          top: 15,
                          right: 15,
                          child: Icon(CupertinoIcons.clear, color: Color(0xFFC48B3F), size: 30),
                        ),
                        const Positioned(
                          bottom: 15,
                          left: 15,
                          child: Icon(CupertinoIcons.clear, color: Color(0xFFC48B3F), size: 30),
                        ),
                        const Positioned(
                          bottom: 15,
                          right: 15,
                          child: Icon(CupertinoIcons.clear, color: Color(0xFFC48B3F), size: 30),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
