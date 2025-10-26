import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/onboarding_controller.dart';
import '../../../models/currency.dart';
import '../../../services/currency_service.dart'; // Import CurrencyService
import '../../../models/currency.dart' as currency_model;

class CurrencyPreferencesScreen extends StatefulWidget {
  const CurrencyPreferencesScreen({super.key});

  @override
  State<CurrencyPreferencesScreen> createState() =>
      _CurrencyPreferencesScreenState();
}

class _CurrencyPreferencesScreenState extends State<CurrencyPreferencesScreen> {
  Currency? _selectedCurrency;
  List<Currency> _currencies = [];
  String _searchQuery = '';
  final CurrencyService _currencyService =
      CurrencyService(); // Initialize CurrencyService

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    final controller = context.read<OnboardingController>();
    if (controller.data.currencyCode != null) {
      _selectedCurrency = currency_model.SupportedCurrencies.getCurrency(
        controller.data.currencyCode!,
      );
    }
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _currencies = currency_model.SupportedCurrencies.currencies;
    });
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
    return Consumer<OnboardingController>(
      builder: (context, controller, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            // Title
            Text(
              'Select Your Currency',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Choose your preferred currency for entering income and expenses.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),

            const SizedBox(height: 32),

            // Search Bar
            _buildSearchBar(),

            const SizedBox(height: 16),

            // Currency List
            Expanded(child: _buildCurrencyList(controller)),

            const SizedBox(height: 16),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can always change your currency later in the Settings screen.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.amber[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ), // Adjusted margin
      decoration: BoxDecoration(
        color: Colors.grey[200], // Light background for search bar
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search currencies...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
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

  Widget _buildCurrencyList(OnboardingController controller) {
    final filteredCurrencies = _filteredCurrencies;

    if (filteredCurrencies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No currencies found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0), // Adjusted padding
      itemCount: filteredCurrencies.length,
      itemBuilder: (context, index) {
        final currency = filteredCurrencies[index];
        final isSelected = _selectedCurrency?.code == currency.code;

        return _buildCurrencyItem(currency, isSelected, controller);
      },
    );
  }

  Widget _buildCurrencyItem(
    Currency currency,
    bool isSelected,
    OnboardingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedCurrency = currency;
            });
            controller.updateCurrencyCode(currency.code);

            // Auto-advance after currency selection
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && controller.currentStep < 7) {
                controller.nextStep();
              }
            });
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
                    color: Colors.grey[100],
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
                                  ? Theme.of(context).primaryColor
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.symbol,
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.7)
                                  : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.name,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Selection Indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
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
