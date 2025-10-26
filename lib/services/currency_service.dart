import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart'; // Import Hive
import '../models/currency.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  static const String _apiKey = '6a3e78ffcd2b6383aa5c0875';
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  // Hive box for settings
  late Box _settingsBox;
  static const String _baseCurrencyKey = 'baseCurrency';
  static const String _defaultBaseCurrency = 'NGN';

  // Cache for exchange rates
  final Map<String, ExchangeRate> _rateCache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(hours: 1);

  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
  }

  /// Get current exchange rate from one currency to another
  Future<ExchangeRate?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    final cacheKey = '${fromCurrency}_$toCurrency';
    if (!forceRefresh && _isCacheValid() && _rateCache.containsKey(cacheKey)) {
      return _rateCache[cacheKey];
    }

    try {
      final url = '$_baseUrl/$_apiKey/pair/$fromCurrency/$toCurrency';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] == 'success') {
          final rate = ExchangeRate.create(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: data['conversion_rate'].toDouble(),
            source: ExchangeRateSource.api,
          );

          // Cache the rate
          _rateCache[cacheKey] = rate;
          _lastCacheUpdate = DateTime.now();

          return rate;
        } else {
          throw Exception('API Error: ${data['error-type']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exchange rate: $e');

      // Try to return cached rate if available
      if (_rateCache.containsKey(cacheKey)) {
        return _rateCache[cacheKey];
      }

      return null;
    }
  }

  /// Get multiple exchange rates for a base currency
  Future<Map<String, ExchangeRate>> getMultipleRates({
    required String baseCurrency,
    required List<String> targetCurrencies,
    bool forceRefresh = false,
  }) async {
    final rates = <String, ExchangeRate>{};

    try {
      final url = '$_baseUrl/$_apiKey/latest/$baseCurrency';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] == 'success') {
          final conversionRates =
              data['conversion_rates'] as Map<String, dynamic>;

          for (final targetCurrency in targetCurrencies) {
            if (conversionRates.containsKey(targetCurrency)) {
              final rate = ExchangeRate.create(
                fromCurrency: baseCurrency,
                toCurrency: targetCurrency,
                rate: conversionRates[targetCurrency].toDouble(),
                source: ExchangeRateSource.api,
              );

              rates[targetCurrency] = rate;

              // Cache the rate
              final cacheKey = '${baseCurrency}_$targetCurrency';
              _rateCache[cacheKey] = rate;
            }
          }

          _lastCacheUpdate = DateTime.now();
        }
      }
    } catch (e) {
      print('Error fetching multiple exchange rates: $e');
    }

    return rates;
  }

  /// Convert amount from one currency to another
  Future<CurrencyAmount?> convertAmount({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    bool forceRefresh = false,
  }) async {
    if (fromCurrency == toCurrency) {
      return CurrencyAmount.create(amount: amount, currencyCode: fromCurrency);
    }

    final exchangeRate = await getExchangeRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      forceRefresh: forceRefresh,
    );

    if (exchangeRate != null) {
      final convertedAmount = exchangeRate.convert(amount);

      return CurrencyAmount.create(
        amount: amount,
        currencyCode: fromCurrency,
        convertedAmount: convertedAmount,
        baseCurrencyCode: toCurrency,
        exchangeRate: exchangeRate.rate,
        exchangeRateDate: exchangeRate.date,
      );
    }

    return null;
  }

  /// Convert amount to base currency
  Future<CurrencyAmount?> convertToBaseCurrency({
    required double amount,
    required String fromCurrency,
    bool forceRefresh = false,
  }) async {
    final baseCurrency = await getBaseCurrency();
    return convertAmount(
      amount: amount,
      fromCurrency: fromCurrency,
      toCurrency: baseCurrency,
      forceRefresh: forceRefresh,
    );
  }

  /// Convert amount from base currency to target currency
  Future<CurrencyAmount?> convertFromBaseCurrency({
    required double amount,
    required String toCurrency,
    bool forceRefresh = false,
  }) async {
    final baseCurrency = await getBaseCurrency();
    return convertAmount(
      amount: amount,
      fromCurrency: baseCurrency,
      toCurrency: toCurrency,
      forceRefresh: forceRefresh,
    );
  }

  /// Get historical exchange rate for a specific date
  Future<ExchangeRate?> getHistoricalRate({
    required String fromCurrency,
    required String toCurrency,
    required DateTime date,
  }) async {
    try {
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final url = '$_baseUrl/$_apiKey/history/$fromCurrency/$formattedDate';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] == 'success') {
          final conversionRates =
              data['conversion_rates'] as Map<String, dynamic>;

          if (conversionRates.containsKey(toCurrency)) {
            return ExchangeRate.create(
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              rate: conversionRates[toCurrency].toDouble(),
              date: date,
              source: ExchangeRateSource.historical,
              isHistorical: true,
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching historical exchange rate: $e');
    }

    return null;
  }

  /// Get supported currencies from the API
  Future<List<Currency>> getSupportedCurrencies() async {
    try {
      final url = '$_baseUrl/$_apiKey/codes';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['result'] == 'success') {
          final supportedCodes = data['supported_codes'] as List<dynamic>;
          final currencies = <Currency>[];

          for (final codeData in supportedCodes) {
            final code = codeData[0] as String;
            final name = codeData[1] as String;

            // Check if we have this currency in our predefined list
            final predefinedCurrency = SupportedCurrencies.getCurrency(code);
            if (predefinedCurrency != null) {
              currencies.add(predefinedCurrency);
            } else {
              // Create a basic currency object for unsupported currencies
              currencies.add(
                Currency.create(
                  code: code,
                  name: name,
                  symbol: code,
                  flag: '🌍',
                ),
              );
            }
          }

          return currencies;
        }
      }
    } catch (e) {
      print('Error fetching supported currencies: $e');
    }

    // Return predefined currencies as fallback
    return SupportedCurrencies.currencies;
  }

  /// Get currency conversion rates for popular currencies
  Future<Map<String, double>> getPopularRates({
    String? baseCurrency, // Make baseCurrency optional
    bool forceRefresh = false,
  }) async {
    final actualBaseCurrency =
        baseCurrency ?? await getBaseCurrency(); // Use dynamic base currency
    final popularCurrencies = [
      'USD',
      'EUR',
      'GBP',
      'JPY',
      'CAD',
      'AUD',
      'CHF',
      'CNY',
      'NGN',
      'GHS',
    ];
    final rates = <String, double>{};

    final exchangeRates = await getMultipleRates(
      baseCurrency: actualBaseCurrency,
      targetCurrencies: popularCurrencies,
      forceRefresh: forceRefresh,
    );

    for (final entry in exchangeRates.entries) {
      rates[entry.key] = entry.value.rate;
    }

    print('Fetched popular rates: $rates');
    return rates;
  }

  /// Clear the exchange rate cache
  void clearCache() {
    _rateCache.clear();
    _lastCacheUpdate = null;
  }

  /// Check if the cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) <
        _cacheValidityDuration;
  }

  /// Get cache status information
  Map<String, dynamic> getCacheInfo() {
    return {
      'cacheSize': _rateCache.length,
      'lastUpdate': _lastCacheUpdate?.toIso8601String(),
      'isValid': _isCacheValid(),
      'validityDuration': _cacheValidityDuration.inMinutes,
    };
  }

  /// Preload popular exchange rates
  Future<void> preloadPopularRates() async {
    try {
      await getPopularRates(forceRefresh: true);
      print('Popular exchange rates preloaded successfully');
    } catch (e) {
      print('Error preloading popular rates: $e');
    }
  }

  /// Get exchange rate trend (requires multiple API calls)
  Future<List<ExchangeRate>> getExchangeRateTrend({
    required String fromCurrency,
    required String toCurrency,
    required int days,
  }) async {
    final rates = <ExchangeRate>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final rate = await getHistoricalRate(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        date: date,
      );

      if (rate != null) {
        rates.add(rate);
      }

      // Add delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return rates.reversed.toList(); // Return in chronological order
  }

  /// Format currency amount with proper symbol and decimal places
  String formatCurrencyAmount(double amount, String currencyCode) {
    final currency = SupportedCurrencies.getCurrency(currencyCode);
    if (currency != null) {
      return currency.formatAmount(amount);
    }
    return '${amount.toStringAsFixed(2)} $currencyCode';
  }

  /// Get base currency
  Future<String> getBaseCurrency() async {
    return _settingsBox.get(
      _baseCurrencyKey,
      defaultValue: _defaultBaseCurrency,
    );
  }

  /// Set base currency
  Future<void> setBaseCurrency(String currencyCode) async {
    await _settingsBox.put(_baseCurrencyKey, currencyCode);
  }

  /// Get base currency object
  Future<Currency> getBaseCurrencyObject() async {
    final code = await getBaseCurrency();
    return SupportedCurrencies.getCurrency(code) ??
        SupportedCurrencies.baseCurrencyObject;
  }
}
