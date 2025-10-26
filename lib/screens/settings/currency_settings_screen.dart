import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/currency.dart';
import '../../services/currency_service.dart';
import '../../services/currency_settings_service.dart';
import '../../widgets/currency_selector.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  final CurrencyService _currencyService = CurrencyService();

  Map<String, double> _exchangeRates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load settings via provider in didChangeDependencies to ensure context is available
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = Provider.of<CurrencySettingsService>(
        context,
        listen: false,
      );
      await settings.init();

      // Get exchange rates for current base currency using local service
      final rates = await _currencyService.getPopularRates(
        baseCurrency: settings.baseCurrency.code,
      );

      setState(() {
        _exchangeRates = rates;
        _isLoading = false;
      });
      print('Loaded exchange rates: $_exchangeRates');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading currency settings: $e')),
        );
      }
    }
  }

  Future<void> _refreshExchangeRates() async {
    final theme = Theme.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ),
      );

      final settings = Provider.of<CurrencySettingsService>(
        context,
        listen: false,
      );
      final rates = await _currencyService.getPopularRates(
        baseCurrency: settings.baseCurrency.code,
        forceRefresh: true,
      );

      Navigator.pop(context); // Close loading dialog

      setState(() {
        _exchangeRates = rates;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Exchange rates updated successfully'),
          backgroundColor: theme.colorScheme.secondary,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating exchange rates: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = Provider.of<CurrencySettingsService>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.textTheme.titleLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Currency Settings',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textTheme.titleLarge?.color),
            onPressed: _refreshExchangeRates,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBaseCurrencySection(theme, isDark, settings),
                const SizedBox(height: 20),
                _buildExchangeRatesSection(theme, isDark),
                const SizedBox(height: 20),
                _buildPreferredCurrenciesSection(theme, isDark, settings),
                const SizedBox(height: 20),
                _buildSettingsSection(theme, isDark, settings),
                const SizedBox(height: 20),
                _buildCacheInfoSection(theme, isDark),
              ],
            ),
    );
  }

  Widget _buildBaseCurrencySection(
    ThemeData theme,
    bool isDark,
    CurrencySettingsService settings,
  ) {
    final cardColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = textColor.withOpacity(0.6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Base Currency',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All amounts will be converted to this currency for calculations and reports.',
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  settings.baseCurrency.flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            title: Text(
              settings.baseCurrency.name,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${settings.baseCurrency.code} (${settings.baseCurrency.symbol})',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            trailing: Icon(Icons.edit, color: theme.primaryColor),
            onTap: () async {
              final selected = await showModalBottomSheet<Currency>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => CurrencySelector(
                  selectedCurrency: settings.baseCurrency,
                  onCurrencySelected: (currency) {
                    _updateBaseCurrency(currency);
                  },
                ),
              );
              if (selected != null) {
                _updateBaseCurrency(selected);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRatesSection(ThemeData theme, bool isDark) {
    final cardColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = textColor.withOpacity(0.6);
    final iconColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exchange Rates',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Updated ${_getLastUpdateText()}',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_exchangeRates.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.currency_exchange,
                    size: 48,
                    color: iconColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No exchange rates available',
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _refreshExchangeRates,
                    child: Text(
                      'Refresh Rates',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._exchangeRates.entries.map(
              (entry) =>
                  _buildExchangeRateItem(entry.key, entry.value, theme, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateItem(
    String currencyCode,
    double rate,
    ThemeData theme,
    bool isDark,
  ) {
    final currency = SupportedCurrencies.getCurrency(currencyCode);
    if (currency == null) return const SizedBox();

    final innerCardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = textColor.withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: innerCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(currency.flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency.code,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  currency.name,
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '1 ${Provider.of<CurrencySettingsService>(context).baseCurrency.code} = ${rate.toStringAsFixed(4)}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currency.symbol,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferredCurrenciesSection(
    ThemeData theme,
    bool isDark,
    CurrencySettingsService settings,
  ) {
    final cardColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = textColor.withOpacity(0.6);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred Currencies',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'These currencies will appear first in currency selectors.',
            style: TextStyle(color: subtitleColor, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: settings.preferredCurrencies
                .map((currency) => _buildCurrencyChip(currency, theme, isDark))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(Currency currency, ThemeData theme, bool isDark) {
    final innerCardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: innerCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currency.flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            currency.code,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    ThemeData theme,
    bool isDark,
    CurrencySettingsService settings,
  ) {
    final cardColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currency Settings',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Auto-update Exchange Rates',
            'Automatically fetch latest rates when opening the app',
            settings.autoUpdateRates,
            (value) async {
              await settings.setAutoUpdateRates(value);
              setState(() {});
            },
            theme,
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Show Exchange Rates in Transactions',
            'Display converted amounts in transaction lists',
            settings.showExchangeRates,
            (value) async {
              await settings.setShowExchangeRates(value);
              setState(() {});
            },
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
    bool isDark,
  ) {
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = textColor.withOpacity(0.6);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildCacheInfoSection(ThemeData theme, bool isDark) {
    final cardColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cacheInfo = _currencyService.getCacheInfo();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cache Information',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  _currencyService.clearCache();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully'),
                      backgroundColor: Color(0xFF00D4AA),
                    ),
                  );
                },
                child: Text(
                  'Clear Cache',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Cached Rates',
            '${cacheInfo['cacheSize']}',
            theme,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Cache Status',
            cacheInfo['isValid'] ? 'Valid' : 'Expired',
            theme,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Validity Period',
            '${cacheInfo['validityDuration']} minutes',
            theme,
            isDark,
          ),
          if (cacheInfo['lastUpdate'] != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Last Updated',
              _formatDateTime(DateTime.parse(cacheInfo['lastUpdate'])),
              theme,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark,
  ) {
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = textColor.withOpacity(0.6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subtitleColor, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getLastUpdateText() {
    final cacheInfo = _currencyService.getCacheInfo();
    if (cacheInfo['lastUpdate'] != null) {
      final lastUpdate = DateTime.parse(cacheInfo['lastUpdate']);
      final now = DateTime.now();
      final difference = now.difference(lastUpdate);

      if (difference.inMinutes < 1) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    }
    return 'never';
  }

  Future<void> _updateBaseCurrency(Currency newCurrency) async {
    final settings = Provider.of<CurrencySettingsService>(
      context,
      listen: false,
    );
    await settings.setBaseCurrency(newCurrency);

    // Refresh local rates and UI
    final rates = await _currencyService.getPopularRates(
      baseCurrency: newCurrency.code,
      forceRefresh: true,
    );
    setState(() {
      _exchangeRates = rates;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
