import 'package:hive/hive.dart';
import 'currency.dart';

part 'savings_contribution.g.dart';

@HiveType(typeId: 11)
class SavingsContribution extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String savingsGoalId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? note;

  @HiveField(5)
  String userId;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  String currencyCode;

  @HiveField(9)
  SavingsContributionType type;

  SavingsContribution({
    required this.id,
    required this.savingsGoalId,
    required this.amount,
    required this.date,
    this.note,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.currencyCode,
    this.type = SavingsContributionType.manual,
  });
  factory SavingsContribution.create({
    required String savingsGoalId,
    required double amount,
    required String userId,
    DateTime? date,
    String? note,
    String? currencyCode,
    SavingsContributionType type = SavingsContributionType.manual,
  }) {
    final now = DateTime.now();
    return SavingsContribution(
      id: now.millisecondsSinceEpoch.toString(),
      savingsGoalId: savingsGoalId,
      amount: amount,
      date: date ?? now,
      note: note,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      currencyCode: currencyCode ?? SupportedCurrencies.baseCurrency,
      type: type,
    );
  }

  SavingsContribution copyWith({
    String? savingsGoalId,
    double? amount,
    DateTime? date,
    String? note,
    String? currencyCode,
    SavingsContributionType? type,
  }) {
    return SavingsContribution(
      id: id,
      savingsGoalId: savingsGoalId ?? this.savingsGoalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      userId: userId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      currencyCode: currencyCode ?? this.currencyCode,
      type: type ?? this.type,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'savingsGoalId': savingsGoalId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'currencyCode': currencyCode,
      'type': type.name,
    };
  }

  factory SavingsContribution.fromJson(Map<String, dynamic> json) {
    return SavingsContribution(
      id: json['id'],
      savingsGoalId: json['savingsGoalId'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      note: json['note'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      currencyCode: json['currencyCode'] ?? SupportedCurrencies.baseCurrency,
      type: SavingsContributionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SavingsContributionType.manual,
      ),
    );
  }

  /// Get the currency used for this contribution
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
@HiveType(typeId: 12)
enum SavingsContributionType {
  @HiveField(0)
  manual,
  @HiveField(1)
  automatic,
}

extension SavingsContributionTypeExtension on SavingsContributionType {
  String get displayName {
    switch (this) {
      case SavingsContributionType.manual:
        return 'Manual';
      case SavingsContributionType.automatic:
        return 'Automatic';
    }
  }
}
