import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jazone_1/screens/utils/color_utils.dart';

class IncidentFormPage extends StatefulWidget {
  final File imageFile;

  const IncidentFormPage({super.key, required this.imageFile});

  @override
  State<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends State<IncidentFormPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String urgency = 'Normal';
  String address = 'Fetching location...';
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getAddressFromGPS();
  }

  Future<void> _getAddressFromGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => address = 'Location service disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => address = 'Location permission denied');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    Placemark place = placemarks.first;

    setState(() {
      address =
          '${place.street}, ${place.locality}, ${place.administrativeArea}';
    });
  }

  Future<void> _submitIncident() async {
    setState(() => isSubmitting = true);

    try {
      final fileName = 'incidents/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      await storageRef.putFile(widget.imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('incidents').add({
        'name': nameController.text.isEmpty ? 'Unknown' : nameController.text,
        'address': address,
        'urgency': urgency,
        'description': descriptionController.text,
        'imageUrl': imageUrl,
        'status': 'Reported',
        'timestamp': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident reported successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Incident Information'),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image preview
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(widget.imageFile),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Name field
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name (Optional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: AppColors.card,
                filled: true,
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),

            const SizedBox(height: 16),

            // Address field (read-only)
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Address',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                fillColor: AppColors.card,
                filled: true,
                hintText: address,
                hintStyle: TextStyle(color: AppColors.textSecondary),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),

            const SizedBox(height: 16),

            // Urgency dropdown
            DropdownButtonFormField<String>(
              value: urgency,
              decoration: InputDecoration(
                labelText: 'Request Type',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: AppColors.card,
                filled: true,
              ),
              items: const [
                DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
              ],
              onChanged: (value) => setState(() => urgency = value!),
              style: TextStyle(color: AppColors.textPrimary),
            ),

            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Incident Description',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryBlue),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: AppColors.card,
                filled: true,
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),

            const SizedBox(height: 25),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitting
                      ? AppColors.buttonDisabled
                      : AppColors.buttonPrimary,
                ),
                onPressed: isSubmitting ? null : _submitIncident,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
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
