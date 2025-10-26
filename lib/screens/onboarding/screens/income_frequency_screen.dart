import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/onboarding_controller.dart';
import '../../../models/onboarding_data.dart';
import '../../../widgets/onboarding/option_card.dart';

class IncomeFrequencyScreen extends StatelessWidget {
  const IncomeFrequencyScreen({super.key});

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
                'How often do you get paid?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'This helps us calculate your cash flow and suggest appropriate budgeting periods.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),

              const SizedBox(height: 32),

              // Options
              Expanded(
                child: ListView(
                  children: [
                    OptionCard(
                      title: 'Weekly',
                      subtitle: 'Every 7 days',
                      icon: Icons.calendar_view_week,
                      isSelected:
                          controller.data.incomeFrequency ==
                          IncomeFrequency.weekly,
                      onTap: () => controller.updateIncomeFrequency(
                        IncomeFrequency.weekly,
                      ),
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Bi-weekly',
                      subtitle: 'Every 2 weeks',
                      icon: Icons.calendar_view_week,
                      isSelected:
                          controller.data.incomeFrequency ==
                          IncomeFrequency.biweekly,
                      onTap: () => controller.updateIncomeFrequency(
                        IncomeFrequency.biweekly,
                      ),
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Monthly',
                      subtitle: 'Once per month',
                      icon: Icons.calendar_month,
                      isSelected:
                          controller.data.incomeFrequency ==
                          IncomeFrequency.monthly,
                      onTap: () => controller.updateIncomeFrequency(
                        IncomeFrequency.monthly,
                      ),
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Quarterly',
                      subtitle: 'Every 3 months',
                      icon: Icons.calendar_today,
                      isSelected:
                          controller.data.incomeFrequency ==
                          IncomeFrequency.quarterly,
                      onTap: () => controller.updateIncomeFrequency(
                        IncomeFrequency.quarterly,
                      ),
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Annually',
                      subtitle: 'Once per year',
                      icon: Icons.calendar_view_month,
                      isSelected:
                          controller.data.incomeFrequency ==
                          IncomeFrequency.annually,
                      onTap: () => controller.updateIncomeFrequency(
                        IncomeFrequency.annually,
                      ),
                    ),
                  ],
                ),
              ),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your income frequency affects how we suggest budget periods and savings goals.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[700],
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
}
