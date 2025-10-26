import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/onboarding_controller.dart';
import '../../../widgets/thousands_separator_input_formatter.dart';
import '../../../models/currency.dart' as currency_model;

class IncomeDetailsScreen extends StatefulWidget {
  const IncomeDetailsScreen({super.key});

  @override
  State<IncomeDetailsScreen> createState() => _IncomeDetailsScreenState();
}

class _IncomeDetailsScreenState extends State<IncomeDetailsScreen> {
  final TextEditingController _incomeController = TextEditingController();
  final FocusNode _incomeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final controller = context.read<OnboardingController>();
    if (controller.data.incomeAmount != null) {
      final currencyCode = controller.data.currencyCode ?? 'USD';
      final currency = currency_model.SupportedCurrencies.getCurrency(
        currencyCode,
      );
      if (currency != null) {
        _incomeController.text = currency
            .formatAmount(controller.data.incomeAmount!)
            .replaceAll(currency.symbol, '')
            .trim();
      } else {
        _incomeController.text = controller.data.incomeAmount.toString();
      }
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _incomeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Title
              Text(
                'What\'s your monthly income?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'This helps us create personalized budgets and financial goals for you.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),

              // Income input
              Consumer<OnboardingController>(
                builder: (context, controller, child) {
                  final currencySymbol = controller.data.currencyCode != null
                      ? currency_model.SupportedCurrencies.getCurrency(
                              controller.data.currencyCode!,
                            )?.symbol ??
                            controller.data.currencyCode!
                      : '\$';

                  return TextFormField(
                    controller: _incomeController,
                    focusNode: _incomeFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monthly Income',
                      hintText: '',
                      prefixText: '$currencySymbol ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      final amount = double.tryParse(value.replaceAll(',', ''));
                      if (amount != null) {
                        controller.updateIncomeAmount(amount);
                      } else if (value.isEmpty) {
                        // Clear income if field is empty
                        controller.updateIncomeAmount(0);
                      }
                    },
                    onFieldSubmitted: (value) {
                      // Auto-advance to next screen when user presses enter
                      final amount = double.tryParse(value.replaceAll(',', ''));
                      if (amount != null && amount > 0) {
                        // Trigger next step after a brief delay for UX
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted && controller.currentStep < 7) {
                            controller.nextStep();
                          }
                        });
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Helper text
              Text(
                'Enter your take-home pay after taxes and deductions.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),

              const SizedBox(height: 32),

              // Quick select buttons
              Text(
                'Quick select:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (controller.data.currencyCode != null
                            ? currency_model
                                  .SupportedCurrencies
                                  .monthlySalaryRanges[controller
                                  .data
                                  .currencyCode!]
                            : currency_model
                                  .SupportedCurrencies
                                  .monthlySalaryRanges['USD'])! // Default to USD if no currency selected
                        .map(
                          (amount) => _buildQuickAmountButton(
                            context,
                            controller,
                            amount,
                          ),
                        )
                        .toList(),
              ),

              const Spacer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAmountButton(
    BuildContext context,
    OnboardingController controller,
    int amount,
  ) {
    final isSelected = controller.data.incomeAmount == amount.toDouble();
    final currencySymbol = controller.data.currencyCode != null
        ? currency_model.SupportedCurrencies.getCurrency(
                controller.data.currencyCode!,
              )?.symbol ??
              controller.data.currencyCode!
        : '\$';

    return OutlinedButton(
      onPressed: () {
        controller.updateIncomeAmount(amount.toDouble());
        _incomeController.text = amount.toString();
        // Auto-advance after quick selection
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && controller.currentStep < 7) {
            controller.nextStep();
          }
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        backgroundColor: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        currency_model.SupportedCurrencies.getCurrency(
          controller.data.currencyCode ?? 'USD', // Default to USD
        )!.formatAmount(amount.toDouble()),
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
