import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/onboarding_controller.dart';
import '../../../models/onboarding_data.dart';
import '../../../widgets/onboarding/option_card.dart';

class SpendingStyleScreen extends StatefulWidget {
  const SpendingStyleScreen({super.key});

  @override
  State<SpendingStyleScreen> createState() => _SpendingStyleScreenState();
}

class _SpendingStyleScreenState extends State<SpendingStyleScreen> {
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
                'What\'s your spending style?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'This helps us understand your financial behavior and provide better recommendations.',
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
                      title: 'Conservative',
                      subtitle: 'I prefer to save more and spend less',
                      icon: Icons.savings,
                      isSelected:
                          controller.data.spendingStyle ==
                          SpendingStyle.conservative,
                      onTap: () {
                        controller.updateSpendingStyle(
                          SpendingStyle.conservative,
                        );
                        // Auto-advance after selection
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (ModalRoute.of(context)?.isCurrent ??
                              true && controller.currentStep < 7) {
                            controller.nextStep();
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Moderate',
                      subtitle: 'I balance saving and spending',
                      icon: Icons.balance,
                      isSelected:
                          controller.data.spendingStyle ==
                          SpendingStyle.moderate,
                      onTap: () {
                        controller.updateSpendingStyle(SpendingStyle.moderate);
                        // Auto-advance after selection
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (ModalRoute.of(context)?.isCurrent ??
                              true && controller.currentStep < 7) {
                            controller.nextStep();
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Aggressive',
                      subtitle: 'I\'m comfortable with higher spending',
                      icon: Icons.trending_up,
                      isSelected:
                          controller.data.spendingStyle ==
                          SpendingStyle.aggressive,
                      onTap: () {
                        controller.updateSpendingStyle(
                          SpendingStyle.aggressive,
                        );
                        // Auto-advance after selection
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (ModalRoute.of(context)?.isCurrent ??
                              true && controller.currentStep < 7) {
                            controller.nextStep();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.purple[700],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your spending style helps us suggest appropriate budget limits and savings goals.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.purple[700],
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
