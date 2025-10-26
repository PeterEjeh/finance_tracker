import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import 'create_password_screen.dart';

class EmailLinkHandlerScreen extends StatefulWidget {
  final String? email;
  final String? link;

  const EmailLinkHandlerScreen({super.key, this.email, this.link});

  @override
  State<EmailLinkHandlerScreen> createState() => _EmailLinkHandlerScreenState();

  // Static method to create the screen from a URL
  static EmailLinkHandlerScreen fromUrl(String url) {
    // Extract email from URL parameters
    final uri = Uri.parse(url);
    final email = uri.queryParameters['email'];
    return EmailLinkHandlerScreen(email: email, link: url);
  }
}

class _EmailLinkHandlerScreenState extends State<EmailLinkHandlerScreen> {
  final AuthService _authService = AuthService();
  bool _isProcessing = true;
  String? _error;
  String? _email;

  @override
  void initState() {
    super.initState();
    _processEmailLink();
  }

  Future<void> _processEmailLink() async {
    try {
      setState(() {
        _isProcessing = true;
        _error = null;
      });

      // Get email from widget or shared preferences
      _email = widget.email ?? await _getPendingEmail();

      if (_email == null || widget.link == null) {
        throw Exception('Missing email or link information');
      }

      // Complete the email link sign-in
      await _authService.completeEmailLinkSignIn(
        email: _email!,
        emailLink: widget.link!,
      );

      // Clear the pending email from storage
      await _clearPendingEmail();

      // Navigate to password creation screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePasswordScreen(email: _email!),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
      });
    }
  }

  Future<String?> _getPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pending_signup_email');
  }

  Future<void> _clearPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_signup_email');
    await prefs.remove('pending_signup_timestamp');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Verifying your email...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_error != null) ...[
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  'Verification Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
