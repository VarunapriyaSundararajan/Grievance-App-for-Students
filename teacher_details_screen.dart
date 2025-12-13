import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacherdashboard.dart'; // Import the Teacher Dashboard screen

class TeacherDetailsScreen extends StatelessWidget {
  final String? userId;

  TeacherDetailsScreen({required this.userId});

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String? _selectedDepartment;


  final List<String> departments = [
    'CSE', 'IT', 'AIML', 'AIDS', 'Civil', 'Food Tech',
    'Mechanical', 'Agri', 'Cyber Security', 'ECE', 'EEE', 'Cyber CSE'
  ];

  final List<String> hostelOptions = ['Hostel', 'Days Scholar'];

  Future<void> _submitTeacherDetails(BuildContext context) async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _selectedDepartment == null ||
        _phoneNumberController.text.isEmpty ) {
      _showAlert(context, 'Please fill in all fields.');
      return;
    }

    try {
      final teacherDetails = {
        'name': _nameController.text,
        'email': _emailController.text,
        'department': _selectedDepartment,
        'phoneNumber': _phoneNumberController.text,
      
      };

      await FirebaseFirestore.instance.collection('teachers').doc(userId).set(teacherDetails);

      // Navigate to the Teacher Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherDashboard(
            name: teacherDetails['name'] ?? 'N/A',
            email: teacherDetails['email'] ?? 'N/A',
            department: teacherDetails['department'] ?? 'N/A',
            phoneNumber: teacherDetails['phoneNumber'] ?? 'N/A',
        
          ),
        ),
      );

      _showAlert(context, 'Teacher details submitted successfully!', isSuccess: true);
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
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeacherDashboard(
                        name: _nameController.text,
                        email: _emailController.text,
                        department: _selectedDepartment ?? 'N/A',
                        phoneNumber: _phoneNumberController.text,
                      
                      ),
                    ),
                  );
                }
              },
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
                  "Enter Teacher Details",
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
                _buildLabel("Phone Number"),
                _buildTextField(_phoneNumberController, "Enter Phone Number", TextInputType.phone),
                
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _submitTeacherDetails(context),
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

  Widget _buildTextField(TextEditingController controller, String hint, [TextInputType inputType = TextInputType.text]) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
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
