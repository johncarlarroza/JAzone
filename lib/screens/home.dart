import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jazone_1/screens/incidentform.dart';
import 'package:jazone_1/screens/utils/color_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras![_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(_flashMode);

    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
  }

  void _toggleFlash() {
    _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    _cameraController!.setFlashMode(_flashMode);
    setState(() {});
  }

  void _switchCamera() async {
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    await _initializeCamera();
  }

  Future<void> _captureImage() async {
    if (!_cameraController!.value.isInitialized) return;
    XFile file = await _cameraController!.takePicture();

    // Navigate to IncidentFormPage with captured image
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentFormPage(imageFile: File(file.path)),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      // Navigate to IncidentFormPage with selected image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentFormPage(imageFile: File(file.path)),
        ),
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Snap Tips"),
        content: Image.asset('assets/tips.png'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double focusWidth = 250;
    double focusHeight = 410;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 3, 27, 62),
      body: Stack(
        children: [
          _isCameraInitialized
              ? Center(
                  child: Container(
                    width: focusWidth,
                    height: focusHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 207, 129, 4),
                        width: 4,
                      ),
                    ),
                    child: CameraPreview(_cameraController!),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),

          /// Top Buttons
          Positioned(
            top: 90,
            left: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(
                    _flashMode == FlashMode.torch
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(Icons.switch_camera, color: Colors.white),
                ),
              ],
            ),
          ),

          /// Bottom Buttons
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FloatingActionButton(
                  onPressed: _pickFromGallery,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.photo, color: Colors.black),
                ),
                FloatingActionButton(
                  onPressed: _captureImage,
                  backgroundColor: const Color.fromARGB(255, 206, 89, 6),
                  child: const Icon(Icons.camera, color: Colors.white),
                ),
                FloatingActionButton(
                  onPressed: _showHelpDialog,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.help_outline, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
