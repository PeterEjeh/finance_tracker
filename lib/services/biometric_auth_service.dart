import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SettingsService _settingsService = SettingsService();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometric authentication is enabled in settings
  Future<bool> isBiometricEnabled() async {
    return await _settingsService.getBiometricAuth();
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _settingsService.setBiometricAuth(enabled);
  }

  /// Force user to perform a setup if they enabled biometrics in settings
  /// Returns true if successfully set up, false otherwise
  Future<bool> ensureSetupIfEnabled() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return true;
    final capability = await getBiometricCapability();
    if (!capability.isAvailable || capability.availableTypes.isEmpty) {
      return false;
    }
    final result = await authenticate(
      reason: 'Enable biometric login for Finance Tracker',
      biometricOnly: true,
    );
    return result == AuthResult.success;
  }

  /// Authenticate using biometrics
  Future<AuthResult> authenticate({
    String reason = 'Please verify your identity to access your finance data',
    bool biometricOnly = true,
  }) async {
    try {
      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        return AuthResult.notAvailable;
      }

      // Check if biometric is enabled in settings
      if (!await isBiometricEnabled()) {
        return AuthResult.disabled;
      }

      // Perform authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Authenticate to continue',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Device credentials required',
            deviceCredentialsSetupDescription:
                'Please set up device credentials',
            goToSettingsButton: 'Go to Settings',
            goToSettingsDescription: 'Set up your fingerprint or face unlock',
          ),
        ],
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate ? AuthResult.success : AuthResult.failed;
    } on PlatformException catch (e) {
      print('Authentication error: $e');

      switch (e.code) {
        case 'NotEnrolled':
          return AuthResult.notEnrolled;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          return AuthResult.lockedOut;
        case 'NotAvailable':
          return AuthResult.notAvailable;
        case 'UserCancel':
          return AuthResult.cancelled;
        case 'PasscodeNotSet':
          return AuthResult.notSetup;
        default:
          return AuthResult.failed;
      }
    } catch (e) {
      print('Unexpected authentication error: $e');
      return AuthResult.failed;
    }
  }

  /// Get biometric type display name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get status message for authentication result
  String getAuthResultMessage(AuthResult result) {
    switch (result) {
      case AuthResult.success:
        return 'Authentication successful';
      case AuthResult.failed:
        return 'Authentication failed. Please try again.';
      case AuthResult.cancelled:
        return 'Authentication cancelled by user';
      case AuthResult.notAvailable:
        return 'Biometric authentication is not available on this device';
      case AuthResult.notEnrolled:
        return 'No biometrics enrolled. Please set up fingerprint or face ID in device settings.';
      case AuthResult.notSetup:
        return 'Device lock screen not set up. Please set up PIN, pattern, or password.';
      case AuthResult.lockedOut:
        return 'Authentication locked out. Please try again later.';
      case AuthResult.disabled:
        return 'Biometric authentication is disabled in app settings';
    }
  }

  /// Check if we should show biometric prompt for app launch
  Future<bool> shouldAuthenticateOnLaunch() async {
    return await isBiometricEnabled() && await isBiometricAvailable();
  }

  /// Set up biometric authentication (show enrollment dialog)
  Future<AuthSetupResult> setupBiometric() async {
    try {
      // Check if device supports biometrics
      if (!await isBiometricAvailable()) {
        return AuthSetupResult.notSupported;
      }

      // Check if biometrics are already enrolled
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return AuthSetupResult.notEnrolled;
      }

      // Try to authenticate to verify setup
      final result = await authenticate(
        reason: 'Verify biometric setup for Finance Tracker',
        biometricOnly: true,
      );

      switch (result) {
        case AuthResult.success:
          await setBiometricEnabled(true);
          return AuthSetupResult.success;
        case AuthResult.notEnrolled:
          return AuthSetupResult.notEnrolled;
        case AuthResult.notAvailable:
          return AuthSetupResult.notSupported;
        case AuthResult.cancelled:
          return AuthSetupResult.cancelled;
        default:
          return AuthSetupResult.failed;
      }
    } catch (e) {
      print('Error setting up biometric: $e');
      return AuthSetupResult.failed;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    await setBiometricEnabled(false);
  }

  /// Get biometric capability info
  Future<BiometricCapability> getBiometricCapability() async {
    final isAvailable = await isBiometricAvailable();
    final biometricTypes = await getAvailableBiometrics();
    final isEnabled = await isBiometricEnabled();

    return BiometricCapability(
      isAvailable: isAvailable,
      availableTypes: biometricTypes,
      isEnabled: isEnabled,
    );
  }
}

enum AuthResult {
  success,
  failed,
  cancelled,
  notAvailable,
  notEnrolled,
  notSetup,
  lockedOut,
  disabled,
}

enum AuthSetupResult { success, failed, cancelled, notSupported, notEnrolled }

class BiometricCapability {
  final bool isAvailable;
  final List<BiometricType> availableTypes;
  final bool isEnabled;

  BiometricCapability({
    required this.isAvailable,
    required this.availableTypes,
    required this.isEnabled,
  });

  bool get hasFaceID => availableTypes.contains(BiometricType.face);
  bool get hasFingerprint => availableTypes.contains(BiometricType.fingerprint);
  bool get hasIris => availableTypes.contains(BiometricType.iris);

  String get primaryBiometricName {
    if (hasFaceID) return 'Face ID';
    if (hasFingerprint) return 'Fingerprint';
    if (hasIris) return 'Iris';
    return 'Biometric';
  }
}
