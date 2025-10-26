import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/biometric_auth_service.dart';

class SecuritySettingsSection extends StatefulWidget {
  const SecuritySettingsSection({super.key});

  @override
  State<SecuritySettingsSection> createState() => _SecuritySettingsSectionState();
}

class _SecuritySettingsSectionState extends State<SecuritySettingsSection> {
  final SettingsService _settings = SettingsService();
  final BiometricAuthService _biometric = BiometricAuthService();
  
  bool _requireLogin = false;
  bool _biometricEnabled = false;
  BiometricCapability? _biometricCapability;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final requireLogin = await _settings.getRequireLoginOnLaunch();
      final biometricEnabled = await _settings.getBiometricAuth();
      final capability = await _biometric.getBiometricCapability();
      
      setState(() {
        _requireLogin = requireLogin;
        _biometricEnabled = biometricEnabled;
        _biometricCapability = capability;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _toggleRequireLogin(bool value) async {
    if (!value) {
      // If disabling login requirement, also disable biometrics
      await _settings.setRequireLoginOnLaunch(false);
      await _settings.setBiometricAuth(false);
      setState(() {
        _requireLogin = false;
        _biometricEnabled = false;
      });
    } else {
      await _settings.setRequireLoginOnLaunch(true);
      setState(() {
        _requireLogin = true;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Check if biometric is available
      if (_biometricCapability?.isAvailable != true) {
        _showBiometricNotAvailableDialog();
        return;
      }

      // Try to authenticate to enable biometric
      final result = await _biometric.authenticate(
        reason: 'Enable biometric authentication for Finance Tracker',
        biometricOnly: true,
      );

      if (result == AuthResult.success) {
        await _settings.setBiometricAuth(true);
        setState(() {
          _biometricEnabled = true;
        });
        _showSuccessMessage('Biometric authentication enabled');
      } else {
        _showErrorMessage('Failed to enable biometric authentication: ${_biometric.getAuthResultMessage(result)}');
      }
    } else {
      await _settings.setBiometricAuth(false);
      setState(() {
        _biometricEnabled = false;
      });
    }
  }

  void _showBiometricNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Authentication Not Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biometric authentication is not available on this device.'),
            const SizedBox(height: 12),
            const Text('Possible reasons:'),
            const SizedBox(height: 8),
            const Text('• No biometric sensors (fingerprint, face, etc.)'),
            const Text('• Biometrics not set up in device settings'),
            const Text('• Device security requirements not met'),
            const SizedBox(height: 12),
            const Text('When you enable "Require login on launch" without biometrics, you\'ll need to enter your password each time you open the app.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Security Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Require Login Toggle
            SwitchListTile(
              title: const Text('Require login on app start'),
              subtitle: Text(
                _requireLogin 
                  ? 'You must authenticate when opening the app'
                  : 'App opens directly to your dashboard',
              ),
              value: _requireLogin,
              onChanged: _toggleRequireLogin,
            ),
            
            const Divider(),
            
            // Biometric Authentication Toggle
            SwitchListTile(
              title: Row(
                children: [
                  const Text('Biometric Authentication'),
                  if (_biometricCapability?.isAvailable == true) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _biometricCapability!.hasFaceID 
                        ? Icons.face 
                        : Icons.fingerprint,
                      size: 16,
                      color: Colors.green,
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_requireLogin)
                    const Text(
                      'Enable "Require login on app start" first',
                      style: TextStyle(color: Colors.orange),
                    )
                  else if (_biometricCapability?.isAvailable != true)
                    const Text(
                      'Not available on this device',
                      style: TextStyle(color: Colors.red),
                    )
                  else if (_biometricEnabled)
                    Text('Use ${_biometricCapability!.primaryBiometricName} to unlock')
                  else
                    const Text('Use password login instead'),
                ],
              ),
              value: _biometricEnabled,
              onChanged: _requireLogin ? _toggleBiometric : null,
            ),
            
            if (_requireLogin && _biometricCapability?.isAvailable != true)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'With login required but no biometrics, you\'ll need to enter your password each time you open the app.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
