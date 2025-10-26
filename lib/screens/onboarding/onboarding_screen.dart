import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../services/settings_service.dart';
import '../../widgets/auth_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _pageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    _startTimer();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              await SettingsService().setOnboardingCompleted();
              await SettingsService().setFirstLaunchComplete();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthWrapper()),
              );
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  itemCount: demo_data.length,
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) => OnboardContent(
                    animation: demo_data[index].animation,
                    title: demo_data[index].title,
                    description: demo_data[index].description,
                  ),
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    demo_data.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: DotIndicator(isActive: index == _pageIndex),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pageIndex == demo_data.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: const Color(0xFF6C5CE7),
                      ),
                      child: Icon(
                        _pageIndex == demo_data.length - 1
                            ? Icons.check
                            : Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTimer() {
    // Timer removed as manual navigation is introduced
  }

  void _completeOnboarding() async {
    await SettingsService().setOnboardingCompleted();
    await SettingsService().setFirstLaunchComplete();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthWrapper()),
    );
  }
}

class DotIndicator extends StatelessWidget {
  const DotIndicator({super.key, this.isActive = false});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 4,
      width: isActive ? 24 : 4,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6C5CE7) : Colors.grey,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}

class Onboard {
  final String animation, title, description;

  Onboard({
    required this.animation,
    required this.title,
    required this.description,
  });
}

final List<Onboard> demo_data = [
  Onboard(
    animation: "assets/animations/track_your_expenses.json",
    title: "Track Every Transaction",
    description:
        "Effortlessly log and categorize all your income and expenses to stay on top of your finances.",
  ),
  Onboard(
    animation: "assets/animations/set_your_budgets.json",
    title: "Smart Budgeting Tools",
    description:
        "Create custom budgets for different categories and receive alerts to help you stick to your financial goals.",
  ),
  Onboard(
    animation: "assets/animations/track_your_savings.json",
    title: "Achieve Savings Goals",
    description:
        "Set clear savings targets, track your progress, and watch your wealth grow with dedicated savings plans.",
  ),
  Onboard(
    animation: "assets/animations/manage_your_finances.json",
    title: "Comprehensive Financial Overview",
    description:
        "Get a holistic view of your financial health with insightful reports and analytics, all in one place.",
  ),
];

class OnboardContent extends StatelessWidget {
  const OnboardContent({
    super.key,
    required this.animation,
    required this.title,
    required this.description,
  });

  final String animation, title, description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        Lottie.asset(animation, height: 250),
        const Spacer(),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(color: Colors.black54),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
