import 'package:flutter/material.dart';

/// An optimized progress bar for onboarding flow with smooth animations
/// and performance-conscious rendering.
class OnboardingProgressBar extends StatefulWidget {
  final double progress;
  final int currentStep;
  final int totalSteps;
  final bool animate;

  const OnboardingProgressBar({
    super.key,
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
    this.animate = true,
  });

  @override
  State<OnboardingProgressBar> createState() => _OnboardingProgressBarState();
}

class _OnboardingProgressBarState extends State<OnboardingProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // Cache theme colors to avoid repeated lookups
  Color? _primaryColor;
  Color? _greyColor;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Optimized duration
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic, // Smoother curve
          ),
        );

    if (widget.animate) {
      _animationController.forward();
    } else {
      _progressAnimation = AlwaysStoppedAnimation(widget.progress);
    }
  }

  @override
  void didUpdateWidget(OnboardingProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update cached colors if theme might have changed and widget is initialized
    // Update cached colors if theme might have changed and widget is initialized
    // or if it's the first time didChangeDependencies is called.
    _updateCachedColors();
    _isInitialized = true;

    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.progress,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.easeOutCubic,
            ),
          );

      if (widget.animate) {
        _animationController.forward(from: 0.0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update cached colors when dependencies change
    _updateCachedColors();
    // Mark as initialized after the first call to didChangeDependencies
    _isInitialized = true;
  }

  void _updateCachedColors() {
    final theme = Theme.of(context);
    _primaryColor = theme.primaryColor;
    _greyColor = Colors.grey[600]!;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator row - optimized with RepaintBoundary
        RepaintBoundary(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${widget.currentStep + 1} of ${widget.totalSteps}',
                style: TextStyle(
                  color: _greyColor ?? Colors.grey[600]!,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) => Text(
                  '${(_progressAnimation.value * 100).round()}%',
                  style: TextStyle(
                    color: _greyColor ?? Colors.grey[600]!,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Progress bar - optimized with RepaintBoundary and efficient painting
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return SizedBox(
                height: 4,
                child: CustomPaint(
                  painter: _ProgressBarPainter(
                    progress: _progressAnimation.value,
                    primaryColor:
                        _primaryColor ?? Theme.of(context).primaryColor,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Custom painter for efficient progress bar rendering
class _ProgressBarPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;

  _ProgressBarPainter({required this.progress, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Background
    paint.color = Colors.grey[200]!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
      paint,
    );

    // Progress fill
    if (progress > 0) {
      paint.color = primaryColor;
      final progressWidth = size.width * progress;

      // Main progress bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, progressWidth, size.height),
          const Radius.circular(2),
        ),
        paint,
      );

      // Shadow effect for visual depth
      paint.color = primaryColor.withValues(alpha: 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height * 0.5, progressWidth, size.height * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}
