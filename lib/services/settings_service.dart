import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _darkModeKey = 'dark_mode';
  static const String _biometricAuthKey = 'biometric_auth';
  static const String _notificationsKey = 'notifications';
  static const String _currencyKey = 'currency';
  static const String _languageKey = 'language';
  static const String _backupEnabledKey = 'backup_enabled';
  static const String _lastBackupKey = 'last_backup';
  static const String _budgetAlertsKey = 'budget_alerts';
  static const String _expenseTrackingKey = 'expense_tracking';
  static const String _autoSyncKey = 'auto_sync';
  static const String _exportFormatKey = 'export_format';
  static const String _firstLaunchKey = 'first_launch';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _usernameKey = 'username';
  static const String _requireLoginOnLaunchKey = 'require_login_on_launch';

  SharedPreferences? _prefs;

  /// Initialize the settings service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Dark Mode Settings
  Future<bool> getDarkMode() async {
    final prefs = await _preferences;
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = await _preferences;
    await prefs.setBool(_darkModeKey, isDarkMode);
  }

  // Biometric Authentication Settings
  Future<bool> getBiometricAuth() async {
    final prefs = await _preferences;
    return prefs.getBool(_biometricAuthKey) ?? false;
  }

  Future<void> setBiometricAuth(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_biometricAuthKey, enabled);
  }

  // Notification Settings
  Future<bool> getNotifications() async {
    final prefs = await _preferences;
    return prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotifications(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_notificationsKey, enabled);
  }

  // Currency Settings
  Future<String> getCurrency() async {
    final prefs = await _preferences;
    return prefs.getString(_currencyKey) ?? 'NGN';
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await _preferences;
    await prefs.setString(_currencyKey, currency);
  }

  // Language Settings
  Future<String> getLanguage() async {
    final prefs = await _preferences;
    return prefs.getString(_languageKey) ?? 'en';
  }

  Future<void> setLanguage(String language) async {
    final prefs = await _preferences;
    await prefs.setString(_languageKey, language);
  }

  // Backup Settings
  Future<bool> getBackupEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_backupEnabledKey) ?? true;
  }

  Future<void> setBackupEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_backupEnabledKey, enabled);
  }

  Future<DateTime?> getLastBackup() async {
    final prefs = await _preferences;
    final timestamp = prefs.getInt(_lastBackupKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setLastBackup(DateTime dateTime) async {
    final prefs = await _preferences;
    await prefs.setInt(_lastBackupKey, dateTime.millisecondsSinceEpoch);
  }

  // Budget Alerts Settings
  Future<bool> getBudgetAlerts() async {
    final prefs = await _preferences;
    return prefs.getBool(_budgetAlertsKey) ?? true;
  }

  Future<void> setBudgetAlerts(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_budgetAlertsKey, enabled);
  }

  // Expense Tracking Settings
  Future<bool> getExpenseTracking() async {
    final prefs = await _preferences;
    return prefs.getBool(_expenseTrackingKey) ?? true;
  }

  Future<void> setExpenseTracking(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_expenseTrackingKey, enabled);
  }

  // Auto Sync Settings
  Future<bool> getAutoSync() async {
    final prefs = await _preferences;
    return prefs.getBool(_autoSyncKey) ?? true;
  }

  Future<void> setAutoSync(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_autoSyncKey, enabled);
  }

  // Export Format Settings
  Future<String> getExportFormat() async {
    final prefs = await _preferences;
    return prefs.getString(_exportFormatKey) ?? 'PDF';
  }

  Future<void> setExportFormat(String format) async {
    final prefs = await _preferences;
    await prefs.setString(_exportFormatKey, format);
  }

  // First Launch Detection
  Future<bool> isFirstLaunch() async {
    final prefs = await _preferences;
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    final prefs = await _preferences;
    await prefs.setBool(_firstLaunchKey, false);
  }

  // Onboarding Settings
  Future<bool> isOnboardingCompleted() async {
    final prefs = await _preferences;
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    final prefs = await _preferences;
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  // Username
  Future<String?> getUsername() async {
    final prefs = await _preferences;
    final value = prefs.getString(_usernameKey);
    if (value != null && value.trim().isEmpty) return null;
    return value;
  }

  Future<void> setUsername(String? username) async {
    final prefs = await _preferences;
    if (username == null || username.trim().isEmpty) {
      await prefs.remove(_usernameKey);
    } else {
      await prefs.setString(_usernameKey, username.trim());
    }
  }

  // Require login on app start
  Future<bool> getRequireLoginOnLaunch() async {
    final prefs = await _preferences;
    return prefs.getBool(_requireLoginOnLaunchKey) ?? false;
  }

  Future<void> setRequireLoginOnLaunch(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_requireLoginOnLaunchKey, enabled);
  }

  /// Get all settings as a map
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'darkMode': await getDarkMode(),
      'biometricAuth': await getBiometricAuth(),
      'notifications': await getNotifications(),
      'currency': await getCurrency(),
      'language': await getLanguage(),
      'backupEnabled': await getBackupEnabled(),
      'lastBackup': await getLastBackup(),
      'budgetAlerts': await getBudgetAlerts(),
      'expenseTracking': await getExpenseTracking(),
      'autoSync': await getAutoSync(),
      'exportFormat': await getExportFormat(),
      'firstLaunch': await isFirstLaunch(),
      'onboardingCompleted': await isOnboardingCompleted(),
      'username': await getUsername(),
      'requireLoginOnLaunch': await getRequireLoginOnLaunch(),
    };
  }

  /// Reset all settings to default
  Future<void> resetAllSettings() async {
    final prefs = await _preferences;
    await prefs.clear();
  }

  /// Export settings as JSON
  Future<String> exportSettingsAsJson() async {
    final settings = await getAllSettings();
    final settingsJson = {
      'settings': settings,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    return settingsJson.toString();
  }
}

