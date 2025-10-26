import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/onboarding_flow_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../models/onboarding_data.dart';
import '../widgets/authentication_gate.dart';

class AuthWrapper extends StatelessWidget {
  AuthWrapper({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> _hasUserCompletedOnboarding(String userId) async {
    try {
      final db = DatabaseService.instance;
      final storedData = db.getSetting('onboarding_data_$userId');
      if (storedData != null && storedData is Map<String, dynamic>) {
        final onboardingData = OnboardingData.fromJson(storedData);
        return onboardingData.isCompleted;
      }
      return false;
    } catch (e) {
      print('Error checking onboarding completion: $e');
      return false;
    }
  }

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
                    return const LoginScreen();
                  } else {
                    return const OnboardingScreen();
                  }
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          }
          // User is logged in - check if comprehensive onboarding is completed
          return FutureBuilder<bool>(
            future: _hasUserCompletedOnboarding(user.uid),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState == ConnectionState.done) {
                if (onboardingSnapshot.data == true) {
                  // Comprehensive onboarding completed - show authentication gate
                  return const AuthenticationGate(child: DashboardScreen());
                } else {
                  // Comprehensive onboarding not completed - show onboarding flow
                  return const OnboardingFlowScreen();
                }
              }
              return const Center(child: CircularProgressIndicator());
            },
          );
        }
        // Waiting for auth state to be determined
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
