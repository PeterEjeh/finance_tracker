import 'dart:async';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import 'budget_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

/// Service to automatically handle budget lifecycle and end-of-period notifications
class BudgetAutoEndService {
  static final BudgetAutoEndService _instance =
      BudgetAutoEndService._internal();
  factory BudgetAutoEndService() => _instance;
  BudgetAutoEndService._internal();

  final NotificationService _notificationService = NotificationService();
  final SettingsService _settingsService = SettingsService();

  Timer? _checkTimer;
  bool _initialized = false;

  // Store scheduled notification IDs to avoid duplicates
  final Set<String> _scheduledBudgetIds = {};

  // Notification ID base (budget hash + offset)
  static const int _expiryNotificationOffset = 1000000;
  static const int _performanceSummaryOffset = 2000000;
  static const int _remindersOffset = 3000000;

  bool get isInitialized => _initialized;

  /// Initialize the service and start monitoring budgets
  Future<void> initialize() async {
    if (_initialized) return;

    await _notificationService.initialize();

    // Check immediately on startup
    await _checkAndHandleBudgets();

    // Schedule periodic checks (every 4 hours)
    _checkTimer = Timer.periodic(
      const Duration(hours: 4),
      (_) => _checkAndHandleBudgets(),
    );

    _initialized = true;
  }

  /// Main method to check and handle all budget states
  /// This should be called periodically or when user logs in
  Future<void> _checkAndHandleBudgets() async {
    try {
      // Note: This method is called from the timer, but it needs userId
      // In a real app, you would get userId from AuthService or store it
      // For now, budgets are checked when processBudgetsForUser is called explicitly
    } catch (e) {
      print('Error checking budgets: $e');
    }
  }

  /// Process budgets for a specific user
  Future<void> processBudgetsForUser(String userId) async {
    await _processExpiredBudgets(userId);
    await _scheduleEndOfPeriodNotifications(userId);
    await _scheduleReminderNotifications(userId);
  }

  /// Process expired budgets - deactivate and optionally auto-renew
  Future<void> _processExpiredBudgets(String userId) async {
    final allBudgets = await BudgetService.getAllBudgets(userId);

    for (final budget in allBudgets) {
      if (budget.isExpired && budget.isActive) {
        // Send performance summary notification
        await _sendPerformanceSummaryNotification(budget, userId);

        // Check if auto-renew is enabled
        if (budget.autoRenew) {
          await autoRenewBudget(budget.id, userId);
        } else {
          // Just deactivate
          await BudgetService.updateBudget(budget.id, isActive: false);
        }

        print('Budget "${budget.name}" has ended.');
      }
    }
  }

  /// Schedule notifications for budget end and reminders
  Future<void> _scheduleEndOfPeriodNotifications(String userId) async {
    final currentBudgets = await BudgetService.getCurrentPeriodBudgets(userId);

    for (final budget in currentBudgets) {
      // Skip if already scheduled
      if (_scheduledBudgetIds.contains(budget.id)) continue;

      // Schedule notification for when budget ends
      await _scheduleEndNotification(budget);

      _scheduledBudgetIds.add(budget.id);
    }
  }

  /// Schedule reminder notifications (3 days before, 1 day before, on day)
  Future<void> _scheduleReminderNotifications(String userId) async {
    final currentBudgets = await BudgetService.getCurrentPeriodBudgets(userId);

    for (final budget in currentBudgets) {
      final daysRemaining = budget.daysRemaining;

      // 3 days before end
      if (daysRemaining == 3) {
        await _scheduleReminderNotification(
          budget,
          daysRemaining: 3,
          message: 'Your ${budget.name} budget ends in 3 days',
        );
      }

      // 1 day before end
      if (daysRemaining == 1) {
        await _scheduleReminderNotification(
          budget,
          daysRemaining: 1,
          message: 'Your ${budget.name} budget ends tomorrow',
        );
      }

      // On end day
      if (daysRemaining == 0) {
        await _scheduleReminderNotification(
          budget,
          daysRemaining: 0,
          message: 'Your ${budget.name} budget ends today',
        );
      }
    }
  }

