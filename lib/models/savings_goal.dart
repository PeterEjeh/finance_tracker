import 'package:hive/hive.dart';
import 'currency.dart';

part 'savings_goal.g.dart';

@HiveType(typeId: 9)
class SavingsGoal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  double targetAmount;

  @HiveField(4)
  double currentAmount;

  @HiveField(5)
  DateTime targetDate;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  String userId;

  @HiveField(9)
  String currencyCode;

  @HiveField(10)
  bool isActive;

  @HiveField(11)
  bool isCompleted;

  @HiveField(12)
  DateTime? completedAt;

  @HiveField(13)
  SavingsGoalFrequency contributionFrequency;

  @HiveField(14)
  double? suggestedContribution;

  @HiveField(15)
  String? categoryId;

  @HiveField(16)
  bool alertEnabled;

  @HiveField(17)
  double alertThreshold;

  SavingsGoal({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.currencyCode,
    this.isActive = true,
    this.isCompleted = false,
    this.completedAt,
    this.contributionFrequency = SavingsGoalFrequency.monthly,
    this.suggestedContribution,
    this.categoryId,
    this.alertEnabled = true,
    this.alertThreshold = 0.5, // Alert when 50% of time has passed
  });
  factory SavingsGoal.create({
    required String name,
    String? description,
    required double targetAmount,
    required DateTime targetDate,
    required String userId,
    String? currencyCode,
    SavingsGoalFrequency contributionFrequency = SavingsGoalFrequency.monthly,
    String? categoryId,
    bool alertEnabled = true,
    double alertThreshold = 0.5,
  }) {
    final now = DateTime.now();
    final goal = SavingsGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      targetAmount: targetAmount,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: now,
      userId: userId,
      currencyCode: currencyCode ?? SupportedCurrencies.baseCurrency,
      contributionFrequency: contributionFrequency,
      categoryId: categoryId,
      alertEnabled: alertEnabled,
      alertThreshold: alertThreshold,
    );
    
    // Calculate suggested contribution based on target date and frequency
    goal._calculateSuggestedContribution();
    return goal;
  }

  void _calculateSuggestedContribution() {
    final remainingAmount = targetAmount - currentAmount;
    final now = DateTime.now();
    final daysUntilTarget = targetDate.difference(now).inDays;
    
    if (daysUntilTarget <= 0 || remainingAmount <= 0) {
      suggestedContribution = 0.0;
      return;
    }
    
    switch (contributionFrequency) {
      case SavingsGoalFrequency.daily:
        suggestedContribution = remainingAmount / daysUntilTarget;
        break;
      case SavingsGoalFrequency.weekly:
        final weeksUntilTarget = (daysUntilTarget / 7).ceil();
        suggestedContribution = remainingAmount / weeksUntilTarget;
        break;
      case SavingsGoalFrequency.monthly:
        final monthsUntilTarget = (daysUntilTarget / 30).ceil();
        suggestedContribution = remainingAmount / monthsUntilTarget;
        break;
    }
  }
  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  int get daysRemaining {
    if (isCompleted) return 0;
    final remaining = targetDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining < 0 ? 0.0 : remaining;
  }

  String get progressText {
    return '${currency.formatAmount(currentAmount)} of ${currency.formatAmount(targetAmount)}';
  }

  void addContribution(double amount) {
    currentAmount += amount;
    updatedAt = DateTime.now();
    
    if (currentAmount >= targetAmount && !isCompleted) {
      isCompleted = true;
      completedAt = DateTime.now();
    }
    
    // Recalculate suggested contribution
    _calculateSuggestedContribution();
  }

  void removeContribution(double amount) {
    currentAmount -= amount;
    if (currentAmount < 0) currentAmount = 0;
    updatedAt = DateTime.now();
    
    // If was completed but now not enough, mark as not completed
    if (currentAmount < targetAmount && isCompleted) {
      isCompleted = false;
      completedAt = null;
    }
    
    _calculateSuggestedContribution();
  }
  SavingsGoal copyWith({
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? currencyCode,
    bool? isActive,
    bool? isCompleted,
    DateTime? completedAt,
    SavingsGoalFrequency? contributionFrequency,
    double? suggestedContribution,
    String? categoryId,
    bool? alertEnabled,
    double? alertThreshold,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      userId: userId,
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      contributionFrequency: contributionFrequency ?? this.contributionFrequency,
      suggestedContribution: suggestedContribution ?? this.suggestedContribution,
      categoryId: categoryId ?? this.categoryId,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'currencyCode': currencyCode,
      'isActive': isActive,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'contributionFrequency': contributionFrequency.name,
      'suggestedContribution': suggestedContribution,
      'categoryId': categoryId,
      'alertEnabled': alertEnabled,
      'alertThreshold': alertThreshold,
    };
  }
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    final userIdValue = json['userId'];
    if (userIdValue == null) {
      throw ArgumentError('userId field is missing in SavingsGoal.fromJson. JSON: $json');
    }
    if (!(userIdValue is String)) {
      throw ArgumentError('userId field must be a String in SavingsGoal.fromJson. Found: ${userIdValue.runtimeType}. JSON: $json');
    }

    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      userId: userIdValue,
      currencyCode: json['currencyCode'] as String? ?? SupportedCurrencies.baseCurrency,
      isActive: json['isActive'] as bool? ?? true,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      contributionFrequency: SavingsGoalFrequency.values.firstWhere(
        (e) => e.name == (json['contributionFrequency'] as String?),
        orElse: () => SavingsGoalFrequency.monthly,
      ),
      suggestedContribution: (json['suggestedContribution'] as num?)?.toDouble(),
      categoryId: json['categoryId'] as String?,
      alertEnabled: json['alertEnabled'] as bool? ?? true,
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble() ?? 0.5,
    );
  }

  /// Get the currency used for this savings goal
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

  /// Get formatted target amount with currency symbol
  String get formattedTargetAmount => currency.formatAmount(targetAmount);

  /// Get formatted current amount with currency symbol
  String get formattedCurrentAmount => currency.formatAmount(currentAmount);

  /// Get formatted remaining amount with currency symbol
  String get formattedRemainingAmount => currency.formatAmount(remainingAmount);

  /// Get formatted suggested contribution with currency symbol
  String get formattedSuggestedContribution => 
      suggestedContribution != null ? currency.formatAmount(suggestedContribution!) : '0.00';
}
@HiveType(typeId: 10)
enum SavingsGoalFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
}

extension SavingsGoalFrequencyExtension on SavingsGoalFrequency {
  String get displayName {
    switch (this) {
      case SavingsGoalFrequency.daily:
        return 'Daily';
      case SavingsGoalFrequency.weekly:
        return 'Weekly';
      case SavingsGoalFrequency.monthly:
        return 'Monthly';
    }
  }
}
