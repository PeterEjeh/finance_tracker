import 'package:flutter/material.dart';

/// Custom skeleton loading widgets for the finance tracker app.
/// These widgets provide shimmer-free placeholder content that mimics
/// the actual UI components during loading states using simple animated containers.

class FinanceSkeletonLoader {
  /// Creates a skeleton card similar to summary cards (income/expense)
  static Widget buildSummaryCardSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Icon and title row
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Amount
          Container(
            width: 100,
            height: 20,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
          ),
        ],
      ),
    ).withShimmer();
  }

  /// Creates skeleton for balance card
  static Widget buildBalanceCardSkeleton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF404040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            width: 120,
            height: 16,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          // Balance amount
          Container(
            width: 200,
            height: 32,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          // Period text
          Container(
            width: 100,
            height: 14,
            color: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
    ).withShimmer();
  }

  /// Creates skeleton for transaction list items
  static Widget buildTransactionSkeleton(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: skeletonColor,
              shape: BoxShape.circle,
            ),
          ),
          title: Container(width: 120, height: 16, color: skeletonColor),
          trailing: Container(width: 80, height: 16, color: skeletonColor),
          subtitle: Container(width: 80, height: 12, color: skeletonColor),
        ).withShimmer(),
      ),
    );
  }

  /// Creates skeleton for quick action cards
  static Widget buildQuickActionSkeleton(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.grey.shade200;

    return Row(
      children: List.generate(
        count,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < count - 1 ? 8.0 : 0),
            child: SizedBox(
              height: 96,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(width: 60, height: 12, color: skeletonColor),
                  ],
                ),
              ).withShimmer(),
            ),
          ),
        ),
      ),
    );
  }

  /// Creates skeleton for budget overview cards
  static Widget buildBudgetCardSkeleton(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: skeletonColor,
              shape: BoxShape.circle,
            ),
          ),
          title: Container(width: 100, height: 16, color: skeletonColor),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Container(width: 140, height: 14, color: skeletonColor),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 4,
                color: skeletonColor,
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 40, height: 16, color: skeletonColor),
              const SizedBox(height: 2),
              Container(width: 50, height: 12, color: skeletonColor),
            ],
          ),
        ).withShimmer(),
      ),
    );
  }

  /// Creates a full dashboard skeleton layout
  static Widget buildDashboardSkeleton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 32.0 : 16.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card Skeleton
              buildBalanceCardSkeleton(context),
              const SizedBox(height: 24),

              // Summary Cards Row
              if (isLargeScreen) ...[
                Row(
                  children: [
                    Expanded(flex: 2, child: buildSummaryCardSkeleton(context)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: buildSummaryCardSkeleton(context)),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: buildSummaryCardSkeleton(context)),
                    const SizedBox(width: 16),
                    Expanded(child: buildSummaryCardSkeleton(context)),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Quick Actions
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                  ),
                ),
              ),
              buildQuickActionSkeleton(context, 4),
              const SizedBox(height: 24),

              // Analytics Section Skeleton
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                  ),
                ),
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1F3A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 24),

              // Budget Overview Skeleton
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Budget Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                  ),
                ),
              ),
              buildBudgetCardSkeleton(context, 2),
              const SizedBox(height: 24),

              // Recent Transactions Skeleton
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                  ),
                ),
              ),
              buildTransactionSkeleton(context, 3),
            ],
          ),
        );
      },
    );
  }
}

/// Extension on Widget to add shimmer effect
extension ShimmerExtension on Widget {
  Widget withShimmer() {
    return _ShimmerWrapper(child: this);
  }
}

/// A simple shimmer wrapper using AnimatedOpacity
class _ShimmerWrapper extends StatefulWidget {
  final Widget child;

  const _ShimmerWrapper({required this.child});

  @override
  State<_ShimmerWrapper> createState() => _ShimmerWrapperState();
}

class _ShimmerWrapperState extends State<_ShimmerWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: _animation.value, child: widget.child);
      },
    );
  }
}
