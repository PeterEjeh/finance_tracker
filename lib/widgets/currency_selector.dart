import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/currency_settings_service.dart';
import '../models/currency.dart';
import '../services/currency_service.dart';

class CurrencySelector extends StatefulWidget {
  final Currency? selectedCurrency;
  final Function(Currency) onCurrencySelected;
  final List<Currency>? availableCurrencies;
  final bool showPopularOnly;
  final String? title;
  final bool showExchangeRates;

  const CurrencySelector({
    super.key,
    this.selectedCurrency,
    required this.onCurrencySelected,
    this.availableCurrencies,
    this.showPopularOnly = false,
    this.title,
    this.showExchangeRates = false,
  });

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  final CurrencyService _currencyService = CurrencyService();
  List<Currency> _currencies = [];
  Map<String, double> _exchangeRates = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Currency> currencies;

      if (widget.availableCurrencies != null) {
        currencies = widget.availableCurrencies!;
      } else if (widget.showPopularOnly) {
        currencies = SupportedCurrencies.popularCurrencies;
      } else {
        currencies = SupportedCurrencies.currencies;
      }

      // Load exchange rates if requested
      Map<String, double> rates = {};
      if (widget.showExchangeRates) {
        rates = await _currencyService.getPopularRates();
      }

      setState(() {
        _currencies = currencies;
        _exchangeRates = rates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currencies = SupportedCurrencies.currencies;
        _isLoading = false;
      });
    }
  }

  List<Currency> get _filteredCurrencies {
    if (_searchQuery.isEmpty) {
      return _currencies;
    }

    return _currencies.where((currency) {
      return currency.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          currency.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E27),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6C5CE7),
                      ),
                    ),
                  )
                : _buildCurrencyList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title ?? 'Select Currency',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search currencies...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCurrencyList() {
    final filteredCurrencies = _filteredCurrencies;

    if (filteredCurrencies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No currencies found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredCurrencies.length,
      itemBuilder: (context, index) {
        final currency = filteredCurrencies[index];
        final isSelected = widget.selectedCurrency?.code == currency.code;
        final exchangeRate = _exchangeRates[currency.code];

        return _buildCurrencyItem(currency, isSelected, exchangeRate);
      },
    );
  }

  Widget _buildCurrencyItem(
    Currency currency,
    bool isSelected,
    double? exchangeRate,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6C5CE7).withOpacity(0.1)
            : const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onCurrencySelected(currency);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Flag and Symbol
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E27),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      currency.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Currency Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currency.code,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.symbol,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      if (widget.showExchangeRates && exchangeRate != null) ...[
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final settings =
                                Provider.of<CurrencySettingsService>(context);
                            final baseCurrencyCode = settings.baseCurrency.code;
                            return Text(
                              '1 $baseCurrencyCode = ${exchangeRate.toStringAsFixed(4)} ${currency.code}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // Selection Indicator
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF6C5CE7),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Compact currency selector for forms
class CompactCurrencySelector extends StatelessWidget {
  final Currency selectedCurrency;
  final Function(Currency) onCurrencySelected;
  final bool showExchangeRates;

  const CompactCurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
    this.showExchangeRates = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => CurrencySelector(
            selectedCurrency: selectedCurrency,
            onCurrencySelected: onCurrencySelected,
            showExchangeRates: showExchangeRates,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedCurrency.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              selectedCurrency.code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Currency display widget
class CurrencyDisplay extends StatelessWidget {
  final Currency currency;
  final double? amount;
  final bool showCode;
  final bool showFlag;
  final TextStyle? textStyle;

  const CurrencyDisplay({
    super.key,
    required this.currency,
    this.amount,
    this.showCode = true,
    this.showFlag = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle =
        textStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showFlag) ...[
          Text(
            currency.flag,
            style: TextStyle(fontSize: defaultStyle.fontSize),
          ),
          const SizedBox(width: 8),
        ],
        if (amount != null) ...[
          Text(currency.formatAmount(amount!), style: defaultStyle),
          if (showCode) ...[
            const SizedBox(width: 4),
            Text(
              currency.code,
              style: defaultStyle.copyWith(
                color: defaultStyle.color?.withAlpha(179),
                fontSize: (defaultStyle.fontSize ?? 16) * 0.8,
              ),
            ),
          ],
        ] else if (showCode) ...[
          Text('${currency.symbol} ${currency.code}', style: defaultStyle),
        ] else ...[
          Text(currency.symbol, style: defaultStyle),
        ],
      ],
    );
  }
}

// Exchange rate display widget
class ExchangeRateDisplay extends StatefulWidget {
  final String fromCurrency;
  final String toCurrency;
  final double? amount;
  final bool showTrend;

  const ExchangeRateDisplay({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    this.amount,
    this.showTrend = false,
  });

  @override
  State<ExchangeRateDisplay> createState() => _ExchangeRateDisplayState();
}

class _ExchangeRateDisplayState extends State<ExchangeRateDisplay> {
  final CurrencyService _currencyService = CurrencyService();
  ExchangeRate? _exchangeRate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExchangeRate();
  }

  Future<void> _loadExchangeRate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rate = await _currencyService.getExchangeRate(
        fromCurrency: widget.fromCurrency,
        toCurrency: widget.toCurrency,
      );

      setState(() {
        _exchangeRate = rate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
        ),
      );
    }

    if (_exchangeRate == null) {
      return Text(
        'Rate unavailable',
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1 ${widget.fromCurrency} = ${_exchangeRate!.rate.toStringAsFixed(4)} ${widget.toCurrency}',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        if (widget.amount != null) ...[
          const SizedBox(height: 4),
          Text(
            '${widget.amount} ${widget.fromCurrency} = ${_exchangeRate!.convert(widget.amount!).toStringAsFixed(2)} ${widget.toCurrency}',
            style: const TextStyle(
              color: Color(0xFF6C5CE7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
