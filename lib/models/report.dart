import 'package:hive/hive.dart';
import 'transaction.dart';
import 'category.dart';
import 'budget.dart';

part 'report.g.dart';

@HiveType(typeId: 17)
class SpendingReport extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  DateTime startDate;

  @HiveField(3)
  DateTime endDate;

  @HiveField(4)
  ReportPeriod period;

  @HiveField(5)
  double totalIncome;

  @HiveField(6)
  double totalExpenses;

  @HiveField(7)
  double netAmount;

  @HiveField(8)
  List<CategorySpending> categoryBreakdown;

  @HiveField(9)
  List<DailySpending> dailyBreakdown;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  String? notes;

  SpendingReport({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netAmount,
    required this.categoryBreakdown,
    required this.dailyBreakdown,
    required this.createdAt,
    this.notes,
  });

  factory SpendingReport.create({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
    required List<Transaction> transactions,
    required List<Category> categories,
    String? notes,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Calculate totals
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount;
      }
    }

    final netAmount = totalIncome - totalExpenses;

    // Create category breakdown
    final categoryMap = <String, CategorySpending>{};
    for (final category in categories) {
      categoryMap[category.id] = CategorySpending(
        categoryId: category.id,
        categoryName: category.name,
        categoryIcon: category.icon,
        categoryColor: category.colorValue,
        totalAmount: 0,
        transactionCount: 0,
        percentage: 0,
        transactions: [],
      );
    }

    for (final transaction in transactions) {
      if (categoryMap.containsKey(transaction.categoryId)) {
        final categorySpending = categoryMap[transaction.categoryId]!;
        categorySpending.totalAmount += transaction.amount;
        categorySpending.transactionCount++;
        categorySpending.transactions.add(transaction);
      }
    }

    // Calculate percentages
    final totalForPercentage = totalExpenses > 0 ? totalExpenses : totalIncome;
    for (final categorySpending in categoryMap.values) {
      if (totalForPercentage > 0) {
        categorySpending.percentage =
            (categorySpending.totalAmount / totalForPercentage) * 100;
      }
    }

    final categoryBreakdown =
        categoryMap.values.where((cs) => cs.totalAmount > 0).toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    // Create daily breakdown
    final dailyMap = <String, DailySpending>{};
    final currentDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

    var date = currentDate;
    while (date.isBefore(endDateOnly) || date.isAtSameMomentAs(endDateOnly)) {
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyMap[dateKey] = DailySpending(
        date: date,
        totalIncome: 0,
        totalExpenses: 0,
        netAmount: 0,
        transactionCount: 0,
      );
      date = date.add(const Duration(days: 1));
    }

    for (final transaction in transactions) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      final dateKey =
          '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}-${transactionDate.day.toString().padLeft(2, '0')}';

      if (dailyMap.containsKey(dateKey)) {
        final dailySpending = dailyMap[dateKey]!;
        if (transaction.type == TransactionType.income) {
          dailySpending.totalIncome += transaction.amount;
        } else {
          dailySpending.totalExpenses += transaction.amount;
        }
        dailySpending.netAmount =
            dailySpending.totalIncome - dailySpending.totalExpenses;
        dailySpending.transactionCount++;
      }
    }

    final dailyBreakdown = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SpendingReport(
      id: id,
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: period,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netAmount: netAmount,
      categoryBreakdown: categoryBreakdown,
      dailyBreakdown: dailyBreakdown,
      createdAt: DateTime.now(),
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'period': period.name,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netAmount': netAmount,
      'categoryBreakdown': categoryBreakdown.map((cb) => cb.toJson()).toList(),
      'dailyBreakdown': dailyBreakdown.map((db) => db.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory SpendingReport.fromJson(Map<String, dynamic> json) {
    return SpendingReport(
      id: json['id'],
      userId: json['userId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      period: ReportPeriod.values.firstWhere((e) => e.name == json['period']),
      totalIncome: json['totalIncome'].toDouble(),
      totalExpenses: json['totalExpenses'].toDouble(),
      netAmount: json['netAmount'].toDouble(),
      categoryBreakdown: (json['categoryBreakdown'] as List)
          .map((cb) => CategorySpending.fromJson(cb))
          .toList(),
      dailyBreakdown: (json['dailyBreakdown'] as List)
          .map((db) => DailySpending.fromJson(db))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      notes: json['notes'],
    );
  }
}

@HiveType(typeId: 18)
class CategorySpending extends HiveObject {
  @HiveField(0)
  String categoryId;

  @HiveField(1)
  String categoryName;

  @HiveField(2)
  String categoryIcon;

  @HiveField(3)
  int categoryColor;

  @HiveField(4)
  double totalAmount;

  @HiveField(5)
  int transactionCount;

  @HiveField(6)
  double percentage;

  @HiveField(7)
  List<Transaction> transactions;

  CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
    required this.transactions,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'percentage': percentage,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      categoryIcon: json['categoryIcon'],
      categoryColor: json['categoryColor'],
      totalAmount: json['totalAmount'].toDouble(),
      transactionCount: json['transactionCount'],
      percentage: json['percentage'].toDouble(),
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
    );
  }
}

