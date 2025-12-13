import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'studentdashboard.dart'; // Import Student Dashboard screen
import 'teacherdashboard.dart'; // Import Teacher Dashboard screen
import 'register.dart'; // Registration screen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final Color purpleColor = Color(0xFF6200EA);
  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userEmail = _emailController.text.trim();

      // Retrieve role from the 'users' collection
      final userQuery = await FirebaseFirestore.instance
          .collection('users') // Fetch role from 'users' collection
          .where('email', isEqualTo: userEmail)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first.data();
        final role = userDoc['role'];

        if (role == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role is not defined')),
          );
          return;
        }

        if (role.toLowerCase() == 'student') {
          // Now retrieve student details from the 'students' collection
          final studentQuery = await FirebaseFirestore.instance
              .collection('students')
              .where('email', isEqualTo: userEmail)
              .get();

          if (studentQuery.docs.isNotEmpty) {
            final studentDoc = studentQuery.docs.first.data();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainStudentScreen(
                  name: studentDoc['name'] ?? 'Unknown Name',
                  email: studentDoc['email'] ?? 'Unknown Email',
                  registerNo: studentDoc['registerNo'] ?? 'N/A',
                  studentClass: studentDoc['class'] ?? 'N/A',
                  section: studentDoc['section'] ?? 'N/A',
                  department: studentDoc['department'] ?? 'N/A',
                  hostelDaysScholar: studentDoc['hostelDaysScholar'] ?? '0',
                  batch: studentDoc['batch'] ?? 'N/A', // Add batch field
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Student details not found')),
            );
          }
        } else if (role.toLowerCase() == 'teacher') {
          // Now retrieve teacher details from the 'teachers' collection
          final teacherQuery = await FirebaseFirestore.instance
              .collection('teachers')
              .where('email', isEqualTo: userEmail)
              .get();

          if (teacherQuery.docs.isNotEmpty) {
            final teacherDoc = teacherQuery.docs.first.data();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherDashboard(
                  name: teacherDoc['name'] ?? 'Unknown Name',
                  email: teacherDoc['email'] ?? 'Unknown Email',
                  department: teacherDoc['department'] ?? 'N/A',
                  phoneNumber: teacherDoc['phoneNumber'] ?? 'N/A',
              
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Teacher details not found')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role not recognized')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found in database')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // Remove AppBar
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

              // Login Button
              ElevatedButton(
                onPressed: _loginUser,
                child: Text('Login'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Registration link
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrationScreen(),
                    ),
                  );
                },
                child: Text(
                  "Don't have an account? Register",
                  style: TextStyle(
                    fontSize: 16,
                    color: purpleColor, // Change to your desired color
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
