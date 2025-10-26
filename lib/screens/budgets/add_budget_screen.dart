import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../widgets/thousands_separator_input_formatter.dart';
import '../../widgets/category_picker_field.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/currency.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../services/currency_settings_service.dart';
import '../../services/smart_categorization_service.dart'; // Import SmartCategorizationService
import '../../widgets/currency_selector.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();
  final CurrencyService _currencyService = CurrencyService();

  List<Category> _categories = [];
  String? _selectedCategoryId;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  BudgetType _selectedType = BudgetType.progressive;
  bool _alertEnabled = true;
  double _alertThreshold = 0.8;
  bool _autoRenew = true;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _isLoading = false;

  // Currency fields
  late Currency _selectedCurrency;
  double? _originalAmount;
  Currency? _originalCurrency;
  double? _exchangeRate;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<CurrencySettingsService>(
      context,
      listen: false,
    );
    _selectedCurrency = settings.baseCurrency;
    _nameController.addListener(
      _onNameChanged,
    ); // Add listener for name changes
    _loadCategories();
    if (widget.budget != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final budget = widget.budget!;
    _nameController.text = budget.name;
    _amountController.text = budget.amount.toString();
    _descriptionController.text = budget.description ?? '';
    _selectedCategoryId = budget.categoryId;
    _selectedPeriod = budget.period;
    _selectedType = budget.type;
    _alertEnabled = budget.alertEnabled;
    _alertThreshold = budget.alertThreshold;
    _selectedCurrency = budget.currency;
    if (budget.period == BudgetPeriod.custom) {
      _customStartDate = budget.startDate;
      _customEndDate = budget.endDate;
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    try {
      final userId = _authService.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      await _databaseService.initializeDefaultCategories(userId);

      if (!mounted) return;

      final categoryType = _selectedType == BudgetType.goal
          ? CategoryType.income
          : CategoryType.expense;

      final categories = _databaseService.getCategoriesByType(
        type: categoryType,
        userId: userId,
      );

      if (!mounted) return;

      setState(() {
        _categories = categories;

        if (_categories.isNotEmpty && _selectedCategoryId == null) {
          if (widget.budget != null) {
            _selectedCategoryId = _categories
                .firstWhere(
                  (c) => c.id == widget.budget!.categoryId,
                  orElse: () => _categories.first,
                )
                .id;
          } else {
            _selectedCategoryId = _categories.first.id;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  void _onTypeChanged(BudgetType type) {
    if (!mounted) return;

    setState(() {
      _selectedType = type;
      _selectedCategoryId = null;
    });
    _loadCategories();
  }

  Future<void> _saveBudget() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }

    if (_selectedPeriod == BudgetPeriod.custom &&
        (_customStartDate == null || _customEndDate == null)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select custom date range')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final amountText = _amountController.text.replaceAll(',', '');
      if (amountText.isEmpty) {
        throw Exception('Amount cannot be empty');
      }

      final amount = double.parse(amountText);
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      Budget budget = Budget.create(
        name: _nameController.text.trim(),
        amount: amount,
        categoryId: _selectedCategoryId!,
        period: _selectedPeriod,
        type: _selectedType,
        userId: userId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        alertEnabled: _alertEnabled,
        alertThreshold: _alertThreshold,
        startDate: _selectedPeriod == BudgetPeriod.custom
            ? _customStartDate
            : null,
        currencyCode: _selectedCurrency.code,
      );

      // For custom periods, update the end date
      if (_selectedPeriod == BudgetPeriod.custom && _customEndDate != null) {
        budget = budget.copyWith(endDate: _customEndDate);
      }

      if (widget.budget != null) {
        // Update existing budget
        final updatedBudget = budget.copyWith();
        updatedBudget.id = widget.budget!.id;
        await _databaseService.updateBudget(updatedBudget);
      } else {
        // Create new budget
        await _databaseService.addBudget(budget);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving budget: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectCustomDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_customStartDate ?? DateTime.now())
          : (_customEndDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C2C2C),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C2C2C),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = picked;
          // Ensure end date is after start date
          if (_customEndDate != null && _customEndDate!.isBefore(picked)) {
            _customEndDate = picked.add(const Duration(days: 30));
          }
        } else {
          _customEndDate = picked;
          // Ensure start date is before end date
          if (_customStartDate != null && _customStartDate!.isAfter(picked)) {
            _customStartDate = picked.subtract(const Duration(days: 30));
          }
        }
      });
    }
  }

  Future<void> _onCurrencyChanged(Currency currency) async {
    if (!mounted || currency.code == _selectedCurrency.code) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amountText = _amountController.text.replaceAll(',', '');
      final amount = double.tryParse(amountText);

      if (amount != null && amount > 0) {
        // Convert amount to new currency
        final convertedAmount = await _currencyService.convertAmount(
          amount: amount,
          fromCurrency: _selectedCurrency.code,
          toCurrency: currency.code,
        );

        if (convertedAmount != null && mounted) {
          // Store original amount and currency
          _originalAmount = amount;
          _originalCurrency = _selectedCurrency;
          _exchangeRate = convertedAmount.amount / amount;

          // Update display
          _amountController.text = NumberFormat.decimalPattern().format(
            convertedAmount.amount,
          );
          _selectedCurrency = currency;
        } else if (mounted) {
          _selectedCurrency = currency;
        }
      } else if (mounted) {
        _selectedCurrency = currency;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error converting currency: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.budget != null ? 'Edit Budget' : 'Add Budget',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveBudget,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF2C2C2C),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeToggle(),

              const SizedBox(height: 24),

              // Budget Name Field
              _buildNameField(),

              const SizedBox(height: 24),

              // Amount Field
              _buildAmountField(),

              const SizedBox(height: 24),

              // Category Selection
              _buildCategorySelection(),

              const SizedBox(height: 24),

              // Currency Selection
              _buildCurrencySelection(),

              const SizedBox(height: 24),

              // Period Selection
              _buildPeriodSelection(),

              const SizedBox(height: 24),

              // Custom Date Range (if custom period selected)
              if (_selectedPeriod == BudgetPeriod.custom) ...[
                _buildCustomDateRange(),
                const SizedBox(height: 24),
              ],

              // Description Field
              _buildDescriptionField(),

              const SizedBox(height: 24),

              // Alert Settings
              _buildAlertSettings(),

              const SizedBox(height: 24),

              // Auto-renew Setting
              _buildAutoRenewSetting(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1F3A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _nameController,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2C2C2C),
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Monthly Food Budget',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a budget name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1F3A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Compact toggle buttons with shorter labels
              Container(
                height: 48,
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(12),
                  selectedBorderColor: Theme.of(context).primaryColor,
                  selectedColor: Colors.white,
                  fillColor: Theme.of(context).primaryColor,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF2C2C2C).withOpacity(0.7),
                  constraints: BoxConstraints(minHeight: 48, minWidth: 80),
                  onPressed: (int index) {
                    _onTypeChanged(BudgetType.values[index]);
                  },
                  isSelected: BudgetType.values
                      .map((type) => _selectedType == type)
                      .toList(),
                  children: [
                    _buildCompactTypeButton(
                      'Progressive',
                      'For daily expenses like food, transport',
                    ),
                    _buildCompactTypeButton(
                      'Fixed',
                      'For fixed costs like rent, bills',
                    ),
                    _buildCompactTypeButton(
                      'Recurring',
                      'For subscriptions, memberships',
                    ),
                    _buildCompactTypeButton(
                      'Goal',
                      'For savings goals, targets',
                    ),
                  ],
                ),
              ),
              // Show current selection with full description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(_selectedType),
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedType.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            _getTypeDescription(_selectedType),
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.6)
                                  : const Color(0xFF2C2C2C).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Show auto-suggestion indicator for new budgets
        if (widget.budget == null && _nameController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Type auto-selected based on budget name',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Allow user to understand this is optional
                  },
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactTypeButton(String label, String description) {
    return Container(
      constraints: BoxConstraints(minWidth: 70),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(BudgetType type) {
    switch (type) {
      case BudgetType.progressive:
        return Icons.trending_up;
      case BudgetType.fixed:
        return Icons.lock;
      case BudgetType.recurring:
        return Icons.repeat;
      case BudgetType.goal:
        return Icons.flag;
    }
  }

  String _getTypeDescription(BudgetType type) {
    switch (type) {
      case BudgetType.progressive:
        return 'Flexible spending that adjusts over time';
      case BudgetType.fixed:
        return 'Fixed amounts for bills and regular payments';
      case BudgetType.recurring:
        return 'Ongoing subscriptions and memberships';
      case BudgetType.goal:
        return 'Target-based savings and one-time goals';
    }
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1F3A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
              ThousandsSeparatorInputFormatter(
                maxDecimalDigits: _selectedCurrency.decimalPlaces,
              ),
            ],
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '${_selectedCurrency.symbol} ',
              prefixStyle: const TextStyle(
                color: Color(0xFF2C2C2C),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2C2C2C),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value.replaceAll(',', '')) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value.replaceAll(',', '')) <= 0) {
                return 'Amount must be greater than 0';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        CategoryPickerField(
          categories: _categories,
          selectedCategoryId: _selectedCategoryId,
          categoryType: CategoryType.expense,
          onSelected: (cat) {
            setState(() {
              // If this is a newly created category not yet in the local list, add it
              if (!_categories.any((c) => c.id == cat.id)) {
                _categories.insert(0, cat);
              }
              _selectedCategoryId = cat.id;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCurrencySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1F3A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CompactCurrencySelector(
            selectedCurrency: _selectedCurrency,
            onCurrencySelected: _onCurrencyChanged,
            showExchangeRates: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Period',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BudgetPeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  if (period != BudgetPeriod.custom) {
                    _customStartDate = null;
                    _customEndDate = null;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2C2C2C)
                      : Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1F3A)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2C2C2C)
                        : Colors.black.withOpacity(0.1),
                  ),
                  boxShadow: isSelected
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  period.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF2C2C2C).withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomDateRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectCustomDate(true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A1F3A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.6)
                              : const Color(0xFF2C2C2C).withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _customStartDate != null
                            ? '${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF2C2C2C),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectCustomDate(false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A1F3A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.6)
                              : const Color(0xFF2C2C2C).withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _customEndDate != null
                            ? '${_customEndDate!.day}/${_customEndDate!.month}/${_customEndDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF2C2C2C),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1F3A)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2C2C2C),
            ),
            decoration: InputDecoration(
              hintText: 'Add notes about this budget...',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1F3A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Alerts',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF2C2C2C),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: _alertEnabled,
                onChanged: (value) {
                  setState(() {
                    _alertEnabled = value;
                  });
                },
                activeColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
              ),
            ],
          ),
          if (_alertEnabled) ...[
            const SizedBox(height: 16),
            Text(
              'Alert when ${(_alertThreshold * 100).toInt()}% of budget is used',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF2C2C2C).withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor:
                    Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
                inactiveTrackColor:
                    Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                thumbColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
                overlayColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFF2C2C2C).withOpacity(0.2),
              ),
              child: Slider(
                value: _alertThreshold,
                min: 0.5,
                max: 1.0,
                divisions: 5,
                onChanged: (value) {
                  setState(() {
                    _alertThreshold = value;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoRenewSetting() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1F3A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-renew Budget',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically create a new budget period when this one ends',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.6)
                        : const Color(0xFF2C2C2C).withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoRenew,
            onChanged: (value) {
              setState(() {
                _autoRenew = value;
              });
            },
            activeColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged); // Remove listener
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_nameController.text.isNotEmpty && widget.budget == null) {
      try {
        final inferredType = SmartCategorizationService.inferBudgetType(
          _nameController.text,
        );
        if (inferredType != _selectedType && mounted) {
          setState(() {
            _selectedType = inferredType;
          });
          _loadCategories(); // Reload categories based on new type
        }
      } catch (e) {
        // Silently handle any errors in type inference to prevent render flow errors
        debugPrint('Error inferring budget type: $e');
      }
    }
  }
}
