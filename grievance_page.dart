// grievance_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';

class GrievancePage extends StatefulWidget {
  final Map<String, dynamic> studentData;
  const GrievancePage({required this.studentData, Key? key}) : super(key: key);

  @override
  State<GrievancePage> createState() => _GrievancePageState();
}

class _GrievancePageState extends State<GrievancePage> {
  final TextEditingController _grievanceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage; // used on mobile
  Uint8List? _webImageBytes; // used on web
  String? _webFileName;
  bool _isSubmitting = false;
  String? _selectedCategory;
  bool _isKeyGrievance = false;

  @override
  void dispose() {
    _grievanceController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageIfAny() async {
    try {
      if (kIsWeb) {
        if (_webImageBytes == null || _webFileName == null) return null;
        final ref = FirebaseStorage.instance.ref().child('grievances/${DateTime.now().millisecondsSinceEpoch}_$_webFileName');
        final task = await ref.putData(_webImageBytes!);
        final url = await ref.getDownloadURL();
        return url;
      } else {
        if (_selectedImage == null) return null;
        final file = io.File(_selectedImage!.path);
        final ref = FirebaseStorage.instance.ref().child('grievances/${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}');
        final task = await ref.putFile(file);
        final url = await ref.getDownloadURL();
        return url;
      }
    } catch (e) {
      // If upload fails, return null but allow grievance to be submitted
      print('Image upload failed: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.isNotEmpty) {
          final picked = result.files.first;
          if (picked.bytes != null) {
            setState(() {
              _webImageBytes = picked.bytes;
              _webFileName = picked.name;
              _selectedImage = null;
            });
          }
        }
      } catch (e) {
        print('Web file picking failed: $e');
      }
    } else {
      try {
        final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked != null) {
          setState(() {
            _selectedImage = picked;
            _webImageBytes = null;
            _webFileName = null;
          });
        }
      } catch (e) {
        print('Mobile image pick failed: $e');
      }
    }
  }

  Future<void> _submitGrievance() async {
    final grievanceText = _grievanceController.text.trim();
    if (grievanceText.isEmpty || _selectedCategory == null) {
      _showAlert('Please enter a grievance and select a category.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // upload image if present
      final imageUrl = await _uploadImageIfAny();

      // Get current user id (if available)
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      // department fallback from passed studentData
      final department = widget.studentData['department'] ?? 'Unknown';

      await FirebaseFirestore.instance.collection('grievances').add({
        'category': _selectedCategory,
        'grievance': grievanceText,
        'department': department,
        'uid': uid,
        'isKey': _isKeyGrievance,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showAlert('Grievance submitted successfully!', isSuccess: true);
      _grievanceController.clear();
      setState(() {
        _selectedCategory = null;
        _isKeyGrievance = false;
        _selectedImage = null;
        _webImageBytes = null;
        _webFileName = null;
      });
    } catch (e) {
      _showAlert('Error submitting grievance: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showAlert(String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isSuccess ? 'Success' : 'Alert'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _imagePreview() {
    if (kIsWeb) {
      if (_webImageBytes != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Image selected (web):'),
            const SizedBox(height: 8),
            Image.memory(_webImageBytes!, height: 120),
          ],
        );
      }
    } else {
      if (_selectedImage != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Image selected:'),
            const SizedBox(height: 8),
            Image.file(io.File(_selectedImage!.path), height: 120),
          ],
        );
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Your Grievance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Choose Category:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            items: <String>['Academic', 'Facilities', 'Hostel', 'Other']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            value: _selectedCategory,
            onChanged: (v) => setState(() => _selectedCategory = v),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            ),
            hint: const Text('Select Category'),
            isExpanded: true,
          ),
          const SizedBox(height: 16),
          const Text('Enter Your Grievance:', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _grievanceController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter your grievance here...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 12),

          Row(children: [
            Checkbox(value: _isKeyGrievance, onChanged: (v) => setState(() => _isKeyGrievance = v ?? false)),
            const Flexible(child: Text('Mark as Key Grievance (Solve ASAP)')),
          ]),

          const SizedBox(height: 12),
          const Text('Insert Image (Optional):', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Insert Image'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),

          _imagePreview(),

          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitGrievance,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Grievance'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // small alias to call submit (keeps name similar to original)
  Future<void> _submitGrievance() async => _submitGrievanceWrapper();
  Future<void> _submitGrievanceWrapper() async => _submitGrievance();
}
