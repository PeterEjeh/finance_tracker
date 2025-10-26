import 'package:hive/hive.dart';

part 'onboarding_data.g.dart';

@HiveType(typeId: 21)
class OnboardingData extends HiveObject {
  @HiveField(0)
  UserType? userType;

  @HiveField(1)
  double? incomeAmount;

  @HiveField(2)
  IncomeFrequency? incomeFrequency;

  @HiveField(3)
  SpendingStyle? spendingStyle;

  @HiveField(4)
  List<FinancialGoal>? financialGoals;

  @HiveField(5)
  String? currencyCode;

  @HiveField(6)
  Map<String, dynamic>? preferences;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  OnboardingData({
    this.userType,
    this.incomeAmount,
    this.incomeFrequency,
    this.spendingStyle,
    this.financialGoals,
    this.currencyCode,
    this.preferences,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory OnboardingData.create() {
    return OnboardingData();
  }

  void updateProgress() {
    updatedAt = DateTime.now();
  }

  bool get isComplete {
    return userType != null &&
        incomeAmount != null &&
        incomeFrequency != null &&
        spendingStyle != null &&
        (financialGoals?.isNotEmpty ?? false) &&
        currencyCode != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'userType': userType?.name,
      'incomeAmount': incomeAmount,
      'incomeFrequency': incomeFrequency?.name,
      'spendingStyle': spendingStyle?.name,
      'financialGoals': financialGoals?.map((g) => g.name).toList(),
      'currencyCode': currencyCode,
      'preferences': preferences,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      userType: json['userType'] != null
          ? UserType.values.firstWhere(
              (e) => e.name == json['userType'],
              orElse: () => UserType.individual,
            )
          : null,
      incomeAmount: (json['incomeAmount'] as num?)?.toDouble(),
      incomeFrequency: json['incomeFrequency'] != null
          ? IncomeFrequency.values.firstWhere(
              (e) => e.name == json['incomeFrequency'],
              orElse: () => IncomeFrequency.monthly,
            )
          : null,
      spendingStyle: json['spendingStyle'] != null
          ? SpendingStyle.values.firstWhere(
              (e) => e.name == json['spendingStyle'],
              orElse: () => SpendingStyle.moderate,
            )
          : null,
      financialGoals: (json['financialGoals'] as List<dynamic>?)
          ?.map(
            (g) => FinancialGoal.values.firstWhere(
              (e) => e.name == g,
              orElse: () => FinancialGoal.save_for_emergency,
            ),
          )
          .toList(),
      currencyCode: json['currencyCode'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

@HiveType(typeId: 22)
enum UserType {
  @HiveField(0)
  individual,
  @HiveField(1)
  business,
  @HiveField(2)
  student,
  @HiveField(3)
  freelancer,
}

@HiveType(typeId: 23)
enum IncomeFrequency {
  @HiveField(0)
  weekly,
  @HiveField(1)
  biweekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  quarterly,
  @HiveField(4)
  annually,
}

@HiveType(typeId: 24)
enum SpendingStyle {
  @HiveField(0)
  conservative,
  @HiveField(1)
  moderate,
  @HiveField(2)
  aggressive,
}

@HiveType(typeId: 25)
enum FinancialGoal {
  @HiveField(0)
  save_for_emergency,
  @HiveField(1)
  buy_house,
  @HiveField(2)
  buy_car,
  @HiveField(3)
  pay_debt,
  @HiveField(4)
  invest,
  @HiveField(5)
  travel,
  @HiveField(6)
  education,
  @HiveField(7)
  retirement,
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.individual:
        return 'Individual';
      case UserType.business:
        return 'Business Owner';
      case UserType.student:
        return 'Student';
      case UserType.freelancer:
        return 'Freelancer';
    }
  }
}

extension IncomeFrequencyExtension on IncomeFrequency {
  String get displayName {
    switch (this) {
      case IncomeFrequency.weekly:
        return 'Weekly';
      case IncomeFrequency.biweekly:
        return 'Bi-weekly';
      case IncomeFrequency.monthly:
        return 'Monthly';
      case IncomeFrequency.quarterly:
        return 'Quarterly';
      case IncomeFrequency.annually:
        return 'Annually';
    }
  }
}

extension SpendingStyleExtension on SpendingStyle {
  String get displayName {
    switch (this) {
      case SpendingStyle.conservative:
        return 'Conservative';
      case SpendingStyle.moderate:
        return 'Moderate';
      case SpendingStyle.aggressive:
        return 'Aggressive';
    }
  }

  String get description {
    switch (this) {
      case SpendingStyle.conservative:
        return 'I prefer to save more and spend less';
      case SpendingStyle.moderate:
        return 'I balance saving and spending';
      case SpendingStyle.aggressive:
        return 'I\'m comfortable with higher spending';
    }
  }
}

extension FinancialGoalExtension on FinancialGoal {
  String get displayName {
    switch (this) {
      case FinancialGoal.save_for_emergency:
        return 'Build Emergency Fund';
      case FinancialGoal.buy_house:
        return 'Buy a House';
      case FinancialGoal.buy_car:
        return 'Buy a Car';
      case FinancialGoal.pay_debt:
        return 'Pay Off Debt';
      case FinancialGoal.invest:
        return 'Invest Money';
      case FinancialGoal.travel:
        return 'Travel';
      case FinancialGoal.education:
        return 'Education';
      case FinancialGoal.retirement:
        return 'Retirement';
    }
  }
}
