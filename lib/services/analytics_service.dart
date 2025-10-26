import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/report.dart';
import '../models/currency.dart';
import 'database_service.dart';
import 'currency_service.dart';
import 'budget_alert_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final DatabaseService _databaseService = DatabaseService.instance;
  final CurrencyService _currencyService = CurrencyService();

  /// Generate a comprehensive spending report for a given period
  SpendingReport generateSpendingReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
    String? notes,
    String? baseCurrency,
  }) {
    final transactions = _databaseService.getTransactionsByDateRange(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    final categories = _databaseService.getAllCategories(userId: userId);
    final targetCurrency = baseCurrency ?? SupportedCurrencies.baseCurrency;

    // Convert all transactions to base currency for consistent reporting
    final convertedTransactions = _convertTransactionsToBaseCurrency(
      transactions,
      targetCurrency,
    );

    return SpendingReport.create(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: period,
      transactions: convertedTransactions,
      categories: categories,
      notes: notes,
    );
  }

  /// Generate an expense-only report for a given period (excludes income)
  SpendingReport generateExpenseReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
    String? notes,
    String? baseCurrency,
  }) {
    final allTransactions = _databaseService.getTransactionsByDateRange(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    // Filter to only expense transactions
    final expenseTransactions = allTransactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList();

    final categories = _databaseService.getAllCategories(userId: userId);
    final targetCurrency = baseCurrency ?? SupportedCurrencies.baseCurrency;

    // Convert expense transactions to base currency for consistent reporting
    final convertedTransactions = _convertTransactionsToBaseCurrency(
      expenseTransactions,
      targetCurrency,
    );

    return SpendingReport.create(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: period,
      transactions: convertedTransactions,
      categories: categories,
      notes: notes,
    );
  }

  /// Convert transactions to base currency for consistent reporting
  List<Transaction> _convertTransactionsToBaseCurrency(
    List<Transaction> transactions,
    String baseCurrency,
  ) {
    return transactions.map((transaction) {
      // If transaction is already in base currency, return as is
      if (transaction.currencyCode == baseCurrency) {
        return transaction;
      }

      // If we have original amount in base currency, use it
      if (transaction.originalCurrencyCode == baseCurrency &&
          transaction.originalAmount != null) {
        return transaction.copyWith(
          amount: transaction.originalAmount!,
          currencyCode: baseCurrency,
        );
      }

      // Otherwise, try to convert using stored exchange rate
      if (transaction.exchangeRate != null) {
        final convertedAmount = transaction.amount / transaction.exchangeRate!;
        return transaction.copyWith(
          amount: convertedAmount,
          currencyCode: baseCurrency,
        );
      }

      // If no conversion data available, return original transaction
      // This maintains data integrity but may affect accuracy
      return transaction;
    }).toList();
  }

  /// Get spending trends over multiple periods
  List<SpendingTrend> getSpendingTrends({
    required String userId,
    required ReportPeriod period,
    required int periodCount,
    String? baseCurrency,
  }) {
    final trends = <SpendingTrend>[];
    final now = DateTime.now();
    final targetCurrency = baseCurrency ?? SupportedCurrencies.baseCurrency;

    for (int i = 0; i < periodCount; i++) {
      final periodDates = _getPeriodDates(period, now, i);
      final transactions = _databaseService.getTransactionsByDateRange(
        startDate: periodDates.start,
        endDate: periodDates.end,
        userId: userId,
      );

      // Convert transactions to base currency
      final convertedTransactions = _convertTransactionsToBaseCurrency(
        transactions,
        targetCurrency,
      );

      double totalIncome = 0;
      double totalExpenses = 0;

      for (final transaction in convertedTransactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else {
          totalExpenses += transaction.amount;
        }
      }

      trends.add(
        SpendingTrend(
          period: periodDates.start,
          totalIncome: totalIncome,
          totalExpenses: totalExpenses,
          netAmount: totalIncome - totalExpenses,
          transactionCount: convertedTransactions.length,
        ),
      );
    }

    return trends.reversed.toList(); // Return in chronological order
  }

  /// Get expense-only trends over multiple periods (excludes income)
  List<SpendingTrend> getExpenseTrends({
    required String userId,
    required ReportPeriod period,
    required int periodCount,
    String? baseCurrency,
  }) {
    final trends = <SpendingTrend>[];
    final now = DateTime.now();
    final targetCurrency = baseCurrency ?? SupportedCurrencies.baseCurrency;

    for (int i = 0; i < periodCount; i++) {
      final periodDates = _getPeriodDates(period, now, i);
      final allTransactions = _databaseService.getTransactionsByDateRange(
        startDate: periodDates.start,
        endDate: periodDates.end,
        userId: userId,
      );

      // Filter to only expense transactions
      final expenseTransactions = allTransactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .toList();

      // Convert expense transactions to base currency
      final convertedTransactions = _convertTransactionsToBaseCurrency(
        expenseTransactions,
        targetCurrency,
      );

      double totalExpenses = 0;

      for (final transaction in convertedTransactions) {
        totalExpenses += transaction.amount;
      }

      trends.add(
        SpendingTrend(
          period: periodDates.start,
          totalIncome: 0, // No income in expense-only trends
          totalExpenses: totalExpenses,
          netAmount: -totalExpenses, // Negative since it's all expenses
          transactionCount: convertedTransactions.length,
        ),
      );
    }

    return trends.reversed.toList(); // Return in chronological order
  }

  /// Check for budgets that need attention based on predictions
  List<BudgetAlertInfo> checkBudgetAlerts({
    required String userId,
    double tolerancePercentage = 0.1,
  }) {
    final reports = getBudgetPerformanceReports(
      userId: userId,
      tolerancePercentage: tolerancePercentage,
    );

    final alerts = <BudgetAlertInfo>[];

    for (final report in reports) {
      if (report.predictionInfo != null) {
        final prediction = report.predictionInfo!;

        // Alert if budget will be exceeded
        if (prediction.willExceedBudget) {
          alerts.add(
            BudgetAlertInfo(
              budgetId: report.budgetId,
              budgetName: report.budgetName,
              alertType: 'overBudget',
              message:
                  'Based on your current spending pattern, you will exceed your ${report.categoryName} budget by ₦${prediction.projectedOverage.toStringAsFixed(0)}',
              severity: 'high',
              daysUntilIssue: prediction.daysUntilOverBudget,
              recommendedAction:
                  'Consider reducing daily spending to ₦${prediction.recommendedDailySpending?.toStringAsFixed(0)} or less',
              confidence: prediction.confidence,
            ),
          );
        }
        // Alert if spending too slowly (might indicate forgotten budget)
        else if (report.status == BudgetPerformanceStatus.underBudget &&
            prediction.confidence > 0.7) {
          final spendingRate = report.actualSpent / report.budgetAmount;
          if (spendingRate < 0.3) {
            // Less than 30% spent
            alerts.add(
              BudgetAlertInfo(
                budgetId: report.budgetId,
                budgetName: report.budgetName,
                alertType: 'thresholdReached',
                message:
                    'You\'ve only used ₦${report.actualSpent.toStringAsFixed(0)} of your ₦${report.budgetAmount.toStringAsFixed(0)} ${report.categoryName} budget',
                severity: 'medium',
                recommendedAction:
                    'Consider if this budget amount is appropriate for your needs',
                confidence: prediction.confidence,
              ),
            );
          }
        }
      }
    }

    return alerts;
  }

  /// Get top spending categories for a period
  List<CategorySpending> getTopSpendingCategories({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
    String? baseCurrency,
  }) {
    final report = generateSpendingReport(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: ReportPeriod.custom,
      baseCurrency: baseCurrency,
    );

    final topCategories =
        report.categoryBreakdown.where((cs) => cs.totalAmount > 0).toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return topCategories.take(limit).toList();
  }

  /// Get top expense categories for a period (expenses only)
  List<CategorySpending> getTopExpenseCategories({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
    String? baseCurrency,
  }) {
    final report = generateExpenseReport(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: ReportPeriod.custom,
      baseCurrency: baseCurrency,
    );

    final topCategories =
        report.categoryBreakdown.where((cs) => cs.totalAmount > 0).toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return topCategories.take(limit).toList();
  }

  /// Calculate spending velocity (average daily spending)
  SpendingVelocity calculateSpendingVelocity({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? baseCurrency,
  }) {
    final transactions = _databaseService.getTransactionsByDateRange(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    final targetCurrency = baseCurrency ?? SupportedCurrencies.baseCurrency;
    final convertedTransactions = _convertTransactionsToBaseCurrency(
      transactions,
      targetCurrency,
    );

    // Separate consumption expenses from savings/investments
    final consumptionExpenses = convertedTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.categoryId != 'expense_savings',
        )
        .toList();

    final savingsInvestments = convertedTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.categoryId == 'expense_savings',
        )
        .toList();

    final totalConsumptionExpenses = consumptionExpenses.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );

    final totalSavingsInvestments = savingsInvestments.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );

    final daysDifference = endDate.difference(startDate).inDays + 1;
    final dailyAverage = daysDifference > 0
        ? totalConsumptionExpenses / daysDifference
        : 0;

    // Calculate weekly and monthly averages for consumption only
    final weeklyAverage = dailyAverage * 7;
    final monthlyAverage = dailyAverage * 30;

    // Find highest and lowest consumption spending days (excluding savings)
    final dailyTotals = <DateTime, double>{};
    for (final transaction in consumptionExpenses) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyTotals[date] = (dailyTotals[date] ?? 0) + transaction.amount;
    }

    double highestDayAmount = 0;
    DateTime? highestDay;
    double lowestDayAmount = double.infinity;
    DateTime? lowestDay;

    for (final entry in dailyTotals.entries) {
      if (entry.value > highestDayAmount) {
        highestDayAmount = entry.value;
        highestDay = entry.key;
      }
      if (entry.value < lowestDayAmount) {
        lowestDayAmount = entry.value;
        lowestDay = entry.key;
      }
    }

    return SpendingVelocity(
      dailyAverage: dailyAverage.toDouble(),
      weeklyAverage: weeklyAverage.toDouble(),
      monthlyAverage: monthlyAverage.toDouble(),
      totalExpenses: totalConsumptionExpenses,
      totalDays: daysDifference,
      highestDayAmount: highestDayAmount,
      highestDay: highestDay,
      lowestDayAmount: lowestDayAmount == double.infinity ? 0 : lowestDayAmount,
      lowestDay: lowestDay,
      totalSavingsInvestments: totalSavingsInvestments,
    );
  }

  /// Generate budget performance reports with improved time-based categorization
  List<BudgetPerformanceReport> getBudgetPerformanceReports({
    required String userId,
    double tolerancePercentage = 0.1, // 10% tolerance by default
  }) {
    return _getBudgetPerformanceReportsInternal(
      userId: userId,
      tolerancePercentage: tolerancePercentage,
      includePredictions: true,
    );
  }

  /// Internal method to generate budget performance reports
  List<BudgetPerformanceReport> _getBudgetPerformanceReportsInternal({
    required String userId,
    double tolerancePercentage = 0.1,
    bool includePredictions = false,
  }) {
    final activeBudgets = _databaseService.getActiveBudgets(userId: userId);
    final categories = _databaseService.getAllCategories(userId: userId);
    final reports = <BudgetPerformanceReport>[];

    for (final budget in activeBudgets) {
      final category = categories.firstWhere(
        (c) => c.id == budget.categoryId,
        orElse: () => Category(
          id: '',
          name: 'Unknown',
          icon: '❓',
          colorValue: 0,
          type: CategoryType.expense,
          userId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final actualSpent = _databaseService.getBudgetSpent(
        budget: budget,
        userId: userId,
      );

      final variance = budget.amount - actualSpent;
      final variancePercentage = budget.amount > 0
          ? (variance / budget.amount) * 100
          : 0;

      final daysInPeriod = budget.totalDays;
      final daysRemaining = budget.daysRemaining;
      final daysElapsed = daysInPeriod - daysRemaining;

      final dailyAverageSpent = daysElapsed > 0 ? actualSpent / daysElapsed : 0;
      final projectedSpending = dailyAverageSpent * daysInPeriod;

      // Calculate new time-based performance status
      final status = _calculateBudgetPerformanceStatus(
        budgetAmount: budget.amount,
        actualSpent: actualSpent,
        daysElapsed: daysElapsed,
        totalDays: daysInPeriod,
        tolerancePercentage: tolerancePercentage,
      );

      // Calculate predictive information
      final predictionInfo = includePredictions
          ? _calculateBudgetPrediction(
              budgetAmount: budget.amount,
              actualSpent: actualSpent,
              daysElapsed: daysElapsed,
              totalDays: daysInPeriod,
              dailyAverageSpent: dailyAverageSpent.toDouble(),
            )
          : null;

      reports.add(
        BudgetPerformanceReport(
          budgetId: budget.id,
          budgetName: budget.name,
          categoryName: category.name,
          budgetAmount: budget.amount,
          actualSpent: actualSpent,
          variance: variance,
          variancePercentage: variancePercentage.toDouble(),
          status: status,
          daysInPeriod: daysInPeriod,
          daysRemaining: daysRemaining,
          dailyAverageSpent: dailyAverageSpent.toDouble(),
          projectedSpending: projectedSpending.toDouble(),
          predictionInfo: predictionInfo,
        ),
      );
    }

    return reports;
  }

  /// Calculate budget performance status using time-based expected spending
  BudgetPerformanceStatus _calculateBudgetPerformanceStatus({
    required double budgetAmount,
    required double actualSpent,
    required int daysElapsed,
    required int totalDays,
    double tolerancePercentage = 0.1,
  }) {
    // Step 1: Calculate Expected Spend (E) based on time elapsed
    final expectedSpend = (daysElapsed / totalDays) * budgetAmount;

    // Step 2: Define Tolerance Range (default 10%)
    final lowerLimit = expectedSpend - (tolerancePercentage * expectedSpend);
    final upperLimit = expectedSpend + (tolerancePercentage * expectedSpend);

    // Step 3: Compare Actual Spend (S) against tolerance range
    if (actualSpent < lowerLimit) {
      return BudgetPerformanceStatus.underBudget; // 🟢 Under Budget
    } else if (actualSpent <= upperLimit) {
      return BudgetPerformanceStatus.onTrack; // 🔵 On Track
    } else {
      return BudgetPerformanceStatus.overBudget; // 🔴 Over Budget
    }
  }

  /// Calculate budget prediction information
  BudgetPredictionInfo _calculateBudgetPrediction({
    required double budgetAmount,
    required double actualSpent,
    required int daysElapsed,
    required int totalDays,
    required double dailyAverageSpent,
  }) {
    final daysRemaining = totalDays - daysElapsed;

    // Calculate when budget will be exceeded based on current daily average
    int? daysUntilOverBudget;
    if (dailyAverageSpent > 0) {
      final remainingBudget = budgetAmount - actualSpent;
      if (remainingBudget > 0) {
        daysUntilOverBudget = (remainingBudget / dailyAverageSpent).ceil();
      }
    }

    // Calculate projected spending at end of period
    final projectedSpending = actualSpent + (dailyAverageSpent * daysRemaining);

    // Determine if user is on track to exceed budget
    final willExceedBudget = projectedSpending > budgetAmount;
    final projectedOverage = willExceedBudget
        ? projectedSpending - budgetAmount
        : 0;

    // Calculate recommended daily spending to stay within budget
    double? recommendedDailySpending;
    if (daysRemaining > 0) {
      final remainingBudget = budgetAmount - actualSpent;
      recommendedDailySpending = remainingBudget / daysRemaining;
      if (recommendedDailySpending < 0) recommendedDailySpending = 0;
    }

    return BudgetPredictionInfo(
      willExceedBudget: willExceedBudget,
      projectedOverage: projectedOverage.toDouble(),
      daysUntilOverBudget: daysUntilOverBudget,
      recommendedDailySpending: recommendedDailySpending,
      projectedSpending: projectedSpending,
      confidence: _calculatePredictionConfidence(daysElapsed, totalDays),
    );
  }

  /// Calculate confidence level for budget prediction
  double _calculatePredictionConfidence(int daysElapsed, int totalDays) {
    // More data points = higher confidence
    final progressRatio = daysElapsed / totalDays;

    if (progressRatio < 0.2) return 0.3; // Low confidence with little data
    if (progressRatio < 0.5) return 0.6; // Medium confidence
    if (progressRatio < 0.8) return 0.8; // High confidence
    return 0.95; // Very high confidence with most data available
  }

  /// Compare spending between two periods
  PeriodComparison compareSpendingPeriods({
    required String userId,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
    String? baseCurrency,
  }) {
    final targetCurrency = baseCurrency ?? SupportedCurrencies.baseCurrency;

    final currentTransactions = _databaseService.getTransactionsByDateRange(
      startDate: currentStart,
      endDate: currentEnd,
      userId: userId,
    );

    final previousTransactions = _databaseService.getTransactionsByDateRange(
      startDate: previousStart,
      endDate: previousEnd,
      userId: userId,
    );

    // Convert transactions to base currency
    final convertedCurrentTransactions = _convertTransactionsToBaseCurrency(
      currentTransactions,
      targetCurrency,
    );

    final convertedPreviousTransactions = _convertTransactionsToBaseCurrency(
      previousTransactions,
      targetCurrency,
    );

    final currentExpenses = convertedCurrentTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final previousExpenses = convertedPreviousTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final currentIncome = convertedCurrentTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final previousIncome = convertedPreviousTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final expenseChange = currentExpenses - previousExpenses;
    final expenseChangePercentage = previousExpenses > 0
        ? (expenseChange / previousExpenses) * 100
        : 0;

    final incomeChange = currentIncome - previousIncome;
    final incomeChangePercentage = previousIncome > 0
        ? (incomeChange / previousIncome) * 100
        : 0;

    return PeriodComparison(
      currentPeriodStart: currentStart,
      currentPeriodEnd: currentEnd,
      previousPeriodStart: previousStart,
      previousPeriodEnd: previousEnd,
      currentExpenses: currentExpenses,
      previousExpenses: previousExpenses,
      expenseChange: expenseChange,
      expenseChangePercentage: expenseChangePercentage.toDouble(),
      currentIncome: currentIncome,
      previousIncome: previousIncome,
      incomeChange: incomeChange,
      incomeChangePercentage: incomeChangePercentage.toDouble(),
    );
  }

  /// Compare expense spending between two periods (expenses only)
  PeriodComparison compareExpensePeriods({
    required String userId,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
    String? baseCurrency,
  }) {
    final targetCurrency = baseCurrency ?? SupportedCurrencies.baseCurrency;

    final currentTransactions = _databaseService.getTransactionsByDateRange(
      startDate: currentStart,
      endDate: currentEnd,
      userId: userId,
    );

    final previousTransactions = _databaseService.getTransactionsByDateRange(
      startDate: previousStart,
      endDate: previousEnd,
      userId: userId,
    );

    // Filter to only expense transactions
    final currentExpenseTransactions = currentTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final previousExpenseTransactions = previousTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    // Convert expense transactions to base currency
    final convertedCurrentTransactions = _convertTransactionsToBaseCurrency(
      currentExpenseTransactions,
      targetCurrency,
    );

    final convertedPreviousTransactions = _convertTransactionsToBaseCurrency(
      previousExpenseTransactions,
      targetCurrency,
    );

    final currentExpenses = convertedCurrentTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    final previousExpenses = convertedPreviousTransactions.fold<double>(
      0,
      (sum, t) => sum + t.amount,
    );

    final expenseChange = currentExpenses - previousExpenses;
    final expenseChangePercentage = previousExpenses > 0
        ? (expenseChange / previousExpenses) * 100
        : 0;

    return PeriodComparison(
      currentPeriodStart: currentStart,
      currentPeriodEnd: currentEnd,
      previousPeriodStart: previousStart,
      previousPeriodEnd: previousEnd,
      currentExpenses: currentExpenses,
      previousExpenses: previousExpenses,
      expenseChange: expenseChange,
      expenseChangePercentage: expenseChangePercentage.toDouble(),
      currentIncome: 0, // No income in expense-only comparison
      previousIncome: 0, // No income in expense-only comparison
      incomeChange: 0, // No income in expense-only comparison
      incomeChangePercentage: 0, // No income in expense-only comparison
    );
  }

  /// Get financial health score (0-100)
  FinancialHealthScore calculateFinancialHealthScore({
    required String userId,
    String? baseCurrency,
  }) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final transactions = _databaseService.getTransactionsByDateRange(
      startDate: monthStart,
      endDate: monthEnd,
      userId: userId,
    );

    final targetCurrency = baseCurrency ?? SupportedCurrencies.baseCurrency;
    final convertedTransactions = _convertTransactionsToBaseCurrency(
      transactions,
      targetCurrency,
    );

    final totalIncome = convertedTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Separate savings/investments from regular expenses
    final savingsTransactions = convertedTransactions
        .where(
          (t) =>
              t.categoryId == 'expense_savings' ||
              (t.type == TransactionType.saving),
        )
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Only count consumption expenses (not savings/investments)
    final consumptionExpenses = convertedTransactions
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.categoryId != 'expense_savings',
        )
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Total expenses for income-expense ratio should only be consumption expenses
    final totalExpenses = consumptionExpenses;

    final budgets = _databaseService.getActiveBudgets(userId: userId);
    final budgetPerformance = getBudgetPerformanceReports(userId: userId);

    // Check if user has budgets created
    final hasBudgets = budgets.isNotEmpty;

    // Calculate different health metrics
    // Net income ratio (income minus consumption expenses)
    double incomeExpenseRatio = 0;
    if (totalIncome > 0) {
      incomeExpenseRatio = (totalIncome - consumptionExpenses) / totalIncome;
    }

    double budgetAdherence = 0;
    double incomeExpenseRatioWeight = 40;
    double budgetAdherenceWeight = 35;
    double savingsRateWeight = 25;

    if (hasBudgets && budgetPerformance.isNotEmpty) {
      // Budget adherence is only active when user has budgets
      final onTrackBudgets = budgetPerformance
          .where((bp) => bp.status == BudgetPerformanceStatus.onTrack)
          .length;
      budgetAdherence = onTrackBudgets / budgetPerformance.length;
    } else {
      // If no budgets are set, disable budget adherence metric and
      // redistribute weight to income-expense ratio and savings rate
      budgetAdherence = 0.0; // Set to zero when no budgets are created
      final remainingWeight = budgetAdherenceWeight;
      incomeExpenseRatioWeight +=
          remainingWeight *
          (incomeExpenseRatioWeight /
              (incomeExpenseRatioWeight + savingsRateWeight));
      savingsRateWeight +=
          remainingWeight *
          (savingsRateWeight / (incomeExpenseRatioWeight + savingsRateWeight));
      budgetAdherenceWeight = 0;
    }

    // Calculate true savings rate (savings as percentage of income)
    // This rewards saving behavior!
    double savingsRate = 0;
    if (totalIncome > 0) {
      savingsRate = (savingsTransactions / totalIncome).clamp(0.0, 1.0);
    } else {
      // If no income but person is saving, still give credit
      savingsRate = savingsTransactions > 0 ? 0.3 : 0;
    }

    // For users without budgets, heavily weight income-expense ratio and savings rate
    double adjustedScore;
    if (hasBudgets) {
      // Standard calculation when budgets exist
      adjustedScore =
          ((incomeExpenseRatio.clamp(0.0, 1.0) * incomeExpenseRatioWeight) +
                  (budgetAdherence * budgetAdherenceWeight) +
                  (savingsRate * savingsRateWeight))
              .clamp(0.0, 100.0);
    } else {
      // For users without budgets, base score primarily on income-expense ratio and savings rate
      // Give additional boost if both income-expense ratio and savings rate are good
      final incomeExpenseContribution = incomeExpenseRatio.clamp(0.0, 1.0) * 60;
      final savingsContribution = savingsRate * 40;

      adjustedScore = (incomeExpenseContribution + savingsContribution).clamp(
        0.0,
        100.0,
      );

      // Additional boost for excellent financial discipline when no budgets needed
      if (incomeExpenseRatio >= 0.3 && savingsRate >= 0.2) {
        adjustedScore = (adjustedScore * 1.1).clamp(0.0, 100.0);
      }
      if (incomeExpenseRatio >= 0.5 && savingsRate >= 0.3) {
        adjustedScore = (adjustedScore * 1.05).clamp(0.0, 100.0);
      }
    }

    String healthLevel;
    if (adjustedScore >= 80) {
      healthLevel = 'Excellent';
    } else if (adjustedScore >= 60) {
      healthLevel = 'Good';
    } else if (adjustedScore >= 40) {
      healthLevel = 'Fair';
    } else {
      healthLevel = 'Poor';
    }

    return FinancialHealthScore(
      score: adjustedScore,
      healthLevel: healthLevel,
      incomeExpenseRatio: incomeExpenseRatio,
      budgetAdherence: budgetAdherence,
      savingsRate: savingsRate,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      calculatedAt: DateTime.now(),
      hasBudgets: hasBudgets,
    );
  }

  /// Helper method to get period start and end dates
  ({DateTime start, DateTime end}) _getPeriodDates(
    ReportPeriod period,
    DateTime referenceDate,
    int periodsBack,
  ) {
    switch (period) {
      case ReportPeriod.daily:
        final date = referenceDate.subtract(Duration(days: periodsBack));
        return (
          start: DateTime(date.year, date.month, date.day),
          end: DateTime(date.year, date.month, date.day, 23, 59, 59),
        );

      case ReportPeriod.weekly:
        final weekStart = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1 + (periodsBack * 7)),
        );
        return (
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day + 6,
            23,
            59,
            59,
          ),
        );

      case ReportPeriod.monthly:
        final monthDate = DateTime(
          referenceDate.year,
          referenceDate.month - periodsBack,
          1,
        );
        return (
          start: monthDate,
          end: DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59),
        );

      case ReportPeriod.quarterly:
        final quarterStartMonth = ((referenceDate.month - 1) ~/ 3) * 3 + 1;
        final quarterDate = DateTime(
          referenceDate.year,
          quarterStartMonth - (periodsBack * 3),
          1,
        );
        return (
          start: quarterDate,
          end: DateTime(quarterDate.year, quarterDate.month + 3, 0, 23, 59, 59),
        );

      case ReportPeriod.yearly:
        final yearDate = DateTime(referenceDate.year - periodsBack, 1, 1);
        return (
          start: yearDate,
          end: DateTime(yearDate.year, 12, 31, 23, 59, 59),
        );

      case ReportPeriod.custom:
        // For custom periods, return the current month as default
        final monthStart = DateTime(referenceDate.year, referenceDate.month, 1);
        return (
          start: monthStart,
          end: DateTime(
            referenceDate.year,
            referenceDate.month + 1,
            0,
            23,
            59,
            59,
          ),
        );
    }
  }
}
