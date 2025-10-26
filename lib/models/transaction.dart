import 'package:hive/hive.dart';
import 'currency.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  TransactionType type;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? description;

  @HiveField(7)
  String? receiptImagePath;

  @HiveField(8)
  String userId;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  String? tags;

  @HiveField(12)
  String? location;

  @HiveField(13)
  bool isRecurring;

  @HiveField(14)
  RecurringType? recurringType;

  @HiveField(15)
  DateTime? nextRecurringDate;

  @HiveField(16)
  String currencyCode;

  @HiveField(17)
  double? originalAmount;

  @HiveField(18)
  String? originalCurrencyCode;

  @HiveField(19)
  double? exchangeRate;

  @HiveField(20)
  double? convertedAmount;

  @HiveField(21)
  String? subcategoryId;

  @HiveField(22)
  String? budgetId;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.type,
    required this.date,
    this.description,
    this.receiptImagePath,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
    this.location,
    this.isRecurring = false,
    this.recurringType,
    this.nextRecurringDate,
    required this.currencyCode,
    this.originalAmount,
    this.originalCurrencyCode,
    this.exchangeRate,
    this.convertedAmount,
    this.subcategoryId,
    this.budgetId,
  });

  factory Transaction.create({
    required String title,
    required double amount,
    required String categoryId,
    required TransactionType type,
    required String userId,
    DateTime? date,
    String? description,
    String? receiptImagePath,
    String? tags,
    String? location,
    bool isRecurring = false,
    RecurringType? recurringType,
    String? currencyCode,
    double? originalAmount,
    String? originalCurrencyCode,
    double? exchangeRate,
    double? convertedAmount,
    String? subcategoryId,
    String? budgetId,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      categoryId: categoryId,
      type: type,
      date: date ?? now,
      description: description,
      receiptImagePath: receiptImagePath,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      tags: tags,
      location: location,
      isRecurring: isRecurring,
      recurringType: recurringType,
      nextRecurringDate: isRecurring && recurringType != null
          ? _calculateNextRecurringDate(now, recurringType)
          : null,
      currencyCode: currencyCode ?? SupportedCurrencies.baseCurrency,
      originalAmount: originalAmount,
      originalCurrencyCode: originalCurrencyCode,
      exchangeRate: exchangeRate,
      convertedAmount: convertedAmount,
      subcategoryId: subcategoryId,
      budgetId: budgetId,
    );
  }

  static DateTime _calculateNextRecurringDate(
    DateTime from,
    RecurringType type,
  ) {
    switch (type) {
      case RecurringType.daily:
        return from.add(const Duration(days: 1));
      case RecurringType.weekly:
        return from.add(const Duration(days: 7));
      case RecurringType.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurringType.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  void updateNextRecurringDate() {
    if (isRecurring && recurringType != null) {
      nextRecurringDate = _calculateNextRecurringDate(date, recurringType!);
      updatedAt = DateTime.now();
    }
  }

  Transaction copyWith({
    String? title,
    double? amount,
    String? categoryId,
    TransactionType? type,
    DateTime? date,
    String? description,
    String? receiptImagePath,
    String? tags,
    String? location,
    bool? isRecurring,
    RecurringType? recurringType,
    String? currencyCode,
    double? originalAmount,
    String? originalCurrencyCode,
    double? exchangeRate,
    double? convertedAmount,
    String? subcategoryId,
    String? budgetId,
  }) {
    return Transaction(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      userId: userId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: tags ?? this.tags,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      nextRecurringDate:
          (isRecurring ?? this.isRecurring) &&
              (recurringType ?? this.recurringType) != null
          ? _calculateNextRecurringDate(
              date ?? this.date,
              recurringType ?? this.recurringType!,
            )
          : null,
      currencyCode: currencyCode ?? this.currencyCode,
      originalAmount: originalAmount ?? this.originalAmount,
      originalCurrencyCode: originalCurrencyCode ?? this.originalCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      budgetId: budgetId ?? this.budgetId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'type': type.name,
      'date': date.toIso8601String(),
      'description': description,
      'receiptImagePath': receiptImagePath,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'location': location,
      'isRecurring': isRecurring,
      'recurringType': recurringType?.name,
      'nextRecurringDate': nextRecurringDate?.toIso8601String(),
      'currencyCode': currencyCode,
      'originalAmount': originalAmount,
      'originalCurrencyCode': originalCurrencyCode,
      'exchangeRate': exchangeRate,
      'convertedAmount': convertedAmount,
      'budgetId': budgetId,
      'subcategoryId': subcategoryId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      receiptImagePath: json['receiptImagePath'] as String?,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      tags: json['tags'] as String?,
      location: json['location'] as String?,
      isRecurring: json['isRecurring'] ?? false,
      recurringType: json['recurringType'] != null
          ? RecurringType.values.firstWhere(
              (e) => e.name == json['recurringType'],
            )
          : null,
      nextRecurringDate: json['nextRecurringDate'] != null
          ? DateTime.parse(json['nextRecurringDate'] as String)
          : null,
      currencyCode:
          json['currencyCode'] as String? ?? SupportedCurrencies.baseCurrency,
      originalAmount: json['originalAmount']?.toDouble(),
      originalCurrencyCode: json['originalCurrencyCode'] as String?,
      exchangeRate: json['exchangeRate']?.toDouble(),
      convertedAmount: json['convertedAmount']?.toDouble(),
      budgetId: json['budgetId'] as String?,
      subcategoryId: json['subcategoryId'] as String?,
    );
  }

  /// Get the display amount in the specified currency
  CurrencyAmount getDisplayAmount([String? targetCurrency]) {
    final target = targetCurrency ?? SupportedCurrencies.baseCurrency;

    if (currencyCode == target) {
      return CurrencyAmount(amount: amount, currencyCode: currencyCode);
    }

    // If we have original amount and it matches target, use it
    if (originalCurrencyCode == target && originalAmount != null) {
      return CurrencyAmount(
        amount: originalAmount!,
        currencyCode: originalCurrencyCode!,
      );
    }

    // Otherwise, return the stored amount with its currency
    return CurrencyAmount(amount: amount, currencyCode: currencyCode);
  }

  /// Check if this transaction involves currency conversion
  bool get isMultiCurrency =>
      originalCurrencyCode != null && originalCurrencyCode != currencyCode;

  /// Get the currency used for this transaction
  Currency get currency {
    final foundCurrency = SupportedCurrencies.getCurrency(currencyCode);
    if (foundCurrency != null) return foundCurrency;

    // Fallback currency if not found
    final now = DateTime.now();
    return Currency(
      code: currencyCode,
      name: currencyCode,
      symbol: currencyCode,
      flag: '🏳️',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get the original currency if different from stored currency
  Currency? get originalCurrency => originalCurrencyCode != null
      ? SupportedCurrencies.getCurrency(originalCurrencyCode!)
      : null;
}

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
  @HiveField(2)
  saving,
}

@HiveType(typeId: 2)
enum RecurringType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}
