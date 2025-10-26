import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/budget.dart';
import '../../models/currency.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../services/currency_settings_service.dart';
import '../../services/smart_categorization_service.dart';
import '../../widgets/category_picker_field.dart';
import '../../widgets/currency_selector.dart';
import '../../widgets/thousands_separator_input_formatter.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType? initialType;
  final Transaction? editTransaction;

  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.editTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();
  final CurrencyService _currencyService = CurrencyService();

  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<Category> _categories = [];
  List<Budget> _availableBudgets = [];
  Budget? _selectedBudget;
  bool _isLoading = false;
  bool _isRecurring = false;
  RecurringType? _recurringType;
  String? _selectedUtility;

  // Smart categorization
  List<CategorySuggestion> _categorySuggestions = [];
  bool _showSuggestions = false;
  CategorySuggestion? _autoSuggestedCategory;

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
    _selectedType = widget.initialType ?? TransactionType.expense;
    _loadCategories();

    // Add listeners for smart categorization
    _titleController.addListener(_onTitleChanged);
    _descriptionController.addListener(_onTitleChanged);

    if (widget.editTransaction != null) {
      _populateEditData();
    }
  }

  void _populateEditData() {
    final transaction = widget.editTransaction!;
    _titleController.text = transaction.title;
    _amountController.text = NumberFormat.decimalPattern().format(
      transaction.amount,
    );
    _descriptionController.text = transaction.description ?? '';
    _selectedType = transaction.type;
    _selectedDate = transaction.date;
    _isRecurring = transaction.isRecurring;
    _recurringType = transaction.recurringType;

    // Currency data
    _selectedCurrency = transaction.currency;
    _originalAmount = transaction.originalAmount;
    _originalCurrency = transaction.originalCurrency;
    _exchangeRate = transaction.exchangeRate;
  }

  Future<void> _loadCategories() async {
    final userId = _authService.currentUser?.uid ?? '';
    await _databaseService.initializeDefaultCategories(userId);

    setState(() {
      _categories = _databaseService.getCategoriesByType(
        type: _selectedType == TransactionType.income
            ? CategoryType.income
            : CategoryType.expense,
        userId: userId,
      );

      // Auto-select savings category for saving type
      if (_selectedType == TransactionType.saving && _categories.isNotEmpty) {
        final savingsCategory = _categories.firstWhere(
          (c) => c.id == 'expense_savings',
          orElse: () => _categories.first,
        );
        _selectedCategory = savingsCategory;
      }

      if (_categories.isNotEmpty && _selectedCategory == null) {
        if (widget.editTransaction != null) {
          _selectedCategory = _categories.firstWhere(
            (c) => c.id == widget.editTransaction!.categoryId,
            orElse: () => _categories.first,
          );
        } else {
          _selectedCategory = _categories.first;
        }
      }
    });
  }

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _selectedType = type;
      _selectedCategory = null;
      _availableBudgets = [];
      _selectedBudget = null;
      // Clear suggestions when type changes
      _categorySuggestions = [];
      _showSuggestions = false;
      _autoSuggestedCategory = null;
    });
    _loadCategories();
  }

  Future<void> _loadBudgetsForSelectedCategory(String userId) async {
    if (_selectedCategory == null) {
      setState(() {
        _availableBudgets = [];
        _selectedBudget = null;
      });
      return;
    }

    final budgets = _databaseService.getBudgetsByCategory(
      categoryId: _selectedCategory!.id,
      userId: userId,
    );
    // Prefer active budgets in current period
    final filtered = budgets
        .where((b) => b.isActive && b.isCurrentPeriod)
        .toList();

    setState(() {
      _availableBudgets = filtered;
      // If editing and transaction has a budget, select it; otherwise keep current selection or choose first
      if (widget.editTransaction != null) {
        final editBudgetId = (widget.editTransaction as Transaction).budgetId;
        Budget? matched;
        if (editBudgetId != null) {
          for (final b in _availableBudgets) {
            if (b.id == editBudgetId) {
              matched = b;
              break;
            }
          }
        }
        _selectedBudget =
            matched ??
            (_availableBudgets.isNotEmpty ? _availableBudgets.first : null);
      } else {
        _selectedBudget =
            _selectedBudget ??
            (_availableBudgets.isNotEmpty ? _availableBudgets.first : null);
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onTitleChanged() {
    final title = _titleController.text.trim();
    if (title.length >= 3) {
      // Only suggest after 3+ characters
      _getCategorySuggestions();
    } else {
      setState(() {
        _categorySuggestions = [];
        _showSuggestions = false;
        _autoSuggestedCategory = null;
      });
    }
  }

  void _getCategorySuggestions() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || _categories.isEmpty) {
      setState(() {
        _categorySuggestions = [];
        _showSuggestions = false;
        _autoSuggestedCategory = null;
      });
      return;
    }

    final suggestions = SmartCategorizationService.getCategorySuggestions(
      title: title,
      description: description.isNotEmpty ? description : null,
      availableCategories: _categories,
      transactionType: _selectedType,
    );

    setState(() {
      _categorySuggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;

      // Auto-suggest if confidence is high enough
      if (suggestions.isNotEmpty &&
          SmartCategorizationService.shouldAutoAssign(suggestions.first)) {
        _autoSuggestedCategory = suggestions.first;
      } else {
        _autoSuggestedCategory = null;
      }
    });
  }

  Future<void> _onCurrencyChanged(Currency currency) async {
    print(
      'Currency changed from ${_selectedCurrency.code} to ${currency.code}',
    );
    if (currency.code == _selectedCurrency.code) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(
        _amountController.text.replaceAll(',', ''),
      );
      print('Amount to convert: $amount');
      if (amount != null && amount > 0) {
        // Convert amount to new currency
        final convertedAmount = await _currencyService.convertAmount(
          amount: amount,
          fromCurrency: _selectedCurrency.code,
          toCurrency: currency.code,
        );

        if (convertedAmount != null) {
          print('Converted amount: ${convertedAmount.amount}');
          // Store original amount and currency
          _originalAmount = amount;
          _originalCurrency = _selectedCurrency;
          _exchangeRate = convertedAmount.amount / amount;

          // Update display
          _amountController.text = NumberFormat.decimalPattern().format(
            convertedAmount.amount,
          );
          _selectedCurrency = currency;
          print('Currency updated to: ${_selectedCurrency.code}');
        } else {
          print('Conversion returned null');
          _selectedCurrency = currency;
        }
      } else {
        print('No amount to convert or amount is 0');
        _selectedCurrency = currency;
      }
    } catch (e) {
      print('Error in currency conversion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error converting currency: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final selectedBudgetId = _selectedBudget?.id;

      if (widget.editTransaction != null) {
        // Update existing transaction
        Transaction updatedTransaction;

        if (_selectedCurrency.code == SupportedCurrencies.baseCurrency) {
          // Base currency transaction
          updatedTransaction = widget.editTransaction!.copyWith(
            title: _titleController.text.trim(),
            amount: amount,
            categoryId: _selectedCategory!.id,
            type: _selectedType,
            date: _selectedDate,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            isRecurring: _isRecurring,
            recurringType: _isRecurring ? _recurringType : null,
            currencyCode: _selectedCurrency.code,
            originalAmount: null,
            originalCurrencyCode: null,
            exchangeRate: null,
            budgetId: selectedBudgetId,
          );
        } else {
          // Foreign currency transaction - convert to base currency for storage
          try {
            final convertedAmount = await _currencyService
                .convertToBaseCurrency(
                  amount: amount,
                  fromCurrency: _selectedCurrency.code,
                );

            if (convertedAmount != null) {
              updatedTransaction = widget.editTransaction!.copyWith(
                title: _titleController.text.trim(),
                amount:
                    convertedAmount.convertedAmount!, // Store in base currency
                categoryId: _selectedCategory!.id,
                type: _selectedType,
                date: _selectedDate,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                isRecurring: _isRecurring,
                recurringType: _isRecurring ? _recurringType : null,
                currencyCode:
                    SupportedCurrencies.baseCurrency, // Store as base currency
                originalAmount: amount, // Store original foreign amount
                originalCurrencyCode:
                    _selectedCurrency.code, // Store original currency
                exchangeRate:
                    convertedAmount.convertedAmount! /
                    amount, // Store exchange rate
                budgetId: selectedBudgetId,
              );
            } else {
              // Fallback: store as foreign currency without conversion
              updatedTransaction = widget.editTransaction!.copyWith(
                title: _titleController.text.trim(),
                amount: amount,
                categoryId: _selectedCategory!.id,
                type: _selectedType,
                date: _selectedDate,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                isRecurring: _isRecurring,
                recurringType: _isRecurring ? _recurringType : null,
                currencyCode: _selectedCurrency.code,
                originalAmount: null,
                originalCurrencyCode: null,
                exchangeRate: null,
                budgetId: selectedBudgetId,
              );
            }
          } catch (e) {
            print('Error converting currency: $e');
            // Fallback: store as foreign currency without conversion
            updatedTransaction = widget.editTransaction!.copyWith(
              title: _titleController.text.trim(),
              amount: amount,
              categoryId: _selectedCategory!.id,
              type: _selectedType,
              date: _selectedDate,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              isRecurring: _isRecurring,
              recurringType: _isRecurring ? _recurringType : null,
              currencyCode: _selectedCurrency.code,
              originalAmount: null,
              originalCurrencyCode: null,
              exchangeRate: null,
              budgetId: selectedBudgetId,
            );
          }
        }

        await _databaseService.updateTransaction(updatedTransaction);
      } else {
        // Create new transaction
        Transaction transaction;

        if (_selectedCurrency.code == SupportedCurrencies.baseCurrency) {
          // Base currency transaction
          transaction = Transaction.create(
            title: _titleController.text.trim(),
            amount: amount,
            categoryId: _selectedCategory!.id,
            type: _selectedType,
            userId: userId,
            date: _selectedDate,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            isRecurring: _isRecurring,
            recurringType: _isRecurring ? _recurringType : null,
            currencyCode: _selectedCurrency.code,
            originalAmount: null,
            originalCurrencyCode: null,
            exchangeRate: null,
            budgetId: selectedBudgetId,
          );
          print(
            'Created base currency transaction: $amount ${_selectedCurrency.code}',
          );
        } else {
          // Foreign currency transaction - convert to base currency for storage
          print(
            'Converting foreign currency: $amount ${_selectedCurrency.code} to ${SupportedCurrencies.baseCurrency}',
          );
          try {
            final convertedAmount = await _currencyService
                .convertToBaseCurrency(
                  amount: amount,
                  fromCurrency: _selectedCurrency.code,
                );

            if (convertedAmount != null) {
              transaction = Transaction.create(
                title: _titleController.text.trim(),
                amount:
                    convertedAmount.convertedAmount!, // Store in base currency
                categoryId: _selectedCategory!.id,
                type: _selectedType,
                userId: userId,
                date: _selectedDate,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                isRecurring: _isRecurring,
                recurringType: _isRecurring ? _recurringType : null,
                currencyCode:
                    SupportedCurrencies.baseCurrency, // Store as base currency
                originalAmount: amount, // Store original foreign amount
                originalCurrencyCode:
                    _selectedCurrency.code, // Store original currency
                exchangeRate:
                    convertedAmount.convertedAmount! /
                    amount, // Store exchange rate
                budgetId: selectedBudgetId,
              );
            } else {
              print('Conversion failed: convertedAmount is null');
              // Fallback: store as foreign currency without conversion
              transaction = Transaction.create(
                title: _titleController.text.trim(),
                amount: amount,
                categoryId: _selectedCategory!.id,
                type: _selectedType,
                userId: userId,
                date: _selectedDate,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                isRecurring: _isRecurring,
                recurringType: _isRecurring ? _recurringType : null,
                currencyCode: _selectedCurrency.code,
                originalAmount: null,
                originalCurrencyCode: null,
                exchangeRate: null,
                budgetId: selectedBudgetId,
              );
            }
          } catch (e) {
            print('Error converting currency: $e');
            // Fallback: store as foreign currency without conversion
            transaction = Transaction.create(
              title: _titleController.text.trim(),
              amount: amount,
              categoryId: _selectedCategory!.id,
              type: _selectedType,
              userId: userId,
              date: _selectedDate,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              isRecurring: _isRecurring,
              recurringType: _isRecurring ? _recurringType : null,
              currencyCode: _selectedCurrency.code,
              originalAmount: null,
              originalCurrencyCode: null,
              exchangeRate: null,
              budgetId: selectedBudgetId,
            );
          }
        }

        await _databaseService.addTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving transaction: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          widget.editTransaction != null
              ? 'Edit Transaction'
              : 'Add Transaction',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTransaction,
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
              // Transaction Type Toggle
              _buildTypeToggle(),

              const SizedBox(height: 24),

              // Amount Field
              _buildAmountField(),

              const SizedBox(height: 24),

              // Title Field
              _buildTitleField(),

              const SizedBox(height: 24),

              // Category Selection
              _buildCategorySelection(),

              const SizedBox(height: 12),

              // Budget selection (optional, when budgets exist for category)
              _buildBudgetSelection(),

              const SizedBox(height: 24),

              // Currency Selection
              _buildCurrencySelection(),

              const SizedBox(height: 24),

              // Date Selection
              _buildDateSelection(),

              const SizedBox(height: 24),

              // Description Field
              _buildDescriptionField(),

              const SizedBox(height: 24),

              // Recurring Options
              _buildRecurringOptions(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onTypeChanged(TransactionType.expense),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.expense
                      ? Colors.red
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_circle_outline,
                      color: _selectedType == TransactionType.expense
                          ? Colors.white
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expense',
                      style: TextStyle(
                        color: _selectedType == TransactionType.expense
                            ? Colors.white
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onTypeChanged(TransactionType.income),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.income
                      ? Colors.green
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: _selectedType == TransactionType.income
                          ? Colors.white
                          : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Income',
                      style: TextStyle(
                        color: _selectedType == TransactionType.income
                            ? Colors.white
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onTypeChanged(TransactionType.saving),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedType == TransactionType.saving
                      ? Colors.blue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      color: _selectedType == TransactionType.saving
                          ? Colors.white
                          : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saving',
                      style: TextStyle(
                        color: _selectedType == TransactionType.saving
                            ? Colors.white
                            : Colors.blue,
                        fontWeight: FontWeight.w600,
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
    );
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

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
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
            controller: _titleController,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2C2C2C),
            ),
            decoration: InputDecoration(
              hintText: 'Enter transaction title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
              contentPadding: EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
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

        // Smart suggestions
        if (_showSuggestions && _categorySuggestions.isNotEmpty) ...[
          _buildCategorySuggestions(),
          const SizedBox(height: 12),
        ],

        // Category picker
        CategoryPickerField(
          categories: _categories,
          selectedCategoryId: _selectedCategory?.id,
          categoryType: _selectedType == TransactionType.income
              ? CategoryType.income
              : CategoryType.expense,
          enabled: _selectedType != TransactionType.saving,
          onSelected: (cat) async {
            setState(() {
              // Add newly created category to local list if not present
              if (!_categories.any((c) => c.id == cat.id)) {
                _categories.insert(0, cat);
              }
              _selectedCategory = cat;
              _selectedBudget = null;
              _availableBudgets = [];
              // Clear suggestions when manually selecting
              _categorySuggestions = [];
              _showSuggestions = false;
              _autoSuggestedCategory = null;
            });
            final userId = _authService.currentUser?.uid ?? '';
            await _loadBudgetsForSelectedCategory(userId);
          },
        ),
      ],
    );
  }

  Widget _buildCategorySuggestions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1F3A)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart Suggestion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                ),
              ),
              const Spacer(),
              if (_autoSuggestedCategory != null)
                Text(
                  '${(_autoSuggestedCategory!.confidence * 100).toInt()}% match',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._categorySuggestions
              .take(2)
              .map((suggestion) => _buildSuggestionItem(suggestion)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(CategorySuggestion suggestion) {
    final isAutoSuggested =
        _autoSuggestedCategory?.category.id == suggestion.category.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = suggestion.category;
          _categorySuggestions = [];
          _showSuggestions = false;
          _autoSuggestedCategory = null;
        });
        // Load budgets for selected category
        final userId = _authService.currentUser?.uid ?? '';
        _loadBudgetsForSelectedCategory(userId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isAutoSuggested ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAutoSuggested
                ? Colors.blue.shade300
                : Colors.grey.shade300,
            width: isAutoSuggested ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.category, color: suggestion.category.color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                suggestion.category.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isAutoSuggested
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF2C2C2C),
                ),
              ),
            ),
            if (suggestion.matchedKeywords.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  suggestion.matchedKeywords.first,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ],
            if (isAutoSuggested) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: Colors.blue.shade600, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSelection() {
    if (_availableBudgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apply to budget (optional)',
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
          child: DropdownButtonFormField<Budget>(
            value: _selectedBudget,
            decoration: InputDecoration(
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
            hint: const Text('Select a budget (optional)'),
            items: _availableBudgets.map((b) {
              return DropdownMenuItem<Budget>(
                value: b,
                child: Text('${b.name} • ${b.formattedAmount}'),
              );
            }).toList(),
            onChanged: (Budget? value) {
              setState(() {
                _selectedBudget = value;
              });
            },
          ),
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

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
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
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF666666)),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
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
              hintText: 'Add a note about this transaction',
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

  Widget _buildRecurringOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value ?? false;
                  if (!_isRecurring) {
                    _recurringType = null;
                  }
                });
              },
              activeColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2C2C2C),
            ),
            Text(
              'Recurring Transaction',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
              ),
            ),
          ],
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 16),
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
            child: DropdownButtonFormField<RecurringType>(
              value: _recurringType,
              decoration: InputDecoration(
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
              hint: const Text('Select frequency'),
              items: RecurringType.values.map((type) {
                return DropdownMenuItem<RecurringType>(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (RecurringType? value) {
                setState(() {
                  _recurringType = value;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  // ignore: unused_element
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
