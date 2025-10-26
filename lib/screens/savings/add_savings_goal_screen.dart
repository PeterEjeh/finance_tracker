import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/savings_goal.dart';
import '../../models/currency.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../services/currency_settings_service.dart';
import '../../widgets/thousands_separator_input_formatter.dart';
import '../../widgets/currency_selector.dart';

class AddSavingsGoalScreen extends StatefulWidget {
  final SavingsGoal? goal;

  const AddSavingsGoalScreen({super.key, this.goal});

  @override
  State<AddSavingsGoalScreen> createState() => _AddSavingsGoalScreenState();
}

class _AddSavingsGoalScreenState extends State<AddSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();
  final CurrencyService _currencyService = CurrencyService();

  DateTime? _targetDate;
  SavingsGoalFrequency _frequency = SavingsGoalFrequency.monthly;
  bool _alertEnabled = true;
  double _alertThreshold = 0.5;
  bool _isLoading = false;
  // Currency fields
  late Currency _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<CurrencySettingsService>(
      context,
      listen: false,
    );
    _selectedCurrency = settings.baseCurrency;
    if (widget.goal != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final goal = widget.goal!;
    _nameController.text = goal.name;
    _targetAmountController.text = goal.targetAmount.toString();
    _descriptionController.text = goal.description ?? '';
    _targetDate = goal.targetDate;
    _frequency = goal.contributionFrequency;
    _alertEnabled = goal.alertEnabled;
    _alertThreshold = goal.alertThreshold;
    _selectedCurrency = goal.currency;
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';
      final targetAmount = double.parse(
        _targetAmountController.text.replaceAll(',', ''),
      );

      SavingsGoal goal = SavingsGoal.create(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        targetAmount: targetAmount,
        targetDate: _targetDate!,
        userId: userId,
        currencyCode: _selectedCurrency.code,
        contributionFrequency: _frequency,
        alertEnabled: _alertEnabled,
        alertThreshold: _alertThreshold,
      );

      if (widget.goal != null) {
        // Update existing goal
        goal = goal.copyWith();
        goal.id = widget.goal!.id;
        goal.currentAmount = widget.goal!.currentAmount;
        await _databaseService.updateSavingsGoal(goal);
      } else {
        // Create new goal
        await _databaseService.addSavingsGoal(goal);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving goal: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTargetDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
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
        _targetDate = picked;
      });
    }
  }

  Future<void> _onCurrencyChanged(Currency currency) async {
    if (currency.code == _selectedCurrency.code) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.tryParse(
        _targetAmountController.text.replaceAll(',', ''),
      );
      if (amount != null && amount > 0) {
        // Convert amount to new currency
        final convertedAmount = await _currencyService.convertAmount(
          amount: amount,
          fromCurrency: _selectedCurrency.code,
          toCurrency: currency.code,
        );

        if (convertedAmount != null) {
          // Update display
          _targetAmountController.text = NumberFormat.decimalPattern().format(
            convertedAmount.amount,
          );
          _selectedCurrency = currency;
        }
      } else {
        _selectedCurrency = currency;
      }
    } catch (e) {
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
          widget.goal != null ? 'Edit Savings Goal' : 'New Savings Goal',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveGoal,
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
              _buildNameField(),
              const SizedBox(height: 24),
              _buildTargetAmountField(),
              const SizedBox(height: 24),
              _buildTargetDateField(),
              const SizedBox(height: 24),
              _buildCurrencySelection(),
              const SizedBox(height: 24),
              _buildFrequencySelection(),
              const SizedBox(height: 24),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildAlertSettings(),
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
          'Goal Name',
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
              hintText: 'e.g., New Car, Vacation, Emergency Fund',
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
                return 'Please enter a goal name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTargetAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Amount',
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
            controller: _targetAmountController,
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
                return 'Please enter a target amount';
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

  Widget _buildTargetDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Date',
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
          onTap: _selectTargetDate,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _targetDate != null
                      ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                      : 'Select target date',
                  style: TextStyle(
                    fontSize: 16,
                    color: _targetDate != null
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF2C2C2C))
                        : Colors.grey,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey,
                  size: 20,
                ),
              ],
            ),
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

  Widget _buildFrequencySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contribution Frequency',
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
          children: SavingsGoalFrequency.values.map((frequency) {
            final isSelected = _frequency == frequency;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _frequency = frequency;
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
                  frequency.displayName,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF2C2C2C).withOpacity(0.7),
                    fontSize: 14,
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
              hintText: 'Add notes about this savings goal...',
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
                'Progress Alerts',
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
              'Alert when ${(_alertThreshold * 100).toInt()}% of time has passed',
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
                min: 0.25,
                max: 0.9,
                divisions: 13,
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

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
