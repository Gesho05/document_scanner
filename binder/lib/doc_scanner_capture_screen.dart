import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class DocScannerCaptureScreen extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onDocumentSaved;

  const DocScannerCaptureScreen({
    super.key,
    required this.onDocumentSaved,
  });

  @override
  State<DocScannerCaptureScreen> createState() => _DocScannerCaptureScreenState();
}

class _DocScannerCaptureScreenState extends State<DocScannerCaptureScreen> {
  CameraController? _controller;
  XFile? _capturedImage;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }
    setState(() => _isTakingPicture = true);

    try {
      final image = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          _capturedImage = image;
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTakingPicture = false);
      }
    }
  }

  Future<void> _openCropScreen() async {
    if (_capturedImage == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _capturedImage!.path,
      uiSettings: [
        IOSUiSettings(
          title: 'Edit Document',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
          aspectRatioLockEnabled: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      _showNamingDialog(File(croppedFile.path));
    }
  }

  Future<File> _saveImagePermanently(File tempFile, String chosenName) async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String safeFileName = '${chosenName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return tempFile.copy('$path/$safeFileName');
  }

  Future<String> _autoCategorizeImage(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      final text = recognizedText.text.toLowerCase();

      if (text.contains('work') ||
          text.contains('invoice') ||
          text.contains('contract') ||
          text.contains('schedule')) {
        return 'Work';
      }

      return 'Personal';
    } catch (_) {
      return 'Personal';
    } finally {
      await textRecognizer.close();
    }
  }

  Future<DateTime?> _recognizeDateFromImage(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      final normalizedText = recognizedText.text.toLowerCase().replaceAll('/', '.').replaceAll('-', '.');

      final dateRegExp = RegExp(r'\b(\d{1,2}\.\d{1,2}\.\d{4})\b');
      final matches = dateRegExp.allMatches(normalizedText);

      if (matches.isNotEmpty) {
        final dateStr = matches.first.group(0);
        if (dateStr != null) {
          return DateFormat('dd.MM.yyyy').parse(dateStr);
        }
      }

      return null;
    } catch (_) {
      return null;
    } finally {
      await textRecognizer.close();
    }
  }

  void _showNamingDialog(File finalImage) {
    final TextEditingController nameController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: CupertinoAlertDialog(
          title: const Text('Name Document'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(
              controller: nameController,
              placeholder: 'Enter filename',
              style: const TextStyle(color: Colors.black),
              autofocus: true,
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

                final savedFile = await _saveImagePermanently(finalImage, fileName);
                final autoCategory = await _autoCategorizeImage(savedFile);
                final extractedDate = await _recognizeDateFromImage(savedFile);
                widget.onDocumentSaved({
                  'name': fileName,
                  'file': savedFile,
                  'category': autoCategory,
                  'savedAt': DateTime.now(),
                  'dateScanned': DateTime.now(),
                  'expiryDate': extractedDate,
                });

                if (!mounted) return;
                Navigator.pop(dialogContext);
                setState(() => _capturedImage = null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final double nativeAspectRatio = 1 / _controller!.value.aspectRatio;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: nativeAspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.width * 0.75 * 1.41,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
                ),
                const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(top: 30, bottom: 60, left: 40, right: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _capturedImage != null ? _openCropScreen : null,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white12,
                        image: _capturedImage != null
                            ? DecorationImage(image: FileImage(File(_capturedImage!.path)), fit: BoxFit.cover)
                            : null,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _takePicture,
                    child: _isTakingPicture
                        ? const SizedBox(
                            width: 75,
                            height: 75,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12, width: 4),
                            ),
                          ),
                  ),
                  GestureDetector(
                    onTap: _capturedImage != null ? _openCropScreen : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _capturedImage != null ? const Color(0xFFC48B3F) : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          color: _capturedImage != null ? Colors.white : Colors.white38,
                          fontWeight: FontWeight.bold,
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
