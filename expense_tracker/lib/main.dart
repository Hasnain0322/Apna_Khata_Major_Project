// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/firebase_options.dart';
import 'package:expense_tracker/screens/auth_gate.dart';
import 'package:expense_tracker/utils/app_theme.dart'; // Import the theme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intelligent Expense Tracker',
      theme: AppTheme.darkTheme, // Apply our custom dark theme
      home: const AuthGate(),
      debugShowCheckedModeBanner: false, // Clean up the UI
    );
  }
}