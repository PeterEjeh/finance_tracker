import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'currency.g.dart';

@HiveType(typeId: 13)
class Currency extends HiveObject {
  @HiveField(0)
  String code;

  @HiveField(1)
  String name;

  @HiveField(2)
  String symbol;

  @HiveField(3)
  String flag;

  @HiveField(4)
  int decimalPlaces;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.decimalPlaces = 2,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Currency.create({
    required String code,
    required String name,
    required String symbol,
    required String flag,
    int decimalPlaces = 2,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return Currency(
      code: code,
      name: name,
      symbol: symbol,
      flag: flag,
      decimalPlaces: decimalPlaces,
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  Currency copyWith({
    String? code,
    String? name,
    String? symbol,
    String? flag,
    int? decimalPlaces,
    bool? isActive,
  }) {
    return Currency(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      flag: flag ?? this.flag,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'flag': flag,
      'decimalPlaces': decimalPlaces,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'],
      name: json['name'],
      symbol: json['symbol'],
      flag: json['flag'],
      decimalPlaces: json['decimalPlaces'] ?? 2,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalPlaces,
    ).format(amount);
  }

  @override
  String toString() => '$code ($symbol)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

@HiveType(typeId: 14)
class ExchangeRate extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fromCurrency;

  @HiveField(2)
  String toCurrency;

  @HiveField(3)
  double rate;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  ExchangeRateSource source;

  @HiveField(8)
  bool isHistorical;

  ExchangeRate({
    required this.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.source = ExchangeRateSource.api,
    this.isHistorical = false,
  });

  factory ExchangeRate.create({
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    DateTime? date,
    ExchangeRateSource source = ExchangeRateSource.api,
    bool isHistorical = false,
  }) {
    final now = DateTime.now();
    final rateDate = date ?? now;
    final id =
        '${fromCurrency}_${toCurrency}_${rateDate.millisecondsSinceEpoch}';

    return ExchangeRate(
      id: id,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      rate: rate,
      date: rateDate,
      createdAt: now,
      updatedAt: now,
      source: source,
      isHistorical: isHistorical,
    );
  }

  ExchangeRate copyWith({
    double? rate,
    DateTime? date,
    ExchangeRateSource? source,
    bool? isHistorical,
  }) {
    return ExchangeRate(
      id: id,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      rate: rate ?? this.rate,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      source: source ?? this.source,
      isHistorical: isHistorical ?? this.isHistorical,
    );
  }

  double convert(double amount) {
    return amount * rate;
  }

  double reverseConvert(double amount) {
    return amount / rate;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'rate': rate,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'source': source.name,
      'isHistorical': isHistorical,
    };
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      id: json['id'],
      fromCurrency: json['fromCurrency'],
      toCurrency: json['toCurrency'],
      rate: json['rate'].toDouble(),
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      source: ExchangeRateSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => ExchangeRateSource.api,
      ),
      isHistorical: json['isHistorical'] ?? false,
    );
  }

  @override
  String toString() => '$fromCurrency/$toCurrency: $rate';
}

@HiveType(typeId: 15)
class CurrencyAmount extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String currencyCode;

  @HiveField(2)
  double? convertedAmount;

  @HiveField(3)
  String? baseCurrencyCode;

  @HiveField(4)
  double? exchangeRate;

  @HiveField(5)
  DateTime? exchangeRateDate;

  CurrencyAmount({
    required this.amount,
    required this.currencyCode,
    this.convertedAmount,
    this.baseCurrencyCode,
    this.exchangeRate,
    this.exchangeRateDate,
  });

  factory CurrencyAmount.create({
    required double amount,
    required String currencyCode,
    double? convertedAmount,
    String? baseCurrencyCode,
    double? exchangeRate,
    DateTime? exchangeRateDate,
  }) {
    return CurrencyAmount(
      amount: amount,
      currencyCode: currencyCode,
      convertedAmount: convertedAmount,
      baseCurrencyCode: baseCurrencyCode,
      exchangeRate: exchangeRate,
      exchangeRateDate: exchangeRateDate,
    );
  }

  CurrencyAmount copyWith({
    double? amount,
    String? currencyCode,
    double? convertedAmount,
    String? baseCurrencyCode,
    double? exchangeRate,
    DateTime? exchangeRateDate,
  }) {
    return CurrencyAmount(
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      exchangeRateDate: exchangeRateDate ?? this.exchangeRateDate,
    );
  }

  bool get isConverted => convertedAmount != null && baseCurrencyCode != null;

  double get displayAmount => convertedAmount ?? amount;

  String get displayCurrencyCode => baseCurrencyCode ?? currencyCode;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currencyCode': currencyCode,
      'convertedAmount': convertedAmount,
      'baseCurrencyCode': baseCurrencyCode,
      'exchangeRate': exchangeRate,
      'exchangeRateDate': exchangeRateDate?.toIso8601String(),
    };
  }

  factory CurrencyAmount.fromJson(Map<String, dynamic> json) {
    return CurrencyAmount(
      amount: json['amount'].toDouble(),
      currencyCode: json['currencyCode'] ?? SupportedCurrencies.baseCurrency,
      convertedAmount: json['convertedAmount']?.toDouble(),
      baseCurrencyCode: json['baseCurrencyCode'],
      exchangeRate: json['exchangeRate']?.toDouble(),
      exchangeRateDate: json['exchangeRateDate'] != null
          ? DateTime.parse(json['exchangeRateDate'])
          : null,
    );
  }

  @override
  String toString() => '$amount $currencyCode';
}

