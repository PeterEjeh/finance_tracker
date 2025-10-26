import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/biometric_auth_service.dart';
import '../services/settings_service.dart';
import '../services/pin_auth_service.dart';
import '../screens/login_screen.dart';
import 'biometric_gate.dart';
import 'pin_gate.dart';

enum AuthMethod { none, biometric, pin, login }

class AuthenticationGate extends StatefulWidget {
  final Widget child;
  final bool isAppLaunch;
  const AuthenticationGate({
    super.key,
    required this.child,
    this.isAppLaunch = true,
  });

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  final PinAuthService _pinService = PinAuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isChecking = true;
  bool _requiresAuthentication = false;
  AuthMethod _authMethod = AuthMethod.none;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationRequirements();
  }

  Future<void> _checkAuthenticationRequirements() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // If this is not an app launch, skip authentication check
      if (!widget.isAppLaunch) {
        setState(() {
          _requiresAuthentication = false;
          _isChecking = false;
        });
        return;
      }

      final settings = SettingsService();
      final requireLogin = await settings.getRequireLoginOnLaunch();

      // If login is not required, allow access
      if (!requireLogin) {
        setState(() {
          _requiresAuthentication = false;
          _isChecking = false;
        });
        return;
      }

      // Check what authentication methods are available
      final biometricEnabled = await _biometricService.isBiometricEnabled();
      final biometricAvailable = await _biometricService.isBiometricAvailable();
      final pinStatus = await _pinService.getPinStatus();

      // Priority: Biometric > PIN > Login
      if (biometricEnabled && biometricAvailable) {
        // Ensure PIN is set before allowing biometric authentication
        if (!pinStatus.isSet) {
          // PIN not set, redirect to login to set PIN first
          setState(() {
            _requiresAuthentication = true;
            _authMethod = AuthMethod.login;
            _isChecking = false;
          });
          _redirectToLogin();
          return;
        }

        setState(() {
          _requiresAuthentication = true;
          _authMethod = AuthMethod.biometric;
          _isChecking = false;
        });
      } else if (pinStatus.isConfigured) {
        setState(() {
          _requiresAuthentication = true;
          _authMethod = AuthMethod.pin;
          _isChecking = false;
        });
      } else {
        // No biometric or PIN configured, don't redirect to login
        // Instead, allow direct access to the child widget
        setState(() {
          _requiresAuthentication = false;
          _isChecking = false;
        });
      }
    } catch (e) {
      print('Error checking authentication requirements: $e');
      setState(() {
        _isChecking = false;
      });
      // On error, redirect to login as fallback
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    // Sign out the user and redirect to login
    _auth.signOut().then((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking authentication...'),
            ],
          ),
        ),
      );
    }

    // If no authentication is required, show the child directly
    if (!_requiresAuthentication) {
      return widget.child;
    }

    // Choose the appropriate authentication method
    switch (_authMethod) {
      case AuthMethod.biometric:
        return BiometricGate(child: widget.child);
      case AuthMethod.pin:
        return PinGate(child: widget.child);
      case AuthMethod.login:
        // This should have been handled by _redirectToLogin()
        _redirectToLogin();
        return const Scaffold(
          body: Center(child: Text('Redirecting to login...')),
        );
      default:
        return const Scaffold(
          body: Center(child: Text('No authentication method configured')),
        );
    }
  }
}
