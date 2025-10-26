import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/onboarding_controller.dart';
import '../../../models/onboarding_data.dart';
import '../../../widgets/onboarding/option_card.dart';

class UserTypeScreen extends StatelessWidget {
  const UserTypeScreen({super.key});

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
                'What best describes you?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'This helps us personalize your experience and provide relevant features.',
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
                      title: 'Individual',
                      subtitle: 'Managing personal finances',
                      icon: Icons.person,
                      isSelected:
                          controller.data.userType == UserType.individual,
                      onTap: () =>
                          controller.updateUserType(UserType.individual),
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Business Owner',
                      subtitle: 'Running a business or freelance work',
                      icon: Icons.business,
                      isSelected: controller.data.userType == UserType.business,
                      onTap: () => controller.updateUserType(UserType.business),
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Student',
                      subtitle: 'Learning about personal finance',
                      icon: Icons.school,
                      isSelected: controller.data.userType == UserType.student,
                      onTap: () => controller.updateUserType(UserType.student),
                    ),

                    const SizedBox(height: 16),

                    OptionCard(
                      title: 'Freelancer',
                      subtitle: 'Independent contractor or consultant',
                      icon: Icons.work,
                      isSelected:
                          controller.data.userType == UserType.freelancer,
                      onTap: () =>
                          controller.updateUserType(UserType.freelancer),
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
