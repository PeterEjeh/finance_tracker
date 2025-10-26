import 'package:flutter/material.dart';
import 'settings_service.dart';

class ThemeNotifier extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  ThemeNotifier() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isDarkMode = await _settingsService.getDarkMode();
    } catch (_) {
      _isDarkMode = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    notifyListeners();
    await _settingsService.setDarkMode(enabled);
  }
}