/// Settings model for type safety
class AppSettings {
  final bool darkMode;
  final bool biometricAuth;
  final bool notifications;
  final String currency;
  final String language;
  final bool backupEnabled;
  final DateTime? lastBackup;
  final bool budgetAlerts;
  final bool expenseTracking;
  final bool autoSync;
  final String exportFormat;
  final bool firstLaunch;
  final bool onboardingCompleted;
  final String? username;

  AppSettings({
    required this.darkMode,
    required this.biometricAuth,
    required this.notifications,
    required this.currency,
    required this.language,
    required this.backupEnabled,
    this.lastBackup,
    required this.budgetAlerts,
    required this.expenseTracking,
    required this.autoSync,
    required this.exportFormat,
    required this.firstLaunch,
    required this.onboardingCompleted,
    this.username,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      darkMode: json['darkMode'] ?? false,
      biometricAuth: json['biometricAuth'] ?? false,
      notifications: json['notifications'] ?? true,
      currency: json['currency'] ?? 'NGN',
      language: json['language'] ?? 'en',
      backupEnabled: json['backupEnabled'] ?? true,
      lastBackup: json['lastBackup'] != null
          ? DateTime.parse(json['lastBackup'])
          : null,
      budgetAlerts: json['budgetAlerts'] ?? true,
      expenseTracking: json['expenseTracking'] ?? true,
      autoSync: json['autoSync'] ?? true,
      exportFormat: json['exportFormat'] ?? 'PDF',
      firstLaunch: json['firstLaunch'] ?? true,
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'biometricAuth': biometricAuth,
      'notifications': notifications,
      'currency': currency,
      'language': language,
      'backupEnabled': backupEnabled,
      'lastBackup': lastBackup?.toIso8601String(),
      'budgetAlerts': budgetAlerts,
      'expenseTracking': expenseTracking,
      'autoSync': autoSync,
      'exportFormat': exportFormat,
      'firstLaunch': firstLaunch,
      'onboardingCompleted': onboardingCompleted,
      'username': username,
    };
  }

  AppSettings copyWith({
    bool? darkMode,
    bool? biometricAuth,
    bool? notifications,
    String? currency,
    String? language,
    bool? backupEnabled,
    DateTime? lastBackup,
    bool? budgetAlerts,
    bool? expenseTracking,
    bool? autoSync,
    String? exportFormat,
    bool? firstLaunch,
    bool? onboardingCompleted,
    String? username,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      notifications: notifications ?? this.notifications,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      backupEnabled: backupEnabled ?? this.backupEnabled,
      lastBackup: lastBackup ?? this.lastBackup,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      expenseTracking: expenseTracking ?? this.expenseTracking,
      autoSync: autoSync ?? this.autoSync,
      exportFormat: exportFormat ?? this.exportFormat,
      firstLaunch: firstLaunch ?? this.firstLaunch,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      username: username ?? this.username,
    );
  }
}