  /// Schedule notification for when budget period ends
  Future<void> _scheduleEndNotification(Budget budget) async {
    final notificationId = _getNotificationId(
      budget.id,
      _expiryNotificationOffset,
    );

    // Schedule for end of day on endDate
    final endDateTime = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
      21, // 9 PM
      0,
    );

    // Only schedule if in the future
    if (endDateTime.isAfter(DateTime.now())) {
      await _notificationService.showLocalNotification(
        notificationId,
        '${budget.name} Budget Ended',
        'Your ${budget.period.displayName.toLowerCase()} budget has ended. Tap to view performance summary.',
        endDateTime,
      );
    }
  }

  /// Schedule reminder notification
  Future<void> _scheduleReminderNotification(
    Budget budget, {
    required int daysRemaining,
    required String message,
  }) async {
    final notificationId = _getNotificationId(
      budget.id + '_$daysRemaining',
      _remindersOffset,
    );

    // Schedule for 10 AM on the reminder day
    final reminderDate = budget.endDate.subtract(Duration(days: daysRemaining));
    final reminderDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      10, // 10 AM
      0,
    );

    // Only schedule if in the future
    if (reminderDateTime.isAfter(DateTime.now())) {
      await _notificationService.showLocalNotification(
        notificationId,
        'Budget Reminder',
        message,
        reminderDateTime,
      );
    }
  }

  /// Send performance summary notification when budget ends
  Future<void> _sendPerformanceSummaryNotification(
    Budget budget,
    String userId,
  ) async {
    try {
      final progress = await BudgetService.getBudgetProgress(budget.id, userId);
      final summary = _generatePerformanceSummary(budget, progress);

      final notificationId = _getNotificationId(
        budget.id,
        _performanceSummaryOffset,
      );

      await _notificationService.showLocalNotification(
        notificationId,
        '${budget.name} Performance Summary',
        summary,
        DateTime.now().add(const Duration(seconds: 5)),
      );
    } catch (e) {
      print('Error sending performance summary: $e');
    }
  }

  /// Generate a performance summary message
  String _generatePerformanceSummary(
    Budget budget,
    Map<String, dynamic> progress,
  ) {
    final totalSpent = progress['totalSpent'] as double;
    final remaining = progress['remaining'] as double;
    final spentPercentage = progress['spentPercentage'] as double;
    final isOverBudget = progress['isOverBudget'] as bool;

    final currencyFormat = NumberFormat.currency(
      symbol: budget.currency.symbol,
      decimalDigits: 0,
    );

    if (isOverBudget) {
      final overAmount = (totalSpent - budget.amount).abs();
      return '❌ Over budget by ${currencyFormat.format(overAmount)}! '
          'Spent ${currencyFormat.format(totalSpent)} of ${budget.formattedAmount}';
    } else if (spentPercentage < 0.7) {
      // Great performance - under 70%
      final saved = remaining;
      final savingsPercentage = (saved / budget.amount * 100).round();
      return '🎉 Great job! Saved ${currencyFormat.format(saved)} '
          '($savingsPercentage% under budget)';
    } else if (spentPercentage < 0.95) {
      // Good performance - under 95%
      return '✅ Well done! Spent ${currencyFormat.format(totalSpent)} '
          'of ${budget.formattedAmount} (${(spentPercentage * 100).round()}%)';
    } else {
      // Just under budget
      return '✓ Budget met! Spent ${currencyFormat.format(totalSpent)} '
          'of ${budget.formattedAmount}';
    }
  }

  /// Calculate a beta score for budget performance (0-5 stars)
  double calculateBudgetRating(Map<String, dynamic> progress) {
    final spentPercentage = progress['spentPercentage'] as double;
    final isOverBudget = progress['isOverBudget'] as bool;

    if (isOverBudget) {
      // Over budget - score based on how much over
      final overPercentage = spentPercentage - 1.0;
      if (overPercentage > 0.5) return 0.5; // 50%+ over
      if (overPercentage > 0.3) return 1.0; // 30-50% over
      if (overPercentage > 0.1) return 1.5; // 10-30% over
      return 2.0; // Less than 10% over
    }

    // Under budget - better score for more savings
    if (spentPercentage < 0.5) return 5.0; // Under 50% - perfect
    if (spentPercentage < 0.7) return 4.5; // Under 70% - excellent
    if (spentPercentage < 0.85) return 4.0; // Under 85% - great
    if (spentPercentage < 0.95) return 3.5; // Under 95% - good
    return 3.0; // 95-100% - acceptable
  }

  /// Get the budget rating as a star string
  String getBudgetRatingStars(double rating) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    String stars = '⭐' * fullStars;
    if (hasHalfStar) stars += '✨';

    return stars;
  }

  /// Get notification ID from budget ID (to avoid collisions)
  int _getNotificationId(String budgetId, int offset) {
    return (budgetId.hashCode.abs() % 1000000) + offset;
  }

  /// Cancel all scheduled notifications for a budget
  Future<void> cancelBudgetNotifications(String budgetId) async {
    final ids = [
      _getNotificationId(budgetId, _expiryNotificationOffset),
      _getNotificationId(budgetId, _performanceSummaryOffset),
      _getNotificationId('${budgetId}_3', _remindersOffset),
      _getNotificationId('${budgetId}_1', _remindersOffset),
      _getNotificationId('${budgetId}_0', _remindersOffset),
    ];

    for (final id in ids) {
      await _notificationService.cancelNotification(id);
    }

    _scheduledBudgetIds.remove(budgetId);
  }

  /// Manually trigger end of budget
  Future<void> manuallyEndBudget(String budgetId, String userId) async {
    final budget = await BudgetService.getBudgetById(budgetId);
    if (budget == null) return;

    // Send performance summary
    await _sendPerformanceSummaryNotification(budget, userId);

    // Deactivate budget
    await BudgetService.updateBudget(budgetId, isActive: false);

    // Cancel scheduled notifications
    await cancelBudgetNotifications(budgetId);
  }

  /// Auto-renew a budget for the next period
  Future<Budget?> autoRenewBudget(String budgetId, String userId) async {
    final budget = await BudgetService.getBudgetById(budgetId);
    if (budget == null || budget.userId != userId) return null;

    // Create renewed budget
    final renewedBudget = budget.renewForNextPeriod();
    await BudgetService.box.put(renewedBudget.id, renewedBudget);

    // Deactivate old budget
    await BudgetService.updateBudget(budgetId, isActive: false);

    // Cancel old notifications
    await cancelBudgetNotifications(budgetId);

    // Schedule new notifications
    await _scheduleEndNotification(renewedBudget);

    // Send notification about renewal
    await _notificationService.showLocalNotification(
      _getNotificationId(renewedBudget.id, _remindersOffset),
      'Budget Renewed',
      '${renewedBudget.name} has been renewed for the next ${renewedBudget.period.displayName.toLowerCase()}',
      DateTime.now().add(const Duration(seconds: 2)),
    );

    return renewedBudget;
  }

  /// Get historical performance for a budget (for graph)
  Future<List<Map<String, dynamic>>> getBudgetHistory(
    String categoryId,
    String userId, {
    int monthsBack = 6,
  }) async {
    final allBudgets = await BudgetService.getBudgetsForCategory(
      categoryId,
      userId,
    );

    // Filter to get historical budgets (ended ones)
    final historicalBudgets =
        allBudgets.where((b) => b.isExpired || !b.isActive).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

    // Take last N budgets
    final recentBudgets = historicalBudgets.length > monthsBack
        ? historicalBudgets.sublist(historicalBudgets.length - monthsBack)
        : historicalBudgets;

    final history = <Map<String, dynamic>>[];

    for (final budget in recentBudgets) {
      try {
        final progress = await BudgetService.getBudgetProgress(
          budget.id,
          userId,
        );
        history.add({
          'budget': budget,
          'totalSpent': progress['totalSpent'],
          'budgetAmount': budget.amount,
          'spentPercentage': progress['spentPercentage'],
          'isOverBudget': progress['isOverBudget'],
          'period': DateFormat('MMM yy').format(budget.startDate),
          'rating': calculateBudgetRating(progress),
        });
      } catch (e) {
        // Skip budgets with errors
        continue;
      }
    }

    return history;
  }

  /// Dispose the service
  void dispose() {
    _checkTimer?.cancel();
    _scheduledBudgetIds.clear();
    _initialized = false;
  }
}
