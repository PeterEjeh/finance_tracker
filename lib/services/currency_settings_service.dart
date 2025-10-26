import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/currency.dart';
import 'currency_service.dart';
import 'settings_service.dart';

/// Enhanced service for managing currency preferences and settings across the app
class CurrencySettingsService extends ChangeNotifier {
  static final CurrencySettingsService _instance =
      CurrencySettingsService._internal();
  factory CurrencySettingsService() => _instance;
  CurrencySettingsService._internal();

  final CurrencyService _currencyService = CurrencyService();
  final SettingsService _settingsService = SettingsService();

  // Settings keys
  static const String _baseCurrencyKey = 'base_currency';
  static const String _preferredCurrenciesKey = 'preferred_currencies';
  static const String _autoUpdateRatesKey = 'auto_update_rates';
  static const String _showExchangeRatesKey = 'show_exchange_rates';
  static const String _currencyDecimalPlacesKey = 'currency_decimal_places';
  static const String _useSymbolInsteadOfCodeKey = 'use_symbol_instead_of_code';

  // Current state
  Currency _baseCurrency = SupportedCurrencies.baseCurrencyObject;
  List<Currency> _preferredCurrencies = SupportedCurrencies.popularCurrencies;
  bool _autoUpdateRates = true;
  bool _showExchangeRates = true;
  int _currencyDecimalPlaces = 2;
  bool _useSymbolInsteadOfCode = true;

  bool _initialized = false;

  // Getters
  Currency get baseCurrency => _baseCurrency;
  List<Currency> get preferredCurrencies => _preferredCurrencies;
  bool get autoUpdateRates => _autoUpdateRates;
  bool get showExchangeRates => _showExchangeRates;
  int get currencyDecimalPlaces => _currencyDecimalPlaces;
  bool get useSymbolInsteadOfCode => _useSymbolInsteadOfCode;
  bool get initialized => _initialized;

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;

