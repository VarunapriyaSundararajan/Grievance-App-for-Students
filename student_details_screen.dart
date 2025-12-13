import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'studentdashboard.dart'; // Import the Student Dashboard screen

class StudentDetailsScreen extends StatelessWidget {
  final String? userId;

  StudentDetailsScreen({required this.userId});

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _registerNoController = TextEditingController();
  final _classController = TextEditingController();
  final _batchController = TextEditingController(); // New Batch controller
  String? _selectedSection;
  String? _selectedDepartment;
  String? _selectedHostel;

  final List<String> departments = [
    'CSE', 'IT', 'AIML', 'AIDS', 'Civil', 'Food Tech', 
    'Mechanical', 'Agri', 'Cyber Security', 'ECE', 'EEE', 'Cyber CSE'
  ];

  final List<String> sections = ['A', 'B', 'C'];

  final List<String> hostelOptions = ['Hostel', 'Days Scholar'];

  Future<void> _submitStudentDetails(BuildContext context) async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _selectedDepartment == null ||
        _registerNoController.text.isEmpty ||
        _classController.text.isEmpty ||
        _selectedSection == null ||
        _selectedHostel == null ||
        _batchController.text.isEmpty) { // Ensure batch is filled
      _showAlert(context, 'Please fill in all fields.');
      return;
    }

    try {
      final studentDetails = {
        'name': _nameController.text,
        'email': _emailController.text,
        'department': _selectedDepartment,
        'registerNo': _registerNoController.text,
        'class': _classController.text,
        'section': _selectedSection,
        'hostelDaysScholar': _selectedHostel,
        'batch': _batchController.text, // Add batch to student details
      };

      await FirebaseFirestore.instance.collection('students').doc(userId).set(studentDetails);

      // Navigate to the Student Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainStudentScreen(
            name: studentDetails['name'] ?? 'N/A',
            email: studentDetails['email'] ?? 'N/A',
            registerNo: studentDetails['registerNo'] ?? 'N/A',
            studentClass: studentDetails['class'] ?? 'N/A',
            section: studentDetails['section'] ?? 'N/A',
            department: studentDetails['department'] ?? 'N/A',
            hostelDaysScholar: studentDetails['hostelDaysScholar'] ?? 'N/A',
            batch: studentDetails['batch'] ?? 'N/A', // Pass batch to dashboard
          ),
        ),
      );

      _showAlert(context, 'Student details submitted successfully!', isSuccess: true);
    } catch (e) {
      _showAlert(context, 'Error submitting details: $e');
    }
  }

  void _showAlert(BuildContext context, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSuccess ? 'Success' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter Student Details",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                _buildLabel("Name"),
                _buildTextField(_nameController, "Enter your name"),
                _buildLabel("Email"),
                _buildTextField(_emailController, "Enter your email"),
                _buildLabel("Department"),
                _buildDropdown(
                  value: _selectedDepartment,
                  hint: 'Select Department',
                  items: departments,
                  onChanged: (String? newValue) {
                    _selectedDepartment = newValue!;
                  },
                ),
                _buildLabel("Register No"),
                _buildTextField(_registerNoController, "Enter Register No"),
                _buildLabel("Class"),
                _buildTextField(_classController, "Enter Class"),
                _buildLabel("Section"),
                _buildDropdown(
                  value: _selectedSection,
                  hint: 'Select Section',
                  items: sections,
                  onChanged: (String? newValue) {
                    _selectedSection = newValue!;
                  },
                ),
                _buildLabel("Hostel/Days Scholar"),
                _buildDropdown(
                  value: _selectedHostel,
                  hint: 'Select Hostel or Days Scholar',
                  items: hostelOptions,
                  onChanged: (String? newValue) {
                    _selectedHostel = newValue!;
                  },
                ),
                _buildLabel("Batch"), // Add batch label
                _buildTextField(_batchController, "Enter Batch"), // Add batch text field
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _submitStudentDetails(context),
                    child: Text("Submit"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: hint,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: hint,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
