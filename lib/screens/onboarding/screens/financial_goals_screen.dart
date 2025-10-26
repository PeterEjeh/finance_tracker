import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/onboarding_controller.dart';
import '../../../models/onboarding_data.dart';

class FinancialGoalsScreen extends StatefulWidget {
  const FinancialGoalsScreen({super.key});

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  final List<FinancialGoal> _selectedGoals = [];

  @override
  void initState() {
    super.initState();
    final controller = context.read<OnboardingController>();
    if (controller.data.financialGoals != null) {
      _selectedGoals.addAll(controller.data.financialGoals!);
    }
  }

  void _toggleGoal(FinancialGoal goal, OnboardingController controller) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
    controller.updateFinancialGoals(List.from(_selectedGoals));

    // Auto-advance if at least one goal is selected and user has been on this screen for a bit
    if (_selectedGoals.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted &&
            controller.currentStep < 7 &&
            _selectedGoals.isNotEmpty) {
          controller.nextStep();
        }
      });
    }
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
                'What are your financial goals?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Select all that apply. This helps us prioritize features and suggestions for you.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),

              // Goals Grid
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: FinancialGoal.values.map((goal) {
                      final isSelected = _selectedGoals.contains(goal);
                      return GestureDetector(
                        onTap: () => _toggleGoal(goal, controller),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getGoalIcon(goal),
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                goal.displayName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Selection summary with auto-advance hint
              if (_selectedGoals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected ${_selectedGoals.length} goal${_selectedGoals.length > 1 ? 's' : ''} • Tap "Next" or wait to continue',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can always add or modify your goals later in the app settings.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getGoalIcon(FinancialGoal goal) {
    switch (goal) {
      case FinancialGoal.save_for_emergency:
        return Icons.emergency;
      case FinancialGoal.buy_house:
        return Icons.home;
      case FinancialGoal.buy_car:
        return Icons.directions_car;
      case FinancialGoal.pay_debt:
        return Icons.credit_card;
      case FinancialGoal.invest:
        return Icons.trending_up;
      case FinancialGoal.travel:
        return Icons.flight;
      case FinancialGoal.education:
        return Icons.school;
      case FinancialGoal.retirement:
        return Icons.chair;
    }
  }
}