    try {
      await _settingsService.init();
      await _currencyService.init();
      await _loadSettings();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing CurrencySettingsService: $e');
      _initialized =
          true; // Set to true even on error to prevent infinite retry
    }
  }

  /// Load all currency settings
  Future<void> _loadSettings() async {
    try {
      // Load base currency
      final baseCurrencyCode = await _settingsService.getCurrency();
      final baseCurrency = SupportedCurrencies.getCurrency(baseCurrencyCode);
      if (baseCurrency != null) {
        _baseCurrency = baseCurrency;
      }

      // Sync with currency service
      await _currencyService.setBaseCurrency(_baseCurrency.code);

      // Load preferred currencies
      await _loadPreferredCurrencies();

      // Load other settings
      final prefs = await SharedPreferences.getInstance();
      _autoUpdateRates = prefs.getBool(_autoUpdateRatesKey) ?? true;
      _showExchangeRates = prefs.getBool(_showExchangeRatesKey) ?? true;
      _currencyDecimalPlaces = prefs.getInt(_currencyDecimalPlacesKey) ?? 2;
      _useSymbolInsteadOfCode =
          prefs.getBool(_useSymbolInsteadOfCodeKey) ?? true;
    } catch (e) {
      debugPrint('Error loading currency settings: $e');
    }
  }

  /// Load preferred currencies from storage
  Future<void> _loadPreferredCurrencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferredCodes = prefs.getStringList(_preferredCurrenciesKey);

      if (preferredCodes != null && preferredCodes.isNotEmpty) {
        final currencies = <Currency>[];
        for (final code in preferredCodes) {
          final currency = SupportedCurrencies.getCurrency(code);
          if (currency != null) {
            currencies.add(currency);
          }
        }

        if (currencies.isNotEmpty) {
          _preferredCurrencies = currencies;
        }
      }
    } catch (e) {
      debugPrint('Error loading preferred currencies: $e');
    }
  }

  /// Set base currency and update across the app
  Future<void> setBaseCurrency(Currency currency) async {
    try {
      _baseCurrency = currency;

      // Update in settings service
      await _settingsService.setCurrency(currency.code);

      // Update in currency service
      await _currencyService.setBaseCurrency(currency.code);

      // Clear exchange rate cache to force refresh
      _currencyService.clearCache();

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting base currency: $e');
      rethrow;
    }
  }

  /// Update preferred currencies
  Future<void> setPreferredCurrencies(List<Currency> currencies) async {
    try {
      _preferredCurrencies = currencies;

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      final codes = currencies.map((c) => c.code).toList();
      await prefs.setStringList(_preferredCurrenciesKey, codes);

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting preferred currencies: $e');
      rethrow;
    }
  }

  /// Add currency to preferred list
  Future<void> addPreferredCurrency(Currency currency) async {
    if (!_preferredCurrencies.any((c) => c.code == currency.code)) {
      final updated = [..._preferredCurrencies, currency];
      await setPreferredCurrencies(updated);
    }
  }

  /// Remove currency from preferred list
  Future<void> removePreferredCurrency(Currency currency) async {
    final updated = _preferredCurrencies
        .where((c) => c.code != currency.code)
        .toList();
    await setPreferredCurrencies(updated);
  }

  /// Set auto-update exchange rates preference
  Future<void> setAutoUpdateRates(bool enabled) async {
    try {
      _autoUpdateRates = enabled;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoUpdateRatesKey, enabled);

      if (enabled) {
        // Preload rates if auto-update is enabled
        await _currencyService.preloadPopularRates();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting auto-update rates: $e');
      rethrow;
    }
  }

  /// Set show exchange rates preference
  Future<void> setShowExchangeRates(bool enabled) async {
    try {
      _showExchangeRates = enabled;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showExchangeRatesKey, enabled);

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting show exchange rates: $e');
      rethrow;
    }
  }

  /// Set decimal places for currency formatting
  Future<void> setCurrencyDecimalPlaces(int places) async {
    try {
      _currencyDecimalPlaces = places.clamp(0, 4);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currencyDecimalPlacesKey, _currencyDecimalPlaces);

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting currency decimal places: $e');
      rethrow;
    }
  }

  /// Set whether to use symbol instead of code in displays
  Future<void> setUseSymbolInsteadOfCode(bool useSymbol) async {
    try {
      _useSymbolInsteadOfCode = useSymbol;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useSymbolInsteadOfCodeKey, useSymbol);

      notifyListeners();
    } catch (e) {
      debugPrint('Error setting use symbol preference: $e');
      rethrow;
    }
  }

  /// Get formatted amount using current settings
  String formatAmount(
    double amount, {
    Currency? currency,
    bool showCode = false,
  }) {
    final targetCurrency = currency ?? _baseCurrency;

    if (_useSymbolInsteadOfCode && !showCode) {
      return targetCurrency.formatAmount(amount);
    } else {
      return targetCurrency.formatAmountWithCode(amount);
    }
  }

  /// Convert amount to base currency and format
  Future<String> formatAmountInBaseCurrency(
    double amount,
    String fromCurrencyCode,
  ) async {
    if (fromCurrencyCode == _baseCurrency.code) {
      return formatAmount(amount);
    }

    try {
      final convertedAmount = await _currencyService.convertToBaseCurrency(
        amount: amount,
        fromCurrency: fromCurrencyCode,
      );

      if (convertedAmount != null) {
        return formatAmount(convertedAmount.displayAmount);
      }
    } catch (e) {
      debugPrint('Error converting amount to base currency: $e');
    }

    // Fallback to original amount with from currency
    final fromCurrency = SupportedCurrencies.getCurrency(fromCurrencyCode);
    if (fromCurrency != null) {
      return formatAmount(amount, currency: fromCurrency);
    }

    return formatAmount(amount);
  }

  /// Get currency options for selectors
  List<Currency> getCurrencyOptions({bool preferredFirst = true}) {
    if (!preferredFirst) {
      return SupportedCurrencies.currencies;
    }

    final preferred = _preferredCurrencies;
    final all = SupportedCurrencies.currencies;
    final others = all
        .where((c) => !preferred.any((p) => p.code == c.code))
        .toList();

    return [...preferred, ...others];
  }

  /// Refresh exchange rates if auto-update is enabled
  Future<void> refreshRatesIfEnabled() async {
    if (_autoUpdateRates) {
      try {
        await _currencyService.preloadPopularRates();
      } catch (e) {
        debugPrint('Error refreshing exchange rates: $e');
      }
    }
  }

  /// Get all settings as a map for backup/restore
  Map<String, dynamic> getAllSettings() {
    return {
      'baseCurrency': _baseCurrency.code,
      'preferredCurrencies': _preferredCurrencies.map((c) => c.code).toList(),
      'autoUpdateRates': _autoUpdateRates,
      'showExchangeRates': _showExchangeRates,
      'currencyDecimalPlaces': _currencyDecimalPlaces,
      'useSymbolInsteadOfCode': _useSymbolInsteadOfCode,
    };
  }

  /// Restore settings from map
  Future<void> restoreSettings(Map<String, dynamic> settings) async {
    try {
      if (settings['baseCurrency'] != null) {
        final currency = SupportedCurrencies.getCurrency(
          settings['baseCurrency'],
        );
        if (currency != null) {
          await setBaseCurrency(currency);
        }
      }

      if (settings['preferredCurrencies'] != null) {
        final codes = List<String>.from(settings['preferredCurrencies']);
        final currencies = codes
            .map((code) => SupportedCurrencies.getCurrency(code))
            .where((c) => c != null)
            .cast<Currency>()
            .toList();
        if (currencies.isNotEmpty) {
          await setPreferredCurrencies(currencies);
        }
      }

      if (settings['autoUpdateRates'] != null) {
        await setAutoUpdateRates(settings['autoUpdateRates']);
      }

      if (settings['showExchangeRates'] != null) {
        await setShowExchangeRates(settings['showExchangeRates']);
      }

      if (settings['currencyDecimalPlaces'] != null) {
        await setCurrencyDecimalPlaces(settings['currencyDecimalPlaces']);
      }

      if (settings['useSymbolInsteadOfCode'] != null) {
        await setUseSymbolInsteadOfCode(settings['useSymbolInsteadOfCode']);
      }
    } catch (e) {
      debugPrint('Error restoring currency settings: $e');
      rethrow;
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      await setBaseCurrency(SupportedCurrencies.baseCurrencyObject);
      await setPreferredCurrencies(SupportedCurrencies.popularCurrencies);
      await setAutoUpdateRates(true);
      await setShowExchangeRates(true);
      await setCurrencyDecimalPlaces(2);
      await setUseSymbolInsteadOfCode(true);
    } catch (e) {
      debugPrint('Error resetting currency settings: $e');
      rethrow;
    }
  }
}
