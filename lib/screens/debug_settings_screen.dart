import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/biometric_auth_service.dart';

class DebugSettingsScreen extends StatefulWidget {
  const DebugSettingsScreen({super.key});

  @override
  State<DebugSettingsScreen> createState() => _DebugSettingsScreenState();
}

class _DebugSettingsScreenState extends State<DebugSettingsScreen> {
  final SettingsService _settings = SettingsService();
  final BiometricAuthService _biometric = BiometricAuthService();
  
  Map<String, dynamic> _allSettings = {};
  bool _loading = true;
  BiometricCapability? _biometricCapability;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final settings = await _settings.getAllSettings();
      final capability = await _biometric.getBiometricCapability();
      
      setState(() {
        _allSettings = settings;
        _biometricCapability = capability;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading debug info: $e')),
      );
    }
  }

  Future<void> _resetCriticalSettings() async {
    try {
      // Reset the problematic settings
      await _settings.setRequireLoginOnLaunch(false);
      await _settings.setBiometricAuth(false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Critical settings reset! Please restart the app.'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadDebugInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resetting settings: $e')),
      );
    }
  }

  Future<void> _testBiometric() async {
    try {
      final result = await _biometric.authenticate(
        reason: 'Testing biometric authentication',
        biometricOnly: false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Biometric test result: ${result.toString()}'),
          backgroundColor: result == AuthResult.success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error testing biometric: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Fix Section
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Fix',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'If you\'re stuck on the "Authentication required" screen, click the button below to reset critical settings:',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _resetCriticalSettings,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset Login & Biometric Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Biometric Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Biometric Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_biometricCapability != null) ...[
                      _buildInfoRow('Available', _biometricCapability!.isAvailable),
                      _buildInfoRow('Enabled in Settings', _biometricCapability!.isEnabled),
                      _buildInfoRow('Available Types', _biometricCapability!.availableTypes.map((e) => e.toString()).join(', ')),
                      _buildInfoRow('Primary Type', _biometricCapability!.primaryBiometricName),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _testBiometric,
                        child: const Text('Test Biometric Authentication'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // All Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._allSettings.entries.map((entry) {
                      return _buildInfoRow(entry.key, entry.value);
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    Color? color;
    if (label == 'requireLoginOnLaunch' && value == true) {
      color = Colors.red.shade100;
    } else if (label == 'biometricAuth' && value == true) {
      color = Colors.orange.shade100;
    }
    
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.toString(),
              style: TextStyle(
                color: value is bool
                    ? (value ? Colors.green : Colors.grey)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
