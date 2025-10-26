import 'package:flutter/material.dart';
import 'dart:async';

import 'package:finance_tracker/screens/signup/create_password_screen.dart';

class VerificationSuccessScreen extends StatefulWidget {
  final String email;
  const VerificationSuccessScreen({super.key, required this.email});

  @override
  State<VerificationSuccessScreen> createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CreatePasswordScreen(email: widget.email),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text(
              'Email Verified Successfully!',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
