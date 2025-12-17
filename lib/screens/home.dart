import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jazone_1/screens/incidentform.dart';
import 'package:jazone_1/screens/utils/color_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _showSnapTips = true; // Show overlay initially

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _controller = CameraController(_cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    final XFile image = await _controller!.takePicture();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentFormPage(imageFile: File(image.path)),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentFormPage(imageFile: File(image.path)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final previewHeight = size.height * 0.5; // Camera preview height
    final previewWidth = size.width * 0.9;   // Camera preview width

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
              children: [
                Center(
                  child: Container(
                    height: previewHeight,
                    width: previewWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      // overflow: BorderOverflow.hidden,
                    ),
                    child: CameraPreview(_controller!),
                  ),
                ),
                if (_showSnapTips)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSnapTips = false; // Hide overlay on tap
                      });
                    },
                    child: Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/snap_tips.png', // Replace with your overlay image
                            width: 200,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Tap anywhere to continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery Button
                      FloatingActionButton(
                        heroTag: "gallery",
                        backgroundColor: Colors.white54,
                        onPressed: _pickImageFromGallery,
                        child: const Icon(Icons.photo_library, color: Colors.black),
                      ),

                      // Capture Button
                      FloatingActionButton(
                        heroTag: "capture",
                        backgroundColor: AppColors.buttonAccent,
                        onPressed: _takePicture,
                        child: const Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
