import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Ensure this is imported in your main app file

// 1. CONVERTED TO STATEFUL WIDGET TO MANAGE INPUT STATE AND SAVE OPERATION
class EditDetailsScreen extends StatefulWidget {
  final String name;
  final String email;
  final String registerNo;
  final String studentClass;
  final String section;
  final String department;
  final String hostelDaysScholar;
  final String batch;

  EditDetailsScreen({
    required this.name,
    required this.email,
    required this.registerNo,
    required this.studentClass,
    required this.section,
    required this.department,
    required this.hostelDaysScholar,
    required this.batch,
  });

  @override
  _EditDetailsScreenState createState() => _EditDetailsScreenState();
}

class _EditDetailsScreenState extends State<EditDetailsScreen> {
  // 2. TEXT EDITING CONTROLLERS
  // We only need controllers for the fields the user is allowed to edit.
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _hostelDaysScholarController;

  // State for loading indicator
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the data passed from the widget
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _hostelDaysScholarController =
        TextEditingController(text: widget.hostelDaysScholar);
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _hostelDaysScholarController.dispose();
    super.dispose();
  }

  // 3. IMPLEMENT THE FIREBASE SAVE LOGIC
  void _saveDetails() async {
    if (_isSaving) return;

    // Basic Input Validation
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name and Email cannot be empty.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Data payload for updating Firestore
      final updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'hostelDaysScholar': _hostelDaysScholarController.text.trim(),
        // Note: We don't update immutable fields like registerNo, department, etc.
      };

      // Perform the Firestore update
      // Assumes your student documents are in a collection named 'students'
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.registerNo) // Use registerNo as the unique Document ID
          .update(updatedData);

      // Success Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back, passing 'true' to signal a successful update to the calling screen
      Navigator.pop(context, true);
    } catch (e) {
      // Error Handling
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 4. Helper method for building TextFields
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        style: TextStyle(color: isReadOnly ? Colors.grey[700] : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: isReadOnly ? Colors.grey : Colors.blueGrey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          fillColor: isReadOnly ? Colors.grey[100] : Colors.white,
          filled: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Controllers for read-only data (initialized once, but we don't manage their state)
    // We use TextEditingController here for consistency in the _buildTextField widget,
    // even though the fields are read-only.
    final _registerNoController = TextEditingController(text: widget.registerNo);
    final _classController = TextEditingController(text: widget.studentClass);
    final _sectionController = TextEditingController(text: widget.section);
    final _departmentController = TextEditingController(text: widget.department);
    final _batchController = TextEditingController(text: widget.batch);

    return Scaffold(
      appBar: AppBar(
        title: const Text('✏️ Edit Student Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editable Fields
              _buildTextField('Name', _nameController),
              _buildTextField('Email', _emailController),
              _buildTextField('Hostel/Days Scholar Status', _hostelDaysScholarController),

              const Divider(height: 40, thickness: 1, color: Colors.blueGrey),

              // Read-Only Fields (for reference)
              _buildTextField('Register No', _registerNoController,
                  isReadOnly: true),
              _buildTextField('Class', _classController, isReadOnly: true),
              _buildTextField('Section', _sectionController, isReadOnly: true),
              _buildTextField('Department', _departmentController,
                  isReadOnly: true),
              _buildTextField('Batch', _batchController, isReadOnly: true),

              const SizedBox(height: 30),

              // Save Button
              Center(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDetails, // Call the save function
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text("Save Changes"),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
