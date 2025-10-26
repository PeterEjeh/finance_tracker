import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinAuthService {
  static final PinAuthService _instance = PinAuthService._internal();
  factory PinAuthService() => _instance;
  PinAuthService._internal();

  static const String _pinKey = 'user_pin';
  static const String _pinEnabledKey = 'pin_enabled';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Check if PIN authentication is enabled
  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  /// Enable or disable PIN authentication
  Future<void> setPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinEnabledKey, enabled);
  }

  /// Set a new PIN
  Future<bool> setPin(String pin) async {
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      return false; // PIN must be exactly 4 digits
    }

    try {
      await _secureStorage.write(key: _pinKey, value: pin);
      await setPinEnabled(true);
      return true;
    } catch (e) {
      print('Error setting PIN: $e');
      return false;
    }
  }

  /// Verify entered PIN
  Future<bool> verifyPin(String enteredPin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) return false;
      return storedPin == enteredPin;
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    try {
      final pin = await _secureStorage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      print('Error checking if PIN is set: $e');
      return false;
    }
  }

  /// Clear PIN
  Future<void> clearPin() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await setPinEnabled(false);
    } catch (e) {
      print('Error clearing PIN: $e');
    }
  }

  /// Get PIN status info
  Future<PinStatus> getPinStatus() async {
    final isSet = await isPinSet();
    final isEnabled = await isPinEnabled();

    return PinStatus(isSet: isSet, isEnabled: isEnabled);
  }
}

class PinStatus {
  final bool isSet;
  final bool isEnabled;

  PinStatus({required this.isSet, required this.isEnabled});

  bool get isConfigured => isSet && isEnabled;
}