@HiveType(typeId: 19)
class DailySpending extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double totalIncome;

  @HiveField(2)
  double totalExpenses;

  @HiveField(3)
  double netAmount;

  @HiveField(4)
  int transactionCount;

  DailySpending({
    required this.date,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netAmount,
    required this.transactionCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netAmount': netAmount,
      'transactionCount': transactionCount,
    };
  }

  factory DailySpending.fromJson(Map<String, dynamic> json) {
    return DailySpending(
      date: DateTime.parse(json['date']),
      totalIncome: json['totalIncome'].toDouble(),
      totalExpenses: json['totalExpenses'].toDouble(),
      netAmount: json['netAmount'].toDouble(),
      transactionCount: json['transactionCount'],
    );
  }
}

@HiveType(typeId: 20)
enum ReportPeriod {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  quarterly,
  @HiveField(4)
  yearly,
  @HiveField(5)
  custom,
}

extension ReportPeriodExtension on ReportPeriod {
  String get displayName {
    switch (this) {
      case ReportPeriod.daily:
        return 'Daily';
      case ReportPeriod.weekly:
        return 'Weekly';
      case ReportPeriod.monthly:
        return 'Monthly';
      case ReportPeriod.quarterly:
        return 'Quarterly';
      case ReportPeriod.yearly:
        return 'Yearly';
      case ReportPeriod.custom:
        return 'Custom';
    }
  }
}

class BudgetAlertInfo {
  final String budgetId;
  final String budgetName;
  final String alertType; // Using string instead of enum to avoid conflicts
  final String message;
  final String severity; // Using string instead of enum to avoid conflicts
  final int? daysUntilIssue;
  final String? recommendedAction;
  final double confidence;

  BudgetAlertInfo({
    required this.budgetId,
    required this.budgetName,
    required this.alertType,
    required this.message,
    required this.severity,
    this.daysUntilIssue,
    this.recommendedAction,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'budgetId': budgetId,
      'budgetName': budgetName,
      'alertType': alertType,
      'message': message,
      'severity': severity,
      'daysUntilIssue': daysUntilIssue,
      'recommendedAction': recommendedAction,
      'confidence': confidence,
    };
  }

  factory BudgetAlertInfo.fromJson(Map<String, dynamic> json) {
    return BudgetAlertInfo(
      budgetId: json['budgetId'],
      budgetName: json['budgetName'],
      alertType: json['alertType'],
      message: json['message'],
      severity: json['severity'],
      daysUntilIssue: json['daysUntilIssue'],
      recommendedAction: json['recommendedAction'],
      confidence: json['confidence']?.toDouble() ?? 0,
    );
  }
}

