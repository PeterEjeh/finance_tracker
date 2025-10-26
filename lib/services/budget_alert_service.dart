import '../models/budget.dart';
import '../services/database_service.dart';
import '../services/budget_service.dart';
import 'package:intl/intl.dart';

class BudgetAlertService {
  static final BudgetAlertService _instance = BudgetAlertService._internal();
  factory BudgetAlertService() => _instance;
  BudgetAlertService._internal();

  final DatabaseService _databaseService = DatabaseService.instance;

  /// Check all budgets for alerts and return those that need attention
  Future<List<BudgetAlert>> checkBudgetAlerts({String? userId}) async {
    final budgetsNeedingAlert = _databaseService.getBudgetsNeedingAlert(
      userId: userId,
    );
    final alerts = <BudgetAlert>[];

    for (final budget in budgetsNeedingAlert) {
      // Use smart budget progress calculation
      final budgetProgress = await BudgetService.getBudgetProgress(
        budget.id,
        userId ?? '',
      );
      final totalSpent = budgetProgress['totalSpent'] as double;
      final spentPercentage = budgetProgress['spentPercentage'] as double;
      final isOverBudget = budgetProgress['isOverBudget'] as bool;

      if (isOverBudget) {
        alerts.add(
          BudgetAlert(
            budget: budget,
            type: BudgetAlertType.overBudget,
            message:
                'You have exceeded your budget for "${budget.name}". '
                'Spent: ${NumberFormat.currency(symbol: '₦').format(totalSpent)} of ${NumberFormat.currency(symbol: '₦').format(budget.amount)}',
            severity: AlertSeverity.high,
          ),
        );
      } else if (spentPercentage >= budget.alertThreshold) {
        final percentage = (spentPercentage * 100).toStringAsFixed(0);
        alerts.add(
          BudgetAlert(
            budget: budget,
            type: BudgetAlertType.thresholdReached,
            message:
                'You have used $percentage% of your budget for "${budget.name}". '
                'Spent: ${NumberFormat.currency(symbol: '₦').format(totalSpent)} of ${NumberFormat.currency(symbol: '₦').format(budget.amount)}',
            severity: AlertSeverity.medium,
          ),
        );
      }
    }

    return alerts;
  }

  /// Check for budgets that are about to expire
  List<BudgetAlert> checkExpiringBudgets({String? userId}) {
    final activeBudgets = _databaseService.getActiveBudgets(userId: userId);
    final alerts = <BudgetAlert>[];

    for (final budget in activeBudgets) {
      if (budget.daysRemaining <= 3 && budget.daysRemaining > 0) {
        alerts.add(
          BudgetAlert(
            budget: budget,
            type: BudgetAlertType.expiringSoon,
            message:
                'Your budget "${budget.name}" expires in ${budget.daysRemaining} day${budget.daysRemaining == 1 ? '' : 's'}.',
            severity: AlertSeverity.low,
          ),
        );
      }
    }

    return alerts;
  }

  /// Get all alerts for a user
  Future<List<BudgetAlert>> getAllAlerts({String? userId}) async {
    final budgetAlerts = await checkBudgetAlerts(userId: userId);
    final expiringAlerts = checkExpiringBudgets(userId: userId);

    final allAlerts = [...budgetAlerts, ...expiringAlerts];

    // Sort by severity (high -> medium -> low)
    allAlerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return allAlerts;
  }

  /// Get summary of budget performance
  Future<BudgetSummary> getBudgetSummary({String? userId}) async {
    final activeBudgets = _databaseService.getActiveBudgets(userId: userId);
    final budgetSummaryData = _databaseService.getBudgetSummary(userId: userId);

    int onTrackCount = 0;
    int alertCount = 0;
    int overBudgetCount = 0;

    for (final budget in activeBudgets) {
      // Use smart budget progress calculation
      final budgetProgress = await BudgetService.getBudgetProgress(
        budget.id,
        userId ?? '',
      );
      final isOverBudget = budgetProgress['isOverBudget'] as bool;
      final spentPercentage = budgetProgress['spentPercentage'] as double;

      if (isOverBudget) {
        overBudgetCount++;
      } else if (spentPercentage >= budget.alertThreshold) {
        alertCount++;
      } else {
        onTrackCount++;
      }
    }

    return BudgetSummary(
      totalBudgets: activeBudgets.length,
      onTrackCount: onTrackCount,
      alertCount: alertCount,
      overBudgetCount: overBudgetCount,
      totalBudgeted: budgetSummaryData['totalBudgeted'] ?? 0.0,
      totalSpent: budgetSummaryData['totalSpent'] ?? 0.0,
      totalRemaining: budgetSummaryData['totalRemaining'] ?? 0.0,
    );
  }
}

class BudgetAlert {
  final Budget budget;
  final BudgetAlertType type;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;

  BudgetAlert({
    required this.budget,
    required this.type,
    required this.message,
    required this.severity,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

enum BudgetAlertType { overBudget, thresholdReached, expiringSoon }

enum AlertSeverity { low, medium, high }

class BudgetSummary {
  final int totalBudgets;
  final int onTrackCount;
  final int alertCount;
  final int overBudgetCount;
  final double totalBudgeted;
  final double totalSpent;
  final double totalRemaining;

  BudgetSummary({
    required this.totalBudgets,
    required this.onTrackCount,
    required this.alertCount,
    required this.overBudgetCount,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.totalRemaining,
  });

  double get overallProgress =>
      totalBudgeted > 0 ? totalSpent / totalBudgeted : 0.0;

  bool get hasAlerts => alertCount > 0 || overBudgetCount > 0;

  String get statusMessage {
    if (overBudgetCount > 0) {
      return '$overBudgetCount budget${overBudgetCount == 1 ? '' : 's'} over limit';
    } else if (alertCount > 0) {
      return '$alertCount budget${alertCount == 1 ? '' : 's'} need attention';
    } else if (onTrackCount > 0) {
      return 'All budgets on track';
    } else {
      return 'No active budgets';
    }
  }
}
