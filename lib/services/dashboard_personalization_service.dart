import 'package:flutter/material.dart';
import '../models/onboarding_data.dart';
import '../models/currency.dart';
import 'database_service.dart';
import 'auth_service.dart';

/// Service for personalizing dashboard content based on onboarding data
class DashboardPersonalizationService {
  static final DashboardPersonalizationService _instance =
      DashboardPersonalizationService._internal();
  factory DashboardPersonalizationService() => _instance;
  DashboardPersonalizationService._internal();

  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  OnboardingData? _cachedOnboardingData;

  /// Get onboarding data for current user
  Future<OnboardingData?> getOnboardingData() async {
    if (_cachedOnboardingData != null) return _cachedOnboardingData;

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return null;

      final storedData = _databaseService.getSetting('onboarding_data_$userId');
      if (storedData != null && storedData is Map<String, dynamic>) {
        _cachedOnboardingData = OnboardingData.fromJson(storedData);
        return _cachedOnboardingData;
      }
    } catch (e) {
      print('Error loading onboarding data for personalization: $e');
    }
    return null;
  }

  /// Get personalized welcome message
  Future<String> getPersonalizedGreeting() async {
    final data = await getOnboardingData();
    if (data == null) return 'Welcome back!';

    final userType = data.userType;
    final spendingStyle = data.spendingStyle;

    String greeting = 'Welcome back';

    if (userType != null) {
      switch (userType) {
        case UserType.business:
          greeting += ', entrepreneur';
          break;
        case UserType.student:
          greeting += ', student';
          break;
        case UserType.freelancer:
          greeting += ', freelancer';
          break;
        case UserType.individual:
          greeting += ', friend';
          break;
      }
    }

    if (spendingStyle != null) {
      switch (spendingStyle) {
        case SpendingStyle.conservative:
          greeting += '! Keep up the great saving habits';
          break;
        case SpendingStyle.moderate:
          greeting += '! Your balanced approach is paying off';
          break;
        case SpendingStyle.aggressive:
          greeting += '! Time to review your spending goals';
          break;
      }
    } else {
      greeting += '!';
    }

    return greeting;
  }

  /// Get personalized tips based on user profile
  Future<List<String>> getPersonalizedTips() async {
    final data = await getOnboardingData();
    if (data == null) return [];

    final tips = <String>[];
    final userType = data.userType;
    final spendingStyle = data.spendingStyle;
    final financialGoals = data.financialGoals ?? [];
    final incomeAmount = data.incomeAmount;
    final incomeFrequency = data.incomeFrequency;

    // User type specific tips
    if (userType != null) {
      switch (userType) {
        case UserType.business:
          tips.add('Track business expenses separately for tax purposes');
          tips.add('Consider quarterly budget reviews for your business');
          break;
        case UserType.student:
          tips.add('Set aside money for textbooks and supplies');
          tips.add('Look for student discounts and deals');
          break;
        case UserType.freelancer:
          tips.add('Save 30% of each payment for taxes');
          tips.add('Track mileage and home office expenses');
          break;
        case UserType.individual:
          tips.add('Review your subscriptions monthly');
          tips.add('Build an emergency fund of 3-6 months expenses');
          break;
      }
    }

    // Spending style tips
    if (spendingStyle != null) {
      switch (spendingStyle) {
        case SpendingStyle.conservative:
          tips.add(
            'Great job staying within budget! Consider investing extra savings',
          );
          break;
        case SpendingStyle.moderate:
          tips.add(
            'Your balanced approach is working well. Keep tracking your progress',
          );
          break;
        case SpendingStyle.aggressive:
          tips.add('Consider setting up automatic transfers to savings');
          tips.add('Review your largest expenses for potential savings');
          break;
      }
    }

    // Income-based tips
    if (incomeAmount != null && incomeFrequency != null) {
      final monthlyIncome = _calculateMonthlyIncome(
        incomeAmount,
        incomeFrequency,
      );
      if (monthlyIncome < 50000) {
        // Assuming NGN, adjust threshold as needed
        tips.add('Focus on building an emergency fund first');
      } else if (monthlyIncome > 200000) {
        tips.add('Consider diversifying your investments');
      }
    }

    // Goal-specific tips
    for (final goal in financialGoals) {
      switch (goal) {
        case FinancialGoal.save_for_emergency:
          tips.add('Aim to save 3-6 months of expenses for emergencies');
          break;
        case FinancialGoal.buy_house:
          tips.add('Research mortgage options and down payment requirements');
          break;
        case FinancialGoal.pay_debt:
          tips.add('Focus on high-interest debt first (debt avalanche method)');
          break;
        case FinancialGoal.invest:
          tips.add(
            'Start with low-risk investments if you\'re new to investing',
          );
          break;
        case FinancialGoal.retirement:
          tips.add('Take advantage of retirement savings plans');
          break;
        default:
          break;
      }
    }

    // Limit to 3 tips max
    return tips.take(3).toList();
  }

  /// Get recommended budget percentages based on spending style
  Future<Map<String, double>> getRecommendedBudgetPercentages() async {
    final data = await getOnboardingData();
    final spendingStyle = data?.spendingStyle;

    // Default moderate percentages
    final defaultPercentages = {
      'Housing': 30.0,
      'Food': 15.0,
      'Transportation': 15.0,
      'Entertainment': 10.0,
      'Savings': 20.0,
      'Miscellaneous': 10.0,
    };

    if (spendingStyle == null) return defaultPercentages;

    switch (spendingStyle) {
      case SpendingStyle.conservative:
        return {
          'Housing': 25.0,
          'Food': 12.0,
          'Transportation': 12.0,
          'Entertainment': 8.0,
          'Savings': 35.0,
          'Miscellaneous': 8.0,
        };
      case SpendingStyle.moderate:
        return defaultPercentages;
      case SpendingStyle.aggressive:
        return {
          'Housing': 35.0,
          'Food': 18.0,
          'Transportation': 18.0,
          'Entertainment': 15.0,
          'Savings': 10.0,
          'Miscellaneous': 4.0,
        };
    }
  }

  /// Get prioritized quick actions based on user profile
  Future<List<QuickAction>> getPrioritizedQuickActions() async {
    final data = await getOnboardingData();
    if (data == null) return _getDefaultQuickActions();

    final actions = <QuickAction>[];
    final userType = data.userType;
    final spendingStyle = data.spendingStyle;
    final financialGoals = data.financialGoals ?? [];

    // Always include basic actions
    actions.add(
      QuickAction(
        title: 'Add Transaction',
        icon: Icons.add_circle_outline,
        color: Colors.green,
        priority: 1,
      ),
    );

    // User type specific actions
    if (userType == UserType.business) {
      actions.add(
        QuickAction(
          title: 'Business Expenses',
          icon: Icons.business,
          color: Colors.blue,
          priority: 2,
        ),
      );
    }

    if (userType == UserType.student) {
      actions.add(
        QuickAction(
          title: 'Education Savings',
          icon: Icons.school,
          color: Colors.teal,
          priority: 2,
        ),
      );
    }

    // Spending style actions
    if (spendingStyle == SpendingStyle.conservative) {
      actions.add(
        QuickAction(
          title: 'Investment',
          icon: Icons.trending_up,
          color: Colors.purple,
          priority: 2,
        ),
      );
    }

    if (spendingStyle == SpendingStyle.aggressive) {
      actions.add(
        QuickAction(
          title: 'Budget Review',
          icon: Icons.warning,
          color: Colors.orange,
          priority: 2,
        ),
      );
    }

    // Goal-specific actions
    if (financialGoals.contains(FinancialGoal.save_for_emergency)) {
      actions.add(
        QuickAction(
          title: 'Emergency Fund',
          icon: Icons.safety_check,
          color: Colors.red,
          priority: 3,
        ),
      );
    }

    if (financialGoals.contains(FinancialGoal.pay_debt)) {
      actions.add(
        QuickAction(
          title: 'Debt Payment',
          icon: Icons.payment,
          color: Colors.blue,
          priority: 3,
        ),
      );
    }

    // Fill with defaults if needed
    while (actions.length < 4) {
      final defaultActions = _getDefaultQuickActions();
      for (final action in defaultActions) {
        if (!actions.any((a) => a.title == action.title)) {
          actions.add(action);
          if (actions.length >= 4) break;
        }
      }
    }

    // Sort by priority and return top 4
    actions.sort((a, b) => a.priority.compareTo(b.priority));
    return actions.take(4).toList();
  }

  List<QuickAction> _getDefaultQuickActions() {
    return [
      QuickAction(
        title: 'Add Transaction',
        icon: Icons.add_circle_outline,
        color: Colors.green,
        priority: 1,
      ),
      QuickAction(
        title: 'Budgets',
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF6C5CE7),
        priority: 1,
      ),
      QuickAction(
        title: 'Savings',
        icon: Icons.savings,
        color: Colors.teal,
        priority: 1,
      ),
      QuickAction(
        title: 'Reports',
        icon: Icons.analytics,
        color: Colors.blue,
        priority: 1,
      ),
    ];
  }

  /// Get personalized insights based on user data
  Future<List<String>> getPersonalizedInsights() async {
    final data = await getOnboardingData();
    if (data == null) return [];

    final insights = <String>[];
    final userType = data.userType;
    final spendingStyle = data.spendingStyle;
    final incomeAmount = data.incomeAmount;
    final incomeFrequency = data.incomeFrequency;

    // Income-based insights
    if (incomeAmount != null && incomeFrequency != null) {
      final monthlyIncome = _calculateMonthlyIncome(
        incomeAmount,
        incomeFrequency,
      );

      if (userType == UserType.student && monthlyIncome < 30000) {
        insights.add(
          'Consider part-time work or freelance opportunities to supplement your income',
        );
      }

      if (userType == UserType.freelancer && monthlyIncome > 100000) {
        insights.add(
          'You\'re doing well! Consider setting aside more for retirement savings',
        );
      }
    }

    // Spending style insights
    if (spendingStyle == SpendingStyle.aggressive) {
      insights.add(
        'Your spending is higher than average. Consider the 50/30/20 rule for better balance',
      );
    }

    if (spendingStyle == SpendingStyle.conservative) {
      insights.add(
        'Excellent saving habits! You might have room for some discretionary spending',
      );
    }

    return insights.take(2).toList();
  }

  /// Calculate monthly income from amount and frequency
  double _calculateMonthlyIncome(double amount, IncomeFrequency frequency) {
    switch (frequency) {
      case IncomeFrequency.weekly:
        return amount * 4.33; // Average weeks per month
      case IncomeFrequency.biweekly:
        return amount * 2.166; // Average bi-weeks per month
      case IncomeFrequency.monthly:
        return amount;
      case IncomeFrequency.quarterly:
        return amount / 3;
      case IncomeFrequency.annually:
        return amount / 12;
    }
  }

  /// Clear cached data (useful when onboarding data changes)
  void clearCache() {
    _cachedOnboardingData = null;
  }
}

/// Quick action model for dashboard
class QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final int priority; // Lower number = higher priority

  const QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.priority,
  });
}