@HiveType(typeId: 16)
enum ExchangeRateSource {
  @HiveField(0)
  api,
  @HiveField(1)
  manual,
  @HiveField(2)
  cached,
  @HiveField(3)
  historical,
}

// Predefined currencies with NGN as base
class SupportedCurrencies {
  static const String baseCurrency = 'NGN';

  static final List<Currency> currencies = [
    Currency.create(
      code: 'NGN',
      name: 'Nigerian Naira',
      symbol: '₦',
      flag: '🇳🇬',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'USD',
      name: 'US Dollar',
      symbol: '\$',
      flag: '🇺🇸',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      flag: '🇬🇧',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      flag: '🇯🇵',
      decimalPlaces: 0,
    ),
    Currency.create(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: 'C\$',
      flag: '🇨🇦',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      flag: '🇦🇺',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'CHF',
      flag: '🇨🇭',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'CNY',
      name: 'Chinese Yuan',
      symbol: '¥',
      flag: '🇨🇳',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      flag: '🇮🇳',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'ZAR',
      name: 'South African Rand',
      symbol: 'R',
      flag: '🇿🇦',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'KES',
      name: 'Kenyan Shilling',
      symbol: 'KSh',
      flag: '🇰🇪',
      decimalPlaces: 2,
    ),
    Currency.create(
      code: 'GHS',
      name: 'Ghanaian Cedi',
      symbol: '₵',
      flag: '🇬🇭',
      decimalPlaces: 2,
    ),
  ];

  static Currency? getCurrency(String code) {
    try {
      return currencies.firstWhere((currency) => currency.code == code);
    } catch (e) {
      return null;
    }
  }

  static Currency get baseCurrencyObject {
    return currencies.firstWhere((currency) => currency.code == baseCurrency);
  }

  static List<Currency> get popularCurrencies {
    return currencies
        .where(
          (currency) => [
            'NGN',
            'USD',
            'EUR',
            'GBP',
            'JPY',
            'CAD',
            'AUD',
            'GHS',
          ].contains(currency.code),
        )
        .toList();
  }

  static List<Currency> get africanCurrencies {
    return currencies
        .where(
          (currency) => ['NGN', 'ZAR', 'KES', 'GHS'].contains(currency.code),
        )
        .toList();
  }

  static Map<String, List<int>> get monthlySalaryRanges {
    return {
      'NGN': [50000, 100000, 200000, 500000, 1000000], // Nigerian Naira
      'USD': [2000, 3000, 5000, 7500, 10000], // US Dollar
      'EUR': [2000, 3000, 4000, 6000, 8000], // Euro
      'GBP': [1500, 2500, 4000, 6000, 8000], // British Pound
      'JPY': [200000, 300000, 500000, 750000, 1000000], // Japanese Yen
      'CAD': [2000, 3000, 4000, 6000, 8000], // Canadian Dollar
      'AUD': [2000, 3000, 4000, 6000, 8000], // Australian Dollar
      'CHF': [3000, 4000, 6000, 8000, 10000], // Swiss Franc
      'CNY': [5000, 8000, 12000, 18000, 25000], // Chinese Yuan
      'INR': [20000, 40000, 70000, 100000, 150000], // Indian Rupee
      'ZAR': [10000, 20000, 30000, 50000, 80000], // South African Rand
      'KES': [30000, 50000, 80000, 120000, 180000], // Kenyan Shilling
      'GHS': [2000, 4000, 7000, 10000, 15000], // Ghanaian Cedi
    };
  }
}

// Currency formatting utilities
extension CurrencyFormatting on Currency {
  String formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalPlaces,
    );
    return formatter.format(amount);
  }

  String formatAmountWithCode(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalPlaces,
    );
    final formatted = formatter.format(amount).trim();
    return '$formatted $code';
  }
}

extension CurrencyAmountFormatting on CurrencyAmount {
  String get formattedAmount {
    final currency = SupportedCurrencies.getCurrency(currencyCode);
    if (currency != null) {
      return currency.formatAmount(amount);
    }
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    return '${formatter.format(amount).trim()} $currencyCode';
  }

  String get formattedDisplayAmount {
    final currency = SupportedCurrencies.getCurrency(displayCurrencyCode);
    if (currency != null) {
      return currency.formatAmount(displayAmount);
    }
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    return '${formatter.format(displayAmount).trim()} $displayCurrencyCode';
  }

  String get formattedWithConversion {
    if (isConverted) {
      final originalCurrency = SupportedCurrencies.getCurrency(currencyCode);
      final baseCurrency = SupportedCurrencies.getCurrency(baseCurrencyCode!);

      if (originalCurrency != null && baseCurrency != null) {
        return '${originalCurrency.formatAmount(amount)} (${baseCurrency.formatAmount(convertedAmount!)})';
      }
    }
    return formattedAmount;
  }
}
