import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../legal/legal_document_screen.dart';
import '../onboarding/onboarding_flow_screen.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingFlowScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _sendVerificationEmail() async {
    if (!_agreedToTerms) {
      setState(() {
        _error = 'You must agree to the Terms of Service and Privacy Policy.';
      });
      return;
    }

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error = 'Please enter your email address';
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _error = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // First check if email already exists
      final emailExists = await _authService.checkEmailExists(email);

      if (emailExists) {
        // Email exists, send password reset instead
        await _authService.resetPassword(email);
        setState(() {
          _error =
              'An account with this email already exists. We\'ve sent you a password reset link.';
        });
        return;
      }

      try {
        // Store signup information for verification
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_signup_email', email);
        await prefs.setInt(
          'pending_signup_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );

        // Send email verification for signup (without creating account yet)
        await _authService.sendEmailVerificationForSignup(email);

        // Navigate to email verification screen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EmailVerificationScreen(email: email, isSignup: true),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } catch (e) {
      // Only show error if it's not handled by the fallback logic above
      if (!e.toString().contains('operation-not-allowed')) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        // Provide more specific error messages for common issues
        if (errorMessage.contains('network') ||
            errorMessage.contains('Network')) {
          errorMessage = 'Please check your internet connection and try again.';
        } else if (errorMessage.contains('timeout') ||
            errorMessage.contains('Timeout')) {
          errorMessage = 'The request timed out. Please try again.';
        } else if (errorMessage.contains('Something went wrong')) {
          errorMessage = 'Unable to process your request. Please try again.';
        }

        setState(() {
          _error = errorMessage;
        });
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Enter your email to get started. We\'ll send you a verification link to confirm your email address.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 60),

                // Error Message
                if (_error != null) _buildErrorMessage(),

                // Email Field
                _buildEmailField(),

                const SizedBox(height: 40),

                // Continue Button
                _buildContinueButton(),

                const SizedBox(height: 24),

                // Google Sign In Button
                _buildGoogleSignInButton(),

                const SizedBox(height: 24),

                // Terms and Privacy
                _buildTermsAndConditions(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    // Check if this is actually a success message (password reset sent)
    final isSuccess = _error!.contains('password reset link');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Text(
        _error!,
        style: TextStyle(
          color: isSuccess ? Colors.green : Colors.red,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1F3A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'hello@financetracker.com',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF666666),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onSubmitted: (_) => _sendVerificationEmail(),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading || !_agreedToTerms ? null : _sendVerificationEmail,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: const Color(0xFF2C2C2C).withOpacity(0.6),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value!;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF666666),
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LegalDocumentScreen(
                            title: 'Terms of Service',
                            mdFile: 'terms_of_service.md',
                          ),
                        ),
                      );
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LegalDocumentScreen(
                            title: 'Privacy Policy',
                            mdFile: 'privacy_policy.md',
                          ),
                        ),
                      );
                    },
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).cardColor,
        ),
        icon: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/g-logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
