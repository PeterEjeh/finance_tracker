import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../widgets/auth_wrapper.dart';
import 'create_password_screen.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final bool isSignup;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.isSignup = false,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  Timer? _timer;
  Timer? _pollTimer;
  bool _isVerified = false;
  bool _canResendEmail = false;
  int _resendCountdown = 60;
  bool _loading = false;
  bool _checkingVerification = false;
  String? _message;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    _listenForAuthChanges();
    _startPollTimer();
  }

  void _startPollTimer() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || _isVerified) {
        timer.cancel();
        return;
      }

      // Reload user data to check if email has been verified
      setState(() {
        _checkingVerification = true;
      });

      try {
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;

        if (user != null && user.emailVerified) {
          timer.cancel();
          if (mounted) {
            _handleEmailVerified();
          }
        }
      } catch (e) {
        // Ignore errors and continue polling
      } finally {
        if (mounted) {
          setState(() {
            _checkingVerification = false;
          });
        }
      }
    });
  }

  void _handleEmailVerified() {
    setState(() {
      _isVerified = true;
      _message = 'Email verified! Redirecting to password creation...';
    });

    // Stop polling timer
    _pollTimer?.cancel();

    // Navigate to password creation screen after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePasswordScreen(email: widget.email),
          ),
        );
      }
    });
  }

  void _manualVerifyEmail() async {
    if (_checkingVerification) return;

    setState(() {
      _checkingVerification = true;
      _message = null;
    });

    try {
      // Force reload user data
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        _handleEmailVerified();
      } else {
        setState(() {
          _message =
              'Email not yet verified. Please check your email and click the verification link.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Failed to check verification status. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingVerification = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenForAuthChanges() {
    _authSubscription = _authService.authStateChanges.listen((User? user) {
      if (user != null && user.emailVerified && mounted) {
        // User has verified their email
        setState(() {
          _isVerified = true;
          _message = 'Email verified! Redirecting to password creation...';
        });

        // Navigate to password creation screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePasswordScreen(email: widget.email),
              ),
            );
          }
        });
      }
    });
  }

  void _startResendCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  void _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await _authService.resendEmailVerification();
      setState(() {
        _message = 'Verification email sent successfully!';
        _canResendEmail = false;
        _resendCountdown = 60;
        _isVerified = false; // Reset verification status when resending
      });
      _startResendCountdown();
    } catch (e) {
      setState(() {
        _message = 'Failed to send verification email. Please try again.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Success Animation or Icon
                  _buildVerificationIcon(),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    _isVerified
                        ? 'Email Verified!'
                        : 'Please Verify Your Email Address',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C2C2C),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    _isVerified
                        ? 'Your email has been verified! Setting up your account...'
                        : 'We\'ve sent a verification link to\n${widget.email}\n\nPlease check your email and click the link to verify your account and continue to password setup.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Message
                  if (_message != null) _buildMessage(),

                  if (!_isVerified) ...[
                    const SizedBox(height: 20),

                    // Manual Verify Button
                    _buildManualVerifyButton(),

                    const SizedBox(height: 20),

                    // Resend Email Button
                    _buildResendButton(),

                    const SizedBox(height: 32),

                    // Instructions
                    _buildInstructions(),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: _isVerified ? Colors.green : const Color(0xFF2C2C2C),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (_isVerified ? Colors.green : const Color(0xFF2C2C2C))
                .withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        _isVerified ? Icons.check : Icons.email_outlined,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  Widget _buildMessage() {
    final isSuccess = _message!.contains('successfully');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Text(
        _message!,
        style: TextStyle(
          color: isSuccess ? Colors.green : Colors.orange.shade700,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _canResendEmail && !_loading
            ? _resendVerificationEmail
            : null,
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
            : Text(
                _canResendEmail
                    ? 'Resend Verification Email'
                    : 'Resend in ${_resendCountdown}s',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildManualVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _checkingVerification ? null : _manualVerifyEmail,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2C2C2C),
          side: BorderSide(color: Theme.of(context).dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).cardColor,
        ),
        child: _checkingVerification
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text(
                    'Check Verification Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '• Check your spam or junk folder\n• Make sure the email address is correct\n• Wait a few minutes for the email to arrive\n• Click the verification link and return to this app\n• If the automatic check doesn\'t work, click "Check Verification Status" above',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
