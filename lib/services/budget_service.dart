import 'package:hive/hive.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/transaction.dart'; // Added for TransactionType
import '../models/subcategory.dart';
import 'database_service.dart';
import 'subcategory_service.dart';

class BudgetService {
  static const String _boxName = 'budgets';
  static Box<Budget>? _box;

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Budget>(_boxName);
    } else {
      _box = Hive.box<Budget>(_boxName);
    }
  }

  static Box<Budget> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('BudgetService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Create a new budget
  static Future<Budget> createBudget({
    required String name,
    required String categoryId,
    required double amount,
    required BudgetPeriod period,
    required String userId,
    DateTime? startDate,
    double alertThreshold = 0.8,
    bool alertEnabled = true,
    BudgetType type = BudgetType.progressive,
    String? description,
    String? currencyCode,
    String? subcategoryId,
    bool autoRenew = false,
  }) async {
    final budget = Budget.create(
      name: name,
      categoryId: categoryId,
      amount: amount,
      period: period,
      userId: userId,
      startDate: startDate,
      alertThreshold: alertThreshold,
      alertEnabled: alertEnabled,
      type: type,
      description: description,
      currencyCode: currencyCode,
      subcategoryId: subcategoryId,
      autoRenew: autoRenew,
    );

    await box.put(budget.id, budget);
    return budget;
  }

  /// Get all budgets for a user
  static Future<List<Budget>> getAllBudgets(String userId) async {
    return box.values
        .where((budget) => budget.userId == userId && budget.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get budgets for a specific category
  static Future<List<Budget>> getBudgetsForCategory(
    String categoryId,
    String userId,
  ) async {
    return box.values
        .where(
          (budget) =>
              budget.categoryId == categoryId &&
              budget.userId == userId &&
              budget.isActive,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get budgets for a specific subcategory
  static Future<List<Budget>> getBudgetsForSubcategory(
    String subcategoryId,
    String userId,
  ) async {
    return box.values
        .where(
          (budget) =>
              budget.subcategoryId == subcategoryId &&
              budget.userId == userId &&
              budget.isActive,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a budget by ID
  static Future<Budget?> getBudgetById(String id) async {
    return box.get(id);
  }

  /// Update an existing budget
  static Future<Budget> updateBudget(
    String id, {
    String? name,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    double? alertThreshold,
    bool? alertEnabled,
    BudgetType? type,
    String? description,
    String? currencyCode,
    String? subcategoryId,
    bool? autoRenew,
  }) async {
    final budget = box.get(id);
    if (budget == null) {
      throw Exception('Budget not found');
    }

    final updatedBudget = budget.copyWith(
      name: name,
      categoryId: categoryId,
      amount: amount,
      period: period,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      alertThreshold: alertThreshold,
      alertEnabled: alertEnabled,
      type: type,
      description: description,
      currencyCode: currencyCode,
      subcategoryId: subcategoryId,
      autoRenew: autoRenew,
    );

    await box.put(id, updatedBudget);
    return updatedBudget;
  }

  /// Delete a budget (soft delete)
  static Future<void> deleteBudget(String id) async {
    final budget = box.get(id);
    if (budget != null) {
      final updatedBudget = budget.copyWith(isActive: false);
      await box.put(id, updatedBudget);
    }
  }

  /// Permanently delete a budget
  static Future<void> permanentlyDeleteBudget(String id) async {
    await box.delete(id);
  }

  /// Get current period budgets
  static Future<List<Budget>> getCurrentPeriodBudgets(String userId) async {
    final allBudgets = await getAllBudgets(userId);
    return allBudgets.where((budget) => budget.isCurrentPeriod).toList();
  }

  /// Get budget spending progress
  static Future<Map<String, dynamic>> getBudgetProgress(
    String budgetId,
    String userId,
  ) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null || budget.userId != userId) {
      throw Exception('Budget not found or access denied');
    }

    // Get transactions for this budget's period
    final transactions = await _getBudgetTransactions(budget, userId);

    switch (budget.type) {
      case BudgetType.progressive:
        return _calculateProgressiveBudgetProgress(budget, transactions);
      case BudgetType.fixed:
        return _calculateFixedBudgetProgress(budget, transactions);
      case BudgetType.recurring:
        return _calculateProgressiveBudgetProgress(
          budget,
          transactions,
        ); // Recurring uses progressive logic for now
      case BudgetType.goal:
        return _calculateGoalBudgetProgress(budget, transactions);
    }
  }

  static Future<Map<String, dynamic>> _calculateProgressiveBudgetProgress(
    Budget budget,
    List<Transaction> transactions,
  ) async {
    final totalSpent = transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
    final remaining = budget.amount - totalSpent;
    final spentPercentage = budget.amount > 0
        ? (totalSpent / budget.amount)
        : 0.0;

    final expectedDailySpend = budget.amount / budget.totalDays;
    final elapsedDays = DateTime.now().difference(budget.startDate).inDays + 1;
    final expectedSpend = expectedDailySpend * elapsedDays;

    // Tolerance band (10-15%)
    final lowerTolerance = expectedSpend * 0.90; // 10% below expected
    final upperTolerance = expectedSpend * 1.15; // 15% above expected

    return {
      'budget': budget,
      'totalSpent': totalSpent,
      'remaining': remaining,
      'spentPercentage': spentPercentage,
      'isOverBudget': totalSpent > budget.amount,
      'transactionCount': transactions.length,
      'averageDailySpending': _calculateAverageDailySpending(
        transactions,
        budget,
      ),
      'daysRemaining': budget.daysRemaining,
      'projectedSpending': _calculateProjectedSpending(transactions, budget),
      'expectedDailySpend': expectedDailySpend,
      'expectedSpend': expectedSpend,
      'lowerTolerance': lowerTolerance,
      'upperTolerance': upperTolerance,
    };
  }

  static Future<Map<String, dynamic>> _calculateFixedBudgetProgress(
    Budget budget,
    List<Transaction> transactions,
  ) async {
    final totalSpent = transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
    final remaining = budget.amount - totalSpent;
    final spentPercentage = budget.amount > 0
        ? (totalSpent / budget.amount)
        : 0.0;

    final isUnderOrOnTrack = totalSpent <= budget.amount;

    return {
      'budget': budget,
      'totalSpent': totalSpent,
      'remaining': remaining,
      'spentPercentage': spentPercentage,
      'isOverBudget': !isUnderOrOnTrack,
      'transactionCount': transactions.length,
      'daysRemaining': budget.daysRemaining,
      'status': isUnderOrOnTrack ? 'On Track or Under Budget' : 'Over Budget',
    };
  }

  static Future<Map<String, dynamic>> _calculateGoalBudgetProgress(
    Budget budget,
    List<Transaction> transactions,
  ) async {
    // For goal-based budgets, transactions represent contributions towards the goal
    final totalSaved = transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
    final remainingToGoal = budget.amount - totalSaved;
    final progressPercentage = budget.amount > 0
        ? (totalSaved / budget.amount)
        : 0.0;

    String status;
    if (progressPercentage < 0.5) {
      status = 'Needs attention';
    } else if (progressPercentage >= 1.0) {
      status = 'Goal achieved 🎯';
    } else {
      status = 'On track';
    }

    return {
      'budget': budget,
      'totalSaved': totalSaved,
      'remainingToGoal': remainingToGoal,
      'progressPercentage': progressPercentage,
      'isGoalAchieved': totalSaved >= budget.amount,
      'transactionCount': transactions.length,
      'daysRemaining': budget.daysRemaining,
      'status': status,
    };
  }

  /// Get all budget progress for a user
  static Future<List<Map<String, dynamic>>> getAllBudgetProgress(
    String userId,
  ) async {
    final budgets = await getCurrentPeriodBudgets(userId);
    final progressList = <Map<String, dynamic>>[];

    for (final budget in budgets) {
      try {
        final progress = await getBudgetProgress(budget.id, userId);
        progressList.add(progress);
      } catch (e) {
        // Skip budgets with errors
        continue;
      }
    }

    return progressList;
  }

  /// Get transactions for a specific budget
  static Future<List<Transaction>> _getBudgetTransactions(
    Budget budget,
    String userId,
  ) async {
    final db = DatabaseService.instance;

    // Get all transactions in the budget period
    final allTransactions = await db.getTransactionsByDateRange(
      startDate: budget.startDate,
      endDate: budget.endDate,
      userId: userId,
    );

    // Filter by category and subcategory
    return allTransactions.where((transaction) {
      if (budget.type == BudgetType.goal) {
        // For goal budgets, consider income transactions that match the category
        return transaction.type == TransactionType.income &&
            transaction.categoryId == budget.categoryId &&
            (budget.subcategoryId == null ||
                transaction.subcategoryId == budget.subcategoryId);
      } else {
        // For other budget types, consider expense transactions that match the category
        return transaction.type == TransactionType.expense &&
            transaction.categoryId == budget.categoryId &&
            (budget.subcategoryId == null ||
                transaction.subcategoryId == budget.subcategoryId);
      }
    }).toList();
  }

  /// Calculate average daily spending for a budget
  static double _calculateAverageDailySpending(
    List<Transaction> transactions,
    Budget budget,
  ) {
    if (transactions.isEmpty) return 0.0;

    final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final elapsedDays = DateTime.now().difference(budget.startDate).inDays + 1;

    return elapsedDays > 0 ? totalSpent / elapsedDays : 0.0;
  }

  /// Calculate projected spending based on current patterns
  static double _calculateProjectedSpending(
    List<Transaction> transactions,
    Budget budget,
  ) {
    if (transactions.isEmpty || budget.totalDays <= 0) return 0.0;

    final averageDaily = _calculateAverageDailySpending(transactions, budget);
    return averageDaily * budget.totalDays;
  }

  /// Get budgets that are over threshold
  static Future<List<Map<String, dynamic>>> getOverThresholdBudgets(
    String userId,
  ) async {
    final progressList = await getAllBudgetProgress(userId);

    return progressList.where((progress) {
      final budget = progress['budget'] as Budget;
      final spentPercentage = progress['spentPercentage'] as double;
      return budget.alertEnabled && spentPercentage >= budget.alertThreshold;
    }).toList();
  }

  /// Get budgets that are over budget
  static Future<List<Map<String, dynamic>>> getOverBudgetBudgets(
    String userId,
  ) async {
    final progressList = await getAllBudgetProgress(userId);

    return progressList.where((progress) {
      return progress['isOverBudget'] as bool;
    }).toList();
  }

  /// Renew expired budgets for next period
  static Future<List<Budget>> renewExpiredBudgets(String userId) async {
    final allBudgets = await getAllBudgets(userId);
    final expiredBudgets = allBudgets
        .where((budget) => budget.isExpired && budget.autoRenew)
        .toList();
    final renewedBudgets = <Budget>[];

    for (final budget in expiredBudgets) {
      try {
        final renewedBudget = budget.renewForNextPeriod();
        await box.put(renewedBudget.id, renewedBudget);

        // Optionally deactivate the old budget
        final updatedOldBudget = budget.copyWith(isActive: false);
        await box.put(budget.id, updatedOldBudget);

        renewedBudgets.add(renewedBudget);
      } catch (e) {
        // Skip budgets that can't be renewed
        continue;
      }
    }

    return renewedBudgets;
  }

  /// Get budget statistics
  static Future<Map<String, dynamic>> getBudgetStatistics(String userId) async {
    final budgets = await getAllBudgets(userId);
    final currentBudgets = budgets.where((b) => b.isCurrentPeriod).toList();
    final progressList = await getAllBudgetProgress(userId);

    final totalBudgetAmount = currentBudgets.fold(
      0.0,
      (sum, b) => sum + b.amount,
    );
    final totalSpent = progressList.fold(
      0.0,
      (sum, p) => sum + (p['totalSpent'] as double),
    );

    return {
      'totalBudgets': budgets.length,
      'activeBudgets': currentBudgets.length,
      'totalBudgetAmount': totalBudgetAmount,
      'totalSpent': totalSpent,
      'remainingBudget': totalBudgetAmount - totalSpent,
      'overThresholdCount': progressList.where((p) {
        final budget = p['budget'] as Budget;
        final spentPercentage = p['spentPercentage'] as double;
        return budget.alertEnabled && spentPercentage >= budget.alertThreshold;
      }).length,
      'overBudgetCount': progressList
          .where((p) => p['isOverBudget'] as bool)
          .length,
      'averageBudgetAmount': currentBudgets.isEmpty
          ? 0.0
          : totalBudgetAmount / currentBudgets.length,
      'budgetUtilizationRate': totalBudgetAmount > 0
          ? totalSpent / totalBudgetAmount
          : 0.0,
    };
  }

  /// Get budgets grouped by category
  static Future<Map<String, List<Budget>>> getBudgetsGroupedByCategory(
    String userId,
  ) async {
    final budgets = await getAllBudgets(userId);
    final Map<String, List<Budget>> grouped = {};

    for (final budget in budgets) {
      if (!grouped.containsKey(budget.categoryId)) {
        grouped[budget.categoryId] = [];
      }
      grouped[budget.categoryId]!.add(budget);
    }

    return grouped;
  }

  /// Check if user can create multiple budgets per category/subcategory
  static Future<bool> canCreateBudgetForCategorySubcategory(
    String categoryId,
    String userId, {
    String? subcategoryId,
    BudgetPeriod? period,
  }) async {
    final existingBudgets = subcategoryId != null
        ? await getBudgetsForSubcategory(subcategoryId, userId)
        : await getBudgetsForCategory(categoryId, userId);

    if (period != null) {
      // Check for overlapping periods
      final currentPeriodBudgets = existingBudgets
          .where((budget) => budget.period == period && budget.isCurrentPeriod)
          .toList();
      return currentPeriodBudgets.isEmpty;
    }

    return true; // Allow multiple budgets by default
  }

  /// Clean up budgets for deleted categories/subcategories
  static Future<void> cleanupBudgets(String userId) async {
    final budgets = await getAllBudgets(userId);

    for (final budget in budgets) {
      bool shouldDelete = false;

      // Check if subcategory exists (if budget has subcategoryId)
      if (budget.subcategoryId != null) {
        final subcategory = await SubcategoryService.getSubcategoryById(
          budget.subcategoryId!,
        );
        if (subcategory == null || !subcategory.isActive) {
          shouldDelete = true;
        }
      }

      if (shouldDelete) {
        await deleteBudget(budget.id);
      }
    }
  }
}
