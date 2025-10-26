import 'package:flutter/material.dart';
import 'package:finance_tracker/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../services/settings_service.dart';
import '../../services/theme_notifier.dart';
import '../../services/biometric_auth_service.dart';
import '../../services/pin_auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/backup_service.dart';
import '../../services/auth_service.dart';
import 'currency_settings_screen.dart';
import 'pin_setup_screen.dart';
import '../cloud_backup/cloud_backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _biometric = false;
  bool _pinEnabled = false;
  bool _notifications = true;
  String? _username;
  bool _requireLoginOnLaunch = false;

  final SettingsService _settingsService = SettingsService();
  final PinAuthService _pinService = PinAuthService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dark = await _settingsService.getDarkMode();
    final bio = await _settingsService.getBiometricAuth();
    final notif = await _settingsService.getNotifications();
    final uname = await _settingsService.getUsername();
    final req = await _settingsService.getRequireLoginOnLaunch();
    final pinStatus = await _pinService.getPinStatus();
    if (!mounted) return;
    setState(() {
      _darkMode = dark;
      _biometric = bio;
      _pinEnabled = pinStatus.isEnabled;
      _notifications = notif;
      _username = uname;
      _requireLoginOnLaunch = req;
    });
  }

  Future<void> _enableBiometric() async {
    setState(() => _biometric = true);
    await BiometricAuthService().setBiometricEnabled(true);

    final ok = await BiometricAuthService().ensureSetupIfEnabled();
    if (!ok && mounted) {
      setState(() => _biometric = false);
      await BiometricAuthService().setBiometricEnabled(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric setup failed or unavailable on this device.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _darkMode,
            onChanged: (v) async {
              setState(() => _darkMode = v);
              await _settingsService.setDarkMode(v);
              Provider.of<ThemeNotifier>(context, listen: false).setDarkMode(v);
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Require login on app start'),
            value: _requireLoginOnLaunch,
            onChanged: (v) async {
              setState(() => _requireLoginOnLaunch = v);
              await _settingsService.setRequireLoginOnLaunch(v);
              if (v) {
                // If "Require login on app start" is enabled, automatically enable PIN
                final pinStatus = await _pinService.getPinStatus();
                if (!pinStatus.isEnabled) {
                  if (pinStatus.isSet) {
                    // PIN is set but not enabled, enable it
                    await _pinService.setPinEnabled(true);
                    setState(() => _pinEnabled = true);
                  } else {
                    // PIN is not set, navigate to PIN setup
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinSetupScreen(),
                      ),
                    );
                    if (result == true) {
                      await _pinService.setPinEnabled(true);
                      setState(() => _pinEnabled = true);
                    } else {
                      // If PIN setup is cancelled, revert "Require login on app start"
                      setState(() => _requireLoginOnLaunch = false);
                      await _settingsService.setRequireLoginOnLaunch(false);
                    }
                  }
                }
              }
            },
            secondary: const Icon(Icons.lock_outline),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Biometric Lock'),
            value: _biometric,
            onChanged: (v) async {
              if (v) {
                // Check if PIN is set before enabling biometric
                final pinStatus = await _pinService.getPinStatus();
                if (!pinStatus.isSet) {
                  // PIN not set, prompt user to set PIN first
                  final shouldSetPin = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('PIN Required'),
                      content: const Text(
                        'You need to set a PIN before enabling biometric authentication. '
                        'Both PIN and biometric authentication will be automatically enabled.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Set PIN'),
                        ),
                      ],
                    ),
                  );

                  if (shouldSetPin == true) {
                    // Navigate to PIN setup
                    final pinResult = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinSetupScreen(),
                      ),
                    );

                    if (pinResult == true) {
                      // PIN set successfully, automatically enable it and then enable biometric
                      await _pinService.setPinEnabled(true);
                      await _enableBiometric();
                      setState(() => _pinEnabled = true);
                    }
                  }
                  return;
                } else {
                  // PIN is already set, check if it's enabled
                  if (!pinStatus.isEnabled) {
                    // PIN is set but not enabled, enable it automatically
                    await _pinService.setPinEnabled(true);
                    setState(() => _pinEnabled = true);
                  }
                  // Enable biometric
                  await _enableBiometric();
                }
              } else {
                // Disable biometric
                setState(() => _biometric = false);
                await BiometricAuthService().setBiometricEnabled(false);
              }
            },
            secondary: const Icon(Icons.fingerprint),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.dialpad),
            title: const Text('PIN Lock'),
            subtitle: Text(_pinEnabled ? 'PIN is enabled' : 'PIN is not set'),
            trailing: Switch(
              value: _pinEnabled,
              onChanged: (v) async {
                if (v) {
                  // Check if PIN already exists
                  final pinStatus = await _pinService.getPinStatus();
                  if (pinStatus.isSet) {
                    // PIN exists, just enable it
                    await _pinService.setPinEnabled(true);
                    setState(() => _pinEnabled = true);
                  } else {
                    // PIN doesn't exist, open setup screen
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinSetupScreen(),
                      ),
                    );
                    if (result == true) {
                      setState(() => _pinEnabled = true);
                    }
                  }
                } else {
                  // Disable PIN
                  await _pinService.setPinEnabled(false);
                  setState(() => _pinEnabled = false);
                }
              },
            ),
          ),
          if (_pinEnabled) ...[
            const Divider(height: 1, indent: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change PIN'),
              subtitle: const Text('Update your 4-digit PIN'),
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PinSetupScreen(),
                  ),
                );
                if (result == true) {
                  // PIN changed successfully, refresh status
                  _load();
                }
              },
            ),
          ],
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: _notifications,
            onChanged: (v) async {
              setState(() => _notifications = v);
              await NotificationService().setNotificationsEnabled(v);
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CurrencySettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Cloud Backup & Restore'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CloudBackupScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Username'),
            subtitle: Text(
              _username == null || _username!.isEmpty ? 'Not set' : _username!,
            ),
            trailing: const Icon(Icons.edit_outlined, size: 20),
            onTap: () async {
              final newName = await showDialog<String>(
                context: context,
                builder: (context) {
                  final controller = TextEditingController(
                    text: _username ?? '',
                  );
                  return AlertDialog(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.surfaceDark
                        : AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Center(
                      child: Text(
                        'Set Username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    content: TextField(
                      controller: controller,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textLight
                            : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter a display name',
                        labelStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textHint
                              : AppColors.textSecondary,
                        ),
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textHint
                              : AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? AppColors.backgroundDark
                            : AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide
                              .none, // Remove border for a cleaner look
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors
                                .primary, // Highlight color when focused
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );
              if (newName != null && newName.isNotEmpty) {
                await _settingsService.setUsername(newName);
                if (!mounted) return;
                setState(() => _username = newName);
              }
            },
          ),
          const Divider(height: 1),

          // Developer Attribution
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'developed by petes-tech',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.5),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
