import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/auth_wrapper.dart';
import '../../widgets/onboarding/progress_bar.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/loading_overlay.dart';
import 'screens/welcome_screen.dart';
import 'screens/user_type_screen.dart';
import 'screens/income_details_screen.dart';
import 'screens/income_frequency_screen.dart';
import 'screens/spending_style_screen.dart';
import 'screens/financial_goals_screen.dart';
import 'screens/currency_preferences_screen.dart';
import 'screens/summary_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Load existing onboarding data if any - defer to after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = Provider.of<OnboardingController>(
          context,
          listen: false,
        );
        controller.loadData();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingController(),
      child: Consumer<OnboardingController>(
        builder: (context, controller, child) {
          return LoadingOverlay(
            isLoading: controller.isLoading,
            message: controller.isOnlineSync
                ? 'Syncing with cloud...'
                : 'Loading...',
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    // Error banner with performance optimization
                    if (controller.errorMessage != null)
                      RepaintBoundary(
                        child: ErrorBanner(
                          message: controller.errorMessage!,
                          onRetry: controller.hasNetworkError
                              ? () => controller.retryLastOperation()
                              : null,
                          onDismiss: () => controller.clearErrors(),
                          showRetry: controller.hasNetworkError,
                        ),
                      ),

                    // Progress bar with performance optimization
                    RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: OnboardingProgressBar(
                          progress: controller.progressPercentage,
                          currentStep: controller.currentStep,
                          totalSteps: 8,
                        ),
                      ),
                    ),

                    // Page view with performance optimization
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 8, // Total screens
                        itemBuilder: (context, index) {
                          // Use RepaintBoundary for each screen to isolate repaints
                          return RepaintBoundary(
                            child: _buildScreen(index, controller),
                          );
                        },
                      ),
                    ),

                    // Navigation buttons with performance optimization
                    RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            if (controller.currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: controller.isLoading
                                      ? null
                                      : () {
                                          controller.previousStep();
                                          _pageController.previousPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                  child: const Text('Back'),
                                ),
                              ),
                            if (controller.currentStep > 0)
                              const SizedBox(width: 16),
                            Expanded(
                              flex: controller.currentStep == 0 ? 1 : 2,
                              child: ElevatedButton(
                                onPressed: controller.isLoading
                                    ? null
                                    : () {
                                        if (controller.currentStep < 7) {
                                          controller.nextStep();
                                          _pageController.nextPage(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        } else {
                                          // Complete onboarding
                                          _completeOnboarding(
                                            context,
                                            controller,
                                          );
                                        }
                                      },
                                child: Text(
                                  controller.currentStep == 7
                                      ? 'Get Started'
                                      : 'Next',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreen(int index, OnboardingController controller) {
    switch (index) {
      case 0:
        return const WelcomeScreen();
      case 1:
        return const UserTypeScreen();
      case 2:
        return const CurrencyPreferencesScreen();
      case 3:
        return const IncomeDetailsScreen();
      case 4:
        return const IncomeFrequencyScreen();
      case 5:
        return const SpendingStyleScreen();
      case 6:
        return const FinancialGoalsScreen();
      case 7:
        return const SummaryScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _completeOnboarding(
    BuildContext context,
    OnboardingController controller,
  ) async {
    try {
      await controller.completeOnboarding();
      if (mounted) {
        // Navigate to main app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthWrapper()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing onboarding: $e')),
        );
      }
    }
  }
}
