import 'package:flutter/material.dart';
import 'package:finance_tracker/services/auth_service.dart';

class VerificationFailureScreen extends StatelessWidget {
  final String email;
  const VerificationFailureScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 100),
              const SizedBox(height: 20),
              const Text(
                'Email Verification Failed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'The verification link is invalid, expired, or has already been used. Please request a new verification email.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await authService.resendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('A new verification email has been sent.'),
                    ),
                  );
                },
                child: const Text('Resend Verification Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
