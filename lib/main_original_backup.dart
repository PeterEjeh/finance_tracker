// BACKUP OF ORIGINAL main.dart
// This is your original main.dart - saved for reference
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/debug_settings_screen.dart';
import 'services/database_service.dart';
import 'services/subcategory_service.dart';
import 'services/budget_service.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/settings_service.dart';
import 'services/theme_notifier.dart';
import 'services/biometric_auth_service.dart';
import 'services/pin_auth_service.dart';
import 'widgets/authentication_gate.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Activating App Check with the correct provider
  // await FirebaseAppCheck.instance.activate(
  // androidProvider: kReleaseMode
  // ? AndroidProvider.playIntegrity
  // : AndroidProvider.debug,
  // );

  await DatabaseService.instance.init();
  await SubcategoryService.init();
  await BudgetService.init();
  await dotenv.load(fileName: '.env');
  await SettingsService().init();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
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
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF6C5CE7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0E27),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white),
        ),
      ),
      routes: {'/debug': (context) => const DebugSettingsScreen()},
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
