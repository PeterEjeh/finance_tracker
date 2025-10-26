import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/onboarding_data.dart';
import '../services/database_service.dart';
import '../services/onboarding_firestore_service.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingData _data = OnboardingData.create();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isOnlineSync = false;
  String? _errorMessage;
  bool _hasNetworkError = false;

  final OnboardingFirestoreService _firestoreService =
      OnboardingFirestoreService();

  OnboardingData get data => _data;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get isOnlineSync => _isOnlineSync;
  bool get isComplete => _data.isComplete;
  String? get errorMessage => _errorMessage;
  bool get hasNetworkError => _hasNetworkError;

  // Step navigation
  void nextStep() {
    if (_currentStep < 7) {
      // 8 screens total (0-7)
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 7) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // Data updates with validation
  void updateUserType(UserType userType) {
    try {
      _clearErrors();
      _data.userType = userType;
      _data.updateProgress();
      notifyListeners();
      _saveData();
    } catch (e) {
      _setError('Failed to update user type: $e');
    }
  }

  void updateIncomeAmount(double amount) {
    try {
      _clearErrors();
      if (amount < 0) {
        throw Exception('Income amount cannot be negative');
      }
      if (amount > 10000000) {
        // 10 million limit
        throw Exception('Income amount seems unreasonably high');
      }
      _data.incomeAmount = amount;
      _data.updateProgress();
      notifyListeners();
      _saveData();
    } catch (e) {
      _setError('Invalid income amount: $e');
    }
  }

  void updateIncomeFrequency(IncomeFrequency frequency) {
    try {
      _clearErrors();
      _data.incomeFrequency = frequency;
      _data.updateProgress();
      notifyListeners();
      _saveData();
    } catch (e) {
      _setError('Failed to update income frequency: $e');
    }
  }

  void updateSpendingStyle(SpendingStyle style) {
    try {
      _clearErrors();
      _data.spendingStyle = style;
      _data.updateProgress();
      notifyListeners();
      _saveData();
    } catch (e) {
      _setError('Failed to update spending style: $e');
    }
  }

  void updateFinancialGoals(List<FinancialGoal> goals) {
    try {
      _clearErrors();
      if (goals.length > 5) {
        throw Exception('Please select no more than 5 financial goals');
      }
      _data.financialGoals = goals;
      _data.updateProgress();
      notifyListeners();
      _saveData();
    } catch (e) {
      _setError('Failed to update financial goals: $e');
    }
  }

  void updateCurrencyCode(String currencyCode) {
    try {
      _clearErrors();
      if (currencyCode.isEmpty) {
        throw Exception('Currency code cannot be empty');
      }
      if (currencyCode.length != 3) {
        throw Exception('Currency code must be 3 characters');
      }
      _data.currencyCode = currencyCode.toUpperCase();
      _data.updateProgress();
      notifyListeners();
      _saveData();
    } catch (e) {
      _setError('Invalid currency code: $e');
    }
  }

  void updatePreferences(Map<String, dynamic> preferences) {
    try {
      _clearErrors();
      _data.preferences = preferences;
      _data.updateProgress();
      notifyListeners();
      _saveData();
    } catch (e) {
      _setError('Failed to update preferences: $e');
    }
  }

  // Load data from storage with cloud sync
  Future<void> loadData() async {
    _isLoading = true;
    _clearErrors();
    notifyListeners();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _setError('No user logged in');
        return;
      }

      // First try to load from local storage
      final db = DatabaseService.instance;
      OnboardingData? localData;
      final storedData = db.getSetting('onboarding_data_$userId');
      if (storedData != null && storedData is Map<String, dynamic>) {
        try {
          localData = OnboardingData.fromJson(storedData);
        } catch (parseError) {
          print('Failed to parse local onboarding data: $parseError');
          // Continue with null localData - will try cloud
        }
      }

      // Try to sync with cloud
      _isOnlineSync = true;
      notifyListeners();

      try {
        final useCloudData = await _firestoreService.syncOnboardingData(
          localData ?? OnboardingData.create(),
        );

        if (useCloudData) {
          // Cloud data is newer, download and use it
          final cloudData = await _firestoreService.downloadOnboardingData();
          if (cloudData != null) {
            _data = cloudData;
            // Save cloud data to local storage
            await _saveData();
          }
        } else {
          // Local data is current, it was already uploaded in syncOnboardingData
          if (localData != null) {
            _data = localData;
          }
        }
      } catch (syncError) {
        print('Cloud sync failed, using local data: $syncError');
        _hasNetworkError = true;
        // Fall back to local data
        if (localData != null) {
          _data = localData;
        }
      }
    } catch (e) {
      print('Error loading onboarding data: $e');
      _setError('Failed to load onboarding data: $e');
    } finally {
      _isLoading = false;
      _isOnlineSync = false;
      notifyListeners();
    }
  }

  // Save data to storage and sync to cloud
  Future<void> _saveData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('No user logged in, cannot save onboarding data');
        return;
      }

      final db = DatabaseService.instance;
      await db.setSetting('onboarding_data_$userId', _data.toJson());

      // Sync to cloud in background (don't block UI)
      try {
        await _firestoreService.uploadOnboardingData(_data);
      } catch (cloudError) {
        print('Cloud sync failed, data saved locally: $cloudError');
        // Don't throw error - local save succeeded
      }
    } catch (e) {
      print('Error saving onboarding data: $e');
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    _data.isCompleted = true;
    _data.updateProgress();
    await _saveData();

    // Mark as completed in cloud
    try {
      await _firestoreService.markOnboardingCompleted();
    } catch (e) {
      print('Failed to mark onboarding completed in cloud: $e');
      // Don't fail the completion if cloud sync fails
    }

    notifyListeners();
  }

  // Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('No user logged in, cannot reset onboarding data');
      return;
    }

    _data = OnboardingData.create();
    _currentStep = 0;
    _clearErrors();
    final db = DatabaseService.instance;
    await db.deleteSetting('onboarding_data_$userId');

    // Also try to delete from cloud
    try {
      await _firestoreService.deleteOnboardingData();
    } catch (e) {
      print('Failed to delete cloud onboarding data: $e');
    }

    notifyListeners();
  }

  // Retry failed operations
  Future<void> retryLastOperation() async {
    if (_hasNetworkError) {
      _hasNetworkError = false;
      _clearErrors();
      notifyListeners();

      // Retry the last save operation
      await _saveData();
    }
  }

  // Clear error states
  void clearErrors() {
    _clearErrors();
    notifyListeners();
  }

  // Private error handling methods
  void _clearErrors() {
    _errorMessage = null;
    _hasNetworkError = false;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Get progress percentage
  double get progressPercentage {
    return (_currentStep + 1) / 8.0; // 8 total screens
  }

  // Get current screen title
  String get currentScreenTitle {
    switch (_currentStep) {
      case 0:
        return 'Welcome';
      case 1:
        return 'User Type';
      case 2:
        return 'Currency & Preferences';
      case 3:
        return 'Income Details';
      case 4:
        return 'Income Frequency';
      case 5:
        return 'Spending Style';
      case 6:
        return 'Financial Goals';
      case 7:
        return 'Summary';
      default:
        return 'Onboarding';
    }
  }
}
