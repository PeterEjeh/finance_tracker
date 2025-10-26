import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/biometric_auth_service.dart';
import '../services/settings_service.dart';
import '../screens/login_screen.dart';

class BiometricGate extends StatefulWidget {
  final Widget child;
  final bool isAppLaunch;
  const BiometricGate({
    super.key,
    required this.child,
    this.isAppLaunch = true,
  });

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isChecking = true;
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    _checkAndAuthenticate();
  }

  Future<void> _checkAndAuthenticate() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // If this is not an app launch, skip authentication check
      if (!widget.isAppLaunch) {
        setState(() {
          _isUnlocked = true;
          _isChecking = false;
        });
        return;
      }

      final settings = SettingsService();
      final requireLogin = await settings.getRequireLoginOnLaunch();
      final biometricEnabled = await _biometricService.isBiometricEnabled();

      // If login is not required, always allow access
      if (!requireLogin) {
        setState(() {
          _isUnlocked = true;
          _isChecking = false;
        });
        return;
      }

      // If biometric is enabled and available, try to authenticate
      if (biometricEnabled && await _biometricService.isBiometricAvailable()) {
        final result = await _biometricService.authenticate(
          reason: 'Unlock Finance Tracker',
          biometricOnly: false,
        );
        setState(() {
          _isUnlocked = result == AuthResult.success;
          _isChecking = false;
        });
      } else {
        // If biometric is not available or not enabled, but requireLogin is true,
        // redirect to login screen instead of blocking access
        setState(() {
          _isChecking = false;
        });
        _redirectToLogin();
      }
    } catch (_) {
      setState(() {
        _isChecking = false;
      });
      // On error, redirect to login screen as fallback
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    // Navigate to login screen and replace the current route
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isUnlocked) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Authentication required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please authenticate to access your financial data',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkAndAuthenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Try Biometric Again'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                // Sign out and redirect to login screen
                FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.login),
              label: const Text('Use Password Instead'),
            ),
            const SizedBox(height: 16),
            // Debug button - remove this in production
            if (const bool.fromEnvironment('dart.vm.product') == false)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/debug');
                },
                child: const Text(
                  'Debug Settings',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
