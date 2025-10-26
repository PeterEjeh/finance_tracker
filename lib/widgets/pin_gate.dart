import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pin_auth_service.dart';
import '../screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinGate extends StatefulWidget {
  final Widget child;
  final bool isAppLaunch;
  const PinGate({super.key, required this.child, this.isAppLaunch = true});

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> {
  final PinAuthService _pinService = PinAuthService();
  final TextEditingController _pinController = TextEditingController();
  String _enteredPin = '';
  bool _isChecking = true;
  bool _isUnlocked = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPinRequirement();
  }

  Future<void> _checkPinRequirement() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // If this is not an app launch, skip PIN requirement check
      if (!widget.isAppLaunch) {
        setState(() {
          _isUnlocked = true;
          _isChecking = false;
        });
        return;
      }

      final pinStatus = await _pinService.getPinStatus();

      if (!pinStatus.isConfigured) {
        // If PIN is not configured, redirect to login
        setState(() {
          _isChecking = false;
        });
        _redirectToLogin();
        return;
      }

      setState(() {
        _isChecking = false;
      });
    } catch (e) {
      print('Error checking PIN requirement: $e');
      setState(() {
        _isChecking = false;
      });
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    FirebaseAuth.instance.signOut().then((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  void _onPinChanged(String value) {
    setState(() {
      _enteredPin = value;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final isValid = await _pinService.verifyPin(_enteredPin);

      if (isValid) {
        setState(() {
          _isUnlocked = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _enteredPin = '';
        });
        _pinController.clear();
      }
    } catch (e) {
      print('Error verifying PIN: $e');
      setState(() {
        _errorMessage = 'Error verifying PIN. Please try again.';
        _enteredPin = '';
      });
      _pinController.clear();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Widget _buildPinDot(int index, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index < _enteredPin.length
            ? theme.primaryColor
            : (isDark ? Colors.grey[600] : Colors.grey[300]),
      ),
    );
  }

  Widget _buildNumberButton(String number, ThemeData theme) {
    return InkWell(
      onTap: _enteredPin.length < 4
          ? () => _onPinChanged(_enteredPin + number)
          : null,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          number,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isChecking) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Checking PIN settings...',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
            ],
          ),
        ),
      );
    }

    if (_isUnlocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(height: 24),
              Text(
                'Enter PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 4-digit PIN to access your financial data',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => _buildPinDot(index, theme),
                ),
              ),

              const SizedBox(height: 32),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Number pad
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildNumberButton('1', theme),
                    _buildNumberButton('2', theme),
                    _buildNumberButton('3', theme),
                    _buildNumberButton('4', theme),
                    _buildNumberButton('5', theme),
                    _buildNumberButton('6', theme),
                    _buildNumberButton('7', theme),
                    _buildNumberButton('8', theme),
                    _buildNumberButton('9', theme),
                    const SizedBox(), // Empty space
                    _buildNumberButton('0', theme),
                    // Backspace button
                    InkWell(
                      onTap: _onBackspace,
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        width: 80,
                        height: 80,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.backspace_outlined,
                          size: 24,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Alternative options
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    icon: Icon(
                      Icons.login,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    label: Text(
                      'Use Password Instead',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
