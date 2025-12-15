import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import for kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'register.dart'; // Adjust this according to your project structure

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with the Web options
  const firebaseOptions = FirebaseOptions(
   
    appId: "1:889803755047:web:56af6c483cfbf035ed8802",
    messagingSenderId: "889803755047",
    projectId: "grievance-83b1c",
    storageBucket: "grievance-83b1c.appspot.com",
    measurementId: "G-EX94X6J1TY",
  );

  try {
    if (kIsWeb) {
      // If running on the web, use the Firebase options
      await Firebase.initializeApp(options: firebaseOptions);
    } else {
      // For mobile platforms, just initialize Firebase normally
      await Firebase.initializeApp();
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grievance App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: RegistrationScreen(), // Set the registration screen as the home page
    );
  }
}

