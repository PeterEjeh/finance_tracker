import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/database_service.dart';
import 'services/subcategory_service.dart';
import 'services/budget_service.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/theme_notifier.dart';
import 'widgets/authentication_gate.dart';
import 'services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  try {
    print('🚀 Starting Finance Tracker...');
    
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter binding initialized');
    
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase initialized');
    
    // Initialize services one by one with error handling
    try {
      await DatabaseService.instance.init();
      print('✅ Database service initialized');
    } catch (e) {
      print('❌ Database service failed: $e');
    }
    
    try {
      await SubcategoryService.init();
      print('✅ Subcategory service initialized');
    } catch (e) {
      print('❌ Subcategory service failed: $e');
    }
    
    try {
      await BudgetService.init();
      print('✅ Budget service initialized');
    } catch (e) {
      print('❌ Budget service failed: $e');
    }
    
    try {
      await SettingsService().init();
      print('✅ Settings service initialized');
    } catch (e) {
      print('❌ Settings service failed: $e');
    }
    
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      print('✅ Firebase messaging configured');
    } catch (e) {
      print('❌ Firebase messaging failed: $e');
    }
    
    try {
      await NotificationService().initialize();
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Notification service failed: $e');
    }
    
    print('🎯 All services initialized, starting app...');
    
    runApp(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
          ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
        ],
        child: const MyApp(),
      ),
    );
    print('✅ App started successfully!');
    
  } catch (e, stackTrace) {
    print('💥 FATAL ERROR during initialization: $e');
    print('Stack trace: $stackTrace');
    
    // Run a minimal app instead
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 100),
                const SizedBox(height: 20),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text('Check the console for details.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Import the background handler from notification service
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MyApp widget...');
    
    try {
      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      print('✅ ThemeNotifier obtained');
      
      return MaterialApp(
        title: 'Finance Tracker',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF6C5CE7),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        ),
        home: const SimpleAuthWrapper(), // Simplified auth wrapper
      );
    } catch (e) {
      print('❌ Error building MyApp: $e');
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error in MyApp: $e'),
          ),
        ),
      );
    }
  }
}

class SimpleAuthWrapper extends StatelessWidget {
  const SimpleAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('🔐 Building SimpleAuthWrapper...');
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('🔐 Auth state: ${snapshot.connectionState}');
        
        if (snapshot.hasError) {
          print('❌ Auth error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(height: 10),
                  Text('Auth Error: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ Waiting for auth state...');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final user = snapshot.data;
        print('👤 User: ${user?.uid ?? 'null'}');
        
        if (user == null) {
          print('➡️ Showing login screen');
          return const LoginScreen();
        } else {
          print('➡️ Showing dashboard');
          return const DashboardScreen();
        }
      },
    );
  }
}