class SpendingInsight {
  final String title;
  final String description;
  final InsightType type;
  final InsightSeverity severity;
  final String? actionRecommendation;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  SpendingInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    this.actionRecommendation,
    this.data,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'severity': severity.name,
      'actionRecommendation': actionRecommendation,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SpendingInsight.fromJson(Map<String, dynamic> json) {
    return SpendingInsight(
      title: json['title'],
      description: json['description'],
      type: InsightType.values.firstWhere((e) => e.name == json['type']),
      severity: InsightSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      actionRecommendation: json['actionRecommendation'],
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

enum InsightType {
  spending,
  saving,
  budget,
  trend,
  prediction,
  alert,
  achievement,
}

enum InsightSeverity { low, medium, high, critical }

class BudgetPerformanceReport {
  final String budgetId;
  final String budgetName;
  final String categoryName;
  final double budgetAmount;
  final double actualSpent;
  final double variance;
  final double variancePercentage;
  final BudgetPerformanceStatus status;
  final int daysInPeriod;
  final int daysRemaining;
  final double dailyAverageSpent;
  final double projectedSpending;
  final BudgetPredictionInfo? predictionInfo;

  BudgetPerformanceReport({
    required this.budgetId,
    required this.budgetName,
    required this.categoryName,
    required this.budgetAmount,
    required this.actualSpent,
    required this.variance,
    required this.variancePercentage,
    required this.status,
    required this.daysInPeriod,
    required this.daysRemaining,
    required this.dailyAverageSpent,
    required this.projectedSpending,
    this.predictionInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'budgetId': budgetId,
      'budgetName': budgetName,
      'categoryName': categoryName,
      'budgetAmount': budgetAmount,
      'actualSpent': actualSpent,
      'variance': variance,
      'variancePercentage': variancePercentage,
      'status': status.name,
      'daysInPeriod': daysInPeriod,
      'daysRemaining': daysRemaining,
      'dailyAverageSpent': dailyAverageSpent,
      'projectedSpending': projectedSpending,
      'predictionInfo': predictionInfo?.toJson(),
    };
  }

  factory BudgetPerformanceReport.fromJson(Map<String, dynamic> json) {
    return BudgetPerformanceReport(
      budgetId: json['budgetId'],
      budgetName: json['budgetName'],
      categoryName: json['categoryName'],
      budgetAmount: json['budgetAmount'].toDouble(),
      actualSpent: json['actualSpent'].toDouble(),
      variance: json['variance'].toDouble(),
      variancePercentage: json['variancePercentage'].toDouble(),
      status: BudgetPerformanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      daysInPeriod: json['daysInPeriod'],
      daysRemaining: json['daysRemaining'],
      dailyAverageSpent: json['dailyAverageSpent'].toDouble(),
      projectedSpending: json['projectedSpending'].toDouble(),
      predictionInfo: json['predictionInfo'] != null
          ? BudgetPredictionInfo.fromJson(json['predictionInfo'])
          : null,
    );
  }
}

enum BudgetPerformanceStatus { onTrack, warning, overBudget, underBudget }

class BudgetPredictionInfo {
  final bool willExceedBudget;
  final double projectedOverage;
  final int? daysUntilOverBudget;
  final double? recommendedDailySpending;
  final double projectedSpending;
  final double confidence;

  BudgetPredictionInfo({
    required this.willExceedBudget,
    required this.projectedOverage,
    this.daysUntilOverBudget,
    this.recommendedDailySpending,
    required this.projectedSpending,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'willExceedBudget': willExceedBudget,
      'projectedOverage': projectedOverage,
      'daysUntilOverBudget': daysUntilOverBudget,
      'recommendedDailySpending': recommendedDailySpending,
      'projectedSpending': projectedSpending,
      'confidence': confidence,
    };
  }

  factory BudgetPredictionInfo.fromJson(Map<String, dynamic> json) {
    return BudgetPredictionInfo(
      willExceedBudget: json['willExceedBudget'] ?? false,
      projectedOverage: json['projectedOverage']?.toDouble() ?? 0,
      daysUntilOverBudget: json['daysUntilOverBudget'],
      recommendedDailySpending: json['recommendedDailySpending']?.toDouble(),
      projectedSpending: json['projectedSpending']?.toDouble() ?? 0,
      confidence: json['confidence']?.toDouble() ?? 0,
    );
  }
}

// Supporting data classes for analytics
class SpendingTrend {
  final DateTime period;
  final double totalIncome;
  final double totalExpenses;
  final double netAmount;
  final int transactionCount;

  SpendingTrend({
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netAmount,
    required this.transactionCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'period': period.toIso8601String(),
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netAmount': netAmount,
      'transactionCount': transactionCount,
    };
  }

  factory SpendingTrend.fromJson(Map<String, dynamic> json) {
    return SpendingTrend(
      period: DateTime.parse(json['period']),
      totalIncome: json['totalIncome'].toDouble(),
      totalExpenses: json['totalExpenses'].toDouble(),
      netAmount: json['netAmount'].toDouble(),
      transactionCount: json['transactionCount'],
    );
  }
}

class SpendingVelocity {
  final double dailyAverage;
  final double weeklyAverage;
  final double monthlyAverage;
  final double totalExpenses;
  final int totalDays;
  final double highestDayAmount;
  final DateTime? highestDay;
  final double lowestDayAmount;
  final DateTime? lowestDay;
  final double totalSavingsInvestments;

  SpendingVelocity({
    required this.dailyAverage,
    required this.weeklyAverage,
    required this.monthlyAverage,
    required this.totalExpenses,
    required this.totalDays,
    required this.highestDayAmount,
    this.highestDay,
    required this.lowestDayAmount,
    this.lowestDay,
    required this.totalSavingsInvestments,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyAverage': dailyAverage,
      'weeklyAverage': weeklyAverage,
      'monthlyAverage': monthlyAverage,
      'totalExpenses': totalExpenses,
      'totalDays': totalDays,
      'highestDayAmount': highestDayAmount,
      'highestDay': highestDay?.toIso8601String(),
      'lowestDayAmount': lowestDayAmount,
      'lowestDay': lowestDay?.toIso8601String(),
      'totalSavingsInvestments': totalSavingsInvestments,
    };
  }

  factory SpendingVelocity.fromJson(Map<String, dynamic> json) {
    return SpendingVelocity(
      dailyAverage: json['dailyAverage'].toDouble(),
      weeklyAverage: json['weeklyAverage'].toDouble(),
      monthlyAverage: json['monthlyAverage'].toDouble(),
      totalExpenses: json['totalExpenses'].toDouble(),
      totalDays: json['totalDays'],
      highestDayAmount: json['highestDayAmount'].toDouble(),
      highestDay: json['highestDay'] != null
          ? DateTime.parse(json['highestDay'])
          : null,
      lowestDayAmount: json['lowestDayAmount'].toDouble(),
      lowestDay: json['lowestDay'] != null
          ? DateTime.parse(json['lowestDay'])
          : null,
      totalSavingsInvestments: json['totalSavingsInvestments']?.toDouble() ?? 0,
    );
  }
}

class PeriodComparison {
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime previousPeriodStart;
  final DateTime previousPeriodEnd;
  final double currentExpenses;
  final double previousExpenses;
  final double expenseChange;
  final double expenseChangePercentage;
  final double currentIncome;
  final double previousIncome;
  final double incomeChange;
  final double incomeChangePercentage;

  PeriodComparison({
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.previousPeriodStart,
    required this.previousPeriodEnd,
    required this.currentExpenses,
    required this.previousExpenses,
    required this.expenseChange,
    required this.expenseChangePercentage,
    required this.currentIncome,
    required this.previousIncome,
    required this.incomeChange,
    required this.incomeChangePercentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPeriodStart': currentPeriodStart.toIso8601String(),
      'currentPeriodEnd': currentPeriodEnd.toIso8601String(),
      'previousPeriodStart': previousPeriodStart.toIso8601String(),
      'previousPeriodEnd': previousPeriodEnd.toIso8601String(),
      'currentExpenses': currentExpenses,
      'previousExpenses': previousExpenses,
      'expenseChange': expenseChange,
      'expenseChangePercentage': expenseChangePercentage,
      'currentIncome': currentIncome,
      'previousIncome': previousIncome,
      'incomeChange': incomeChange,
      'incomeChangePercentage': incomeChangePercentage,
    };
  }

  factory PeriodComparison.fromJson(Map<String, dynamic> json) {
    return PeriodComparison(
      currentPeriodStart: DateTime.parse(json['currentPeriodStart']),
      currentPeriodEnd: DateTime.parse(json['currentPeriodEnd']),
      previousPeriodStart: DateTime.parse(json['previousPeriodStart']),
      previousPeriodEnd: DateTime.parse(json['previousPeriodEnd']),
      currentExpenses: json['currentExpenses'].toDouble(),
      previousExpenses: json['previousExpenses'].toDouble(),
      expenseChange: json['expenseChange'].toDouble(),
      expenseChangePercentage: json['expenseChangePercentage'].toDouble(),
      currentIncome: json['currentIncome'].toDouble(),
      previousIncome: json['previousIncome'].toDouble(),
      incomeChange: json['incomeChange'].toDouble(),
      incomeChangePercentage: json['incomeChangePercentage'].toDouble(),
    );
  }
}

class FinancialHealthScore {
  final double score;
  final String healthLevel;
  final double incomeExpenseRatio;
  final double budgetAdherence;
  final double savingsRate;
  final double totalIncome;
  final double totalExpenses;
  final DateTime calculatedAt;
  final bool hasBudgets;

  FinancialHealthScore({
    required this.score,
    required this.healthLevel,
    required this.incomeExpenseRatio,
    required this.budgetAdherence,
    required this.savingsRate,
    required this.totalIncome,
    required this.totalExpenses,
    required this.calculatedAt,
    required this.hasBudgets,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'healthLevel': healthLevel,
      'incomeExpenseRatio': incomeExpenseRatio,
      'budgetAdherence': budgetAdherence,
      'savingsRate': savingsRate,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'calculatedAt': calculatedAt.toIso8601String(),
      'hasBudgets': hasBudgets,
    };
  }

  factory FinancialHealthScore.fromJson(Map<String, dynamic> json) {
    return FinancialHealthScore(
      score: json['score'].toDouble(),
      healthLevel: json['healthLevel'],
      incomeExpenseRatio: json['incomeExpenseRatio'].toDouble(),
      budgetAdherence: json['budgetAdherence'].toDouble(),
      savingsRate: json['savingsRate'].toDouble(),
      totalIncome: json['totalIncome'].toDouble(),
      totalExpenses: json['totalExpenses'].toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt']),
      hasBudgets: json['hasBudgets'] ?? false,
    );
  }
}
