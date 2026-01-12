import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jazone_1/screens/incident_dashboard_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jazone_1/screens/utils/color_utils.dart';

class IncidentFormPage extends StatefulWidget {
  final File imageFile;

  const IncidentFormPage({super.key, required this.imageFile});

  @override
  State<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends State<IncidentFormPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String urgency = 'Normal';
  bool isSubmitting = false;

  double? latitude;
  double? longitude;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
    _getLocationAndAddress();
  }

  // 📍 LOCATION
  Future<void> _getLocationAndAddress() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _addressController.text = 'Location service disabled';
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _addressController.text = 'Location permission denied';
      return;
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitude = position.latitude;
    longitude = position.longitude;

    final placemarks = await placemarkFromCoordinates(latitude!, longitude!);
    final place = placemarks.first;

    setState(() {
      _addressController.text =
          '${place.locality}, ${place.administrativeArea}';
    });
  }

  // 🚀 SUBMIT INCIDENT
  Future<void> _submitIncident() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final String filePath =
          'incidents/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final bytes = await widget.imageFile.readAsBytes();

      // Upload image to Supabase
      await supabase.storage
          .from('incident-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final String imageUrl = supabase.storage
          .from('incident-images')
          .getPublicUrl(filePath);

      print('Submitting incident with URL: $imageUrl');

      // Save to Firestore and capture the DocumentReference
      final docRef = await FirebaseFirestore.instance
          .collection('incidents')
          .add({
            'name': _nameController.text.isEmpty
                ? 'Unknown'
                : _nameController.text,
            'address': _addressController.text,
            'description': _descriptionController.text,
            'imageUrl': imageUrl,
            'latitude': latitude ?? 0.0,
            'longitude': longitude ?? 0.0,
            'urgency': urgency,
            'status': 'Reported',
            'timestamp': Timestamp.now(),
            'progress': {
              'accepted': false,
              'reportedToLGU': false,
              'onAction': false,
              'solved': false,
            },
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident reported successfully')),
      );

      // Navigate to IncidentDashboardPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentDashboardPage(incidentId: docRef.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Color get submitColor =>
      urgency == 'Urgent' ? Colors.orange.shade400 : Colors.blue.shade400;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // dark blue background
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text('Report Incident'),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _imagePreview(),
              const SizedBox(height: 24),
              _formCard(),
              const SizedBox(height: 30),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 🖼 IMAGE PREVIEW
  Widget _imagePreview() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          widget.imageFile,
          height: 230,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 📋 FORM
  Widget _formCard() {
    return Card(
      elevation: 4,
      color: const Color(0xFF1A1F3A), // dark card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _inputField(
              controller: _nameController,
              label: 'Name (Optional)',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _addressController,
              readOnly: true,
              decoration: _inputDecoration(
                'Location',
                Icons.location_on_outlined,
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: urgency,
              decoration: _inputDecoration(
                'Urgency Level',
                Icons.priority_high_outlined,
              ),
              items: const [
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
              ],
              onChanged: (value) => setState(() => urgency = value!),
            ),
            const SizedBox(height: 16),

            _inputField(
              controller: _descriptionController,
              label: 'Incident Description',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: submitColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isSubmitting ? null : _submitIncident,
        child: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Submit Incident Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.blue.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.orange.shade400, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF0F172A),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
