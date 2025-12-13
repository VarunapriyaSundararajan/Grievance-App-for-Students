import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_details_screen.dart';
import 'teacher_details_screen.dart';
import 'login.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole = 'student'; // Set default role to 'student'
  int _selectedIndex = 0; // 0 for student, 1 for teacher
  bool _isLoading = false; // Loading state

  // Define your purple shade here
  final Color purpleColor = Color(0xFF6200EA);

  // Function to show alert dialog
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Function to validate password strength
  bool _isPasswordStrong(String password) {
    return password.length >= 6; // Adjust the criteria as needed
  }

  Future<void> _registerUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showAlert('Please fill in all fields.');
      return;
    }

    if (!_isPasswordStrong(_passwordController.text)) {
      _showAlert('Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Store the user's role in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': _emailController.text.trim(),
        'role': _selectedRole,
      });

      // Navigate to the details screen based on the selected role
      if (_selectedRole == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailsScreen(userId: userCredential.user?.uid),
          ),
        );
      } else if (_selectedRole == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherDetailsScreen(userId: userCredential.user?.uid),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showAlert('Account already exists for that email.');
      } else {
        _showAlert('An error occurred: ${e.message}');
      }
    } catch (e) {
      _showAlert('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 5,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Role Toggle (for Student or Teacher)
              ToggleButtons(
                isSelected: [_selectedIndex == 0, _selectedIndex == 1],
                onPressed: (int newIndex) {
                  setState(() {
                    _selectedIndex = newIndex;
                    _selectedRole = newIndex == 0 ? 'student' : 'teacher';
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text('Student'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text('Teacher'),
                  ),
                ],
                borderRadius: BorderRadius.circular(12),
                borderColor: Colors.grey,
                selectedBorderColor: purpleColor,
                fillColor: purpleColor.withOpacity(0.2),
                selectedColor: purpleColor,
                textStyle: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),

              // Email input
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 16),

              // Password input
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),

              // Loading indicator
              if (_isLoading) CircularProgressIndicator(),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser, // Disable button while loading
                child: Text('Register'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: purpleColor,
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Login link
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  'Already have an account? Log in',
                  style: TextStyle(
                    fontSize: 16,
                    color: purpleColor,
                    decoration: TextDecoration.underline,
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
