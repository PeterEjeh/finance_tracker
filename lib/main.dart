// BACKUP OF ORIGINAL main.dart
// This is your original main.dart - saved for reference
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/debug_settings_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'services/database_service.dart';
import 'services/subcategory_service.dart';
import 'services/budget_service.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/settings_service.dart';
import 'services/currency_settings_service.dart';
import 'services/theme_notifier.dart';
import 'constants/app_theme.dart';
import 'services/biometric_auth_service.dart';
import 'services/pin_auth_service.dart';
import 'widgets/authentication_gate.dart';
import 'services/notification_service.dart';
import 'services/reminder_service.dart'; // Import ReminderService
import 'services/budget_auto_end_service.dart'; // Import BudgetAutoEndService
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, kIsWeb;
import 'screens/signup/email_verification_screen.dart';
import 'screens/signup/create_password_screen.dart';
import 'screens/signup/email_link_handler_screen.dart';
import 'package:flutter/services.dart';

Future<void> _handleEmailLinkAuthentication() async {
  // Handle email link authentication for passwordless signup
  final authService = AuthService();

  try {
    // Check if there's a pending signup email in shared preferences
    final prefs = await SharedPreferences.getInstance();
    final pendingEmail = prefs.getString('pending_signup_email');

    if (pendingEmail != null && pendingEmail.isNotEmpty) {
      // Clear the pending email since we're handling it now
      await prefs.remove('pending_signup_email');

      print('Pending signup email found: $pendingEmail');
      // The auth state listener in AuthWrapper will handle the user state
    }
  } catch (e) {
    print('Error handling email link authentication: $e');
  }
}

// Global key to access navigator state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> handleCustomUrlScheme(String url) async {
  // Handle custom URL scheme for email link authentication
  if (url.contains('financetracker.firebaseapp.com/finishSignUp')) {
    // Extract email from URL
    final uri = Uri.parse(url);
    final email = uri.queryParameters['email'];

    if (email != null) {
      // Navigate to email link handler screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => EmailLinkHandlerScreen.fromUrl(url)),
      );
    }
  }
}

// Method channel for handling email links from native Android
const platform = MethodChannel('com.example.finance_tracker/email_link');

Future<void> _setupMethodChannel() async {
  platform.setMethodCallHandler((call) async {
    if (call.method == 'handleEmailLink') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final email = args['email'] as String?;
      final link = args['link'] as String?;

      if (email != null && link != null) {
        // Navigate to email link handler screen
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => EmailLinkHandlerScreen(email: email, link: link),
          ),
        );
      }
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Handle email link authentication for passwordless signup
    await _handleEmailLinkAuthentication();

    // Setup method channel for native email link handling
    await _setupMethodChannel();
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Activating App Check with the correct provider (only for mobile)
  if (!kIsWeb) {
    // await FirebaseAppCheck.instance.activate(
    // androidProvider: kReleaseMode
    // ? AndroidProvider.playIntegrity
    // : AndroidProvider.debug,
    // );
  }

  try {
    await DatabaseService.instance.init();
    await SubcategoryService.init();
    await BudgetService.init();
  } catch (e) {
    print('Database initialization failed: $e');
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Environment loading failed: $e');
  }

  try {
    await SettingsService().init();
    await CurrencySettingsService().init();
  } catch (e) {
    print('Settings initialization failed: $e');
  }

  // Firebase Messaging only works on mobile platforms
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
      await ReminderService().initialize(); // Initialize ReminderService
      await BudgetAutoEndService()
          .initialize(); // Initialize BudgetAutoEndService
    } catch (e) {
      print('Notification/Reminder/BudgetAutoEnd initialization failed: $e');
    }
  }
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider<CurrencySettingsService>(
          create: (_) => CurrencySettingsService(),
        ),
        Provider<ReminderService>(
          create: (_) => ReminderService(),
        ), // Add ReminderService provider
        Provider<BudgetAutoEndService>(
          create: (_) => BudgetAutoEndService(),
        ), // Add BudgetAutoEndService provider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      title: 'Finance Tracker',
      themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      routes: {
        '/debug': (context) => const DebugSettingsScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            // User not logged in - check if onboarding is completed
            return FutureBuilder<bool>(
              future: SettingsService().isOnboardingCompleted(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data == true) {
                    // Check if login is required on app start
                    return FutureBuilder<bool>(
                      future: SettingsService().getRequireLoginOnLaunch(),
                      builder: (context, loginSnapshot) {
                        if (loginSnapshot.connectionState ==
                            ConnectionState.done) {
                          if (loginSnapshot.data == true) {
                            // Login required - check if any auth methods are configured
                            return FutureBuilder<List<bool>>(
                              future: Future.wait([
                                BiometricAuthService()
                                    .isBiometricEnabled()
                                    .then(
                                      (enabled) =>
                                          Future.wait([
                                            Future.value(enabled),
                                            enabled
                                                ? BiometricAuthService()
                                                      .isBiometricAvailable()
                                                : Future.value(false),
                                          ]).then(
                                            (results) =>
                                                results[0] && results[1],
                                          ),
                                    ),
                                PinAuthService().getPinStatus().then(
                                  (status) => status.isConfigured,
                                ),
                              ]),
                              builder: (context, authSnapshot) {
                                if (authSnapshot.connectionState ==
                                    ConnectionState.done) {
                                  final hasBiometric =
                                      authSnapshot.data?[0] ?? false;
                                  final hasPin = authSnapshot.data?[1] ?? false;

                                  if (hasBiometric || hasPin) {
                                    // Has auth methods - use authentication gate
                                    return const AuthenticationGate(
                                      child: LoginScreen(),
                                    );
                                  } else {
                                    // No auth methods - show login screen normally
                                    return const LoginScreen();
                                  }
                                } else {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                              },
                            );
                          } else {
                            // Login not required - show login screen normally
                            return const LoginScreen();
                          }
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    );
                  } else {
                    return const OnboardingScreen();
                  }
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            // User is logged in - show authentication gate only for app launch
            return const AuthenticationGate(
              child: HomeScreen(),
              isAppLaunch: true,
            );
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
