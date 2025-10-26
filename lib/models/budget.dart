import 'package:hive/hive.dart';
import 'currency.dart';

part 'budget.g.dart';

@HiveType(typeId: 5)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String categoryId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  BudgetPeriod period;

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  DateTime endDate;

  @HiveField(7)
  String userId;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  bool isActive;

  @HiveField(11)
  double alertThreshold; // Percentage (0.0 to 1.0) when to alert

  @HiveField(12)
  bool alertEnabled;

  @HiveField(13)
  BudgetType type;

  @HiveField(14)
  String? description;

  @HiveField(15)
  String currencyCode;

  @HiveField(16)
  String? subcategoryId;

  @HiveField(17)
  bool autoRenew; // Whether to automatically renew for next period

  Budget({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.alertThreshold = 0.8, // Alert at 80% by default
    this.alertEnabled = true,
    this.type = BudgetType.progressive,

    this.description,
    required this.currencyCode,
    this.subcategoryId,
    this.autoRenew = false,
  });

  factory Budget.create({
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
  }) {
    final now = DateTime.now();
    final start = startDate ?? _getStartDateForPeriod(period, now);
    final end = _getEndDateForPeriod(period, start);

    return Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      categoryId: categoryId,
      amount: amount,
      period: period,
      startDate: start,
      endDate: end,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      alertThreshold: alertThreshold,
      alertEnabled: alertEnabled,
      type: type,

      description: description,
      currencyCode: currencyCode ?? SupportedCurrencies.baseCurrency,
      subcategoryId: subcategoryId,
      autoRenew: autoRenew,
    );
  }

  static DateTime _getStartDateForPeriod(
    BudgetPeriod period,
    DateTime referenceDate,
  ) {
    switch (period) {
      case BudgetPeriod.weekly:
        // Start of current week (Monday)
        final daysFromMonday = referenceDate.weekday - 1;
        return DateTime(
          referenceDate.year,
          referenceDate.month,
          referenceDate.day,
        ).subtract(Duration(days: daysFromMonday));
      case BudgetPeriod.monthly:
        // Start of current month
        return DateTime(referenceDate.year, referenceDate.month, 1);
      case BudgetPeriod.quarterly:
        // Start of current quarter
        final quarterStartMonth = ((referenceDate.month - 1) ~/ 3) * 3 + 1;
        return DateTime(referenceDate.year, quarterStartMonth, 1);
      case BudgetPeriod.yearly:
        // Start of current year
        return DateTime(referenceDate.year, 1, 1);
      case BudgetPeriod.custom:
        // For custom periods, use the reference date
        return DateTime(
          referenceDate.year,
          referenceDate.month,
          referenceDate.day,
        );
    }
  }

  static DateTime _getEndDateForPeriod(
    BudgetPeriod period,
    DateTime startDate,
  ) {
    switch (period) {
      case BudgetPeriod.weekly:
        return startDate.add(const Duration(days: 6));
      case BudgetPeriod.monthly:
        return DateTime(startDate.year, startDate.month + 1, 0);
      case BudgetPeriod.quarterly:
        return DateTime(startDate.year, startDate.month + 3, 0);
      case BudgetPeriod.yearly:
        return DateTime(startDate.year, 12, 31);
      case BudgetPeriod.custom:
        // For custom periods, default to 30 days
        return startDate.add(const Duration(days: 30));
    }
  }

  bool get isCurrentPeriod {
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  int get daysRemaining {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays + 1;
  }

  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  double get progressPercentage {
    final totalDays = this.totalDays;
    final elapsedDays = DateTime.now().difference(startDate).inDays + 1;
    return (elapsedDays / totalDays).clamp(0.0, 1.0);
  }

  Budget copyWith({
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
  }) {
    return Budget(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      type: type ?? this.type,

      description: description ?? this.description,
      currencyCode: currencyCode ?? this.currencyCode,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }

  Budget renewForNextPeriod() {
    final newStartDate = _getNextPeriodStartDate();
    final newEndDate = _getEndDateForPeriod(period, newStartDate);

    return Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      categoryId: categoryId,
      amount: amount,
      period: period,
      startDate: newStartDate,
      endDate: newEndDate,
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: isActive,
      alertThreshold: alertThreshold,
      alertEnabled: alertEnabled,
      type: type,

      description: description,
      currencyCode: currencyCode,
      subcategoryId: subcategoryId,
      autoRenew: autoRenew,
    );
  }

  DateTime _getNextPeriodStartDate() {
    switch (period) {
      case BudgetPeriod.weekly:
        return endDate.add(const Duration(days: 1));
      case BudgetPeriod.monthly:
        return DateTime(endDate.year, endDate.month + 1, 1);
      case BudgetPeriod.quarterly:
        return DateTime(endDate.year, endDate.month + 1, 1);
      case BudgetPeriod.yearly:
        return DateTime(endDate.year + 1, 1, 1);
      case BudgetPeriod.custom:
        return endDate.add(const Duration(days: 1));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'amount': amount,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'alertThreshold': alertThreshold,
      'alertEnabled': alertEnabled,
      'type': type.name,

      'description': description,
      'currencyCode': currencyCode,
      'subcategoryId': subcategoryId,
      'autoRenew': autoRenew,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere((e) => e.name == json['period']),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] ?? true,
      alertThreshold: json['alertThreshold']?.toDouble() ?? 0.8,
      alertEnabled: json['alertEnabled'] ?? true,
      type: BudgetType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => BudgetType.progressive,
      ),
      description: json['description'] as String?,

      currencyCode:
          json['currencyCode'] as String? ?? SupportedCurrencies.baseCurrency,
      subcategoryId: json['subcategoryId'] as String?,
      autoRenew: json['autoRenew'] ?? false,
    );
  }

  /// Get the currency used for this budget
  Currency get currency =>
      SupportedCurrencies.getCurrency(currencyCode) ??
      Currency(
        code: currencyCode,
        name: currencyCode,
        symbol: currencyCode,
        flag: '🏳️',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Get formatted amount with currency symbol
  String get formattedAmount => currency.formatAmount(amount);
}

@HiveType(typeId: 6)
enum BudgetPeriod {
  @HiveField(0)
  weekly,
  @HiveField(1)
  monthly,
  @HiveField(2)
  quarterly,
  @HiveField(3)
  yearly,
  @HiveField(4)
  custom,
}

@HiveType(typeId: 7)
enum BudgetType {
  @HiveField(0)
  progressive,
  @HiveField(1)
  fixed,
  @HiveField(2)
  recurring,
  @HiveField(3)
  goal,
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.quarterly:
        return 'Quarterly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.custom:
        return 'Custom';
    }
  }
}

extension BudgetTypeExtension on BudgetType {
  String get displayName {
    switch (this) {
      case BudgetType.progressive:
        return 'Progressive Budget';
      case BudgetType.fixed:
        return 'Fixed/Event-Based Budget';
      case BudgetType.recurring:
        return 'Recurring Budget';
      case BudgetType.goal:
        return 'Goal-Based Budget';
    }
  }
}
