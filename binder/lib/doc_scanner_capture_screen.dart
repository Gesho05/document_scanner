import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
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
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImage;
  bool _isTakingPicture = false;
  final TextEditingController _nameController = TextEditingController();

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

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
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

  Future<void> _validateAndSave() async {
    final String chosenName = _nameController.text.trim();

    if (chosenName.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext dialogContext) => CupertinoAlertDialog(
          title: const Text('Name Required'),
          content: const Text('Please provide a name for your document before saving.'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (_capturedImage != null) {
      final savedFile = await _saveImagePermanently(File(_capturedImage!.path), chosenName);
      final DateTime now = DateTime.now();

      widget.onDocumentSaved({
        'name': chosenName,
        'file': savedFile,
        'category': 'Personal',
        'savedAt': now,
      });

      if (mounted) {
        setState(() {
          _capturedImage = null;
          _nameController.clear();
        });
        Navigator.pop(context);
      }
    }
  }

  Future<File> _saveImagePermanently(File tempFile, String chosenName) async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String safeFileName = '${chosenName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return tempFile.copy('$path/$safeFileName');
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_capturedImage == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.width * 0.85 * 1.41,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
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
                          'Scan Document',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 28),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 40,
                    right: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: _takePicture,
                          child: _isTakingPicture
                              ? const CircularProgressIndicator()
                              : Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black.withOpacity(0.2), width: 6),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 65,
                                      height: 65,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 60),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _capturedImage = null),
                    child: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
                  ),
                  const Text(
                    'Edit & Name',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                      image: DecorationImage(image: FileImage(File(_capturedImage!.path)), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.pencil, color: Colors.white30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _nameController,
                        placeholder: 'Document Name',
                        placeholderStyle: const TextStyle(color: Colors.white30),
                        style: const TextStyle(color: Colors.white),
                        decoration: null,
                        autofocus: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0, left: 25.0, right: 25.0),
              child: GestureDetector(
                onTap: _validateAndSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC48B3F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Save Scan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
