import '../models/budget.dart';
import 'package:intl/intl.dart';

class InsightsService {
  static String getBudgetInsight(Map<String, dynamic> budgetProgress) {
    final budget = budgetProgress['budget'] as Budget;
    final totalSpent = budgetProgress['totalSpent'] as double?;
    final remaining = budgetProgress['remaining'] as double?;
    final spentPercentage = budgetProgress['spentPercentage'] as double?;
    final daysRemaining = budgetProgress['daysRemaining'] as int?;

    switch (budget.type) {
      case BudgetType.progressive:
        final expectedDailySpend =
            budgetProgress['expectedDailySpend'] as double;
        final expectedSpend = budgetProgress['expectedSpend'] as double;
        final lowerTolerance = budgetProgress['lowerTolerance'] as double;
        final upperTolerance = budgetProgress['upperTolerance'] as double;

        if (totalSpent! > upperTolerance) {
          final overSpend = totalSpent - expectedSpend;
          return 'You\'re spending ${NumberFormat.currency(symbol: budget.currency.symbol).format(overSpend)} faster than expected. Slow down to stay within ${budget.formattedAmount}.';
        } else if (totalSpent < lowerTolerance) {
          final underSpend = expectedSpend - totalSpent;
          return 'You\'re spending ${NumberFormat.currency(symbol: budget.currency.symbol).format(underSpend)} slower than expected. You have room to spend more if needed.';
        } else {
          return 'You\'re on track with your spending for ${budget.name}.';
        }

      case BudgetType.fixed:
        if (budgetProgress['isOverBudget'] as bool) {
          return 'You\'ve spent ${budget.formattedAmount} for ${budget.name} and are over budget.';
        } else {
          return 'You\'ve paid ${NumberFormat.currency(symbol: budget.currency.symbol).format(totalSpent)} for ${budget.name} — you\'re still on track for the ${budget.formattedAmount} limit.';
        }

      case BudgetType.recurring:
        if (daysRemaining != null && daysRemaining > 0) {
          return 'Your ${budget.formattedAmount} ${budget.name} budget renews in $daysRemaining days.';
        } else {
          return 'Your ${budget.name} budget has renewed.';
        }

      case BudgetType.goal:
        final totalSaved = budgetProgress['totalSaved'] as double;
        final remainingToGoal = budgetProgress['remainingToGoal'] as double;
        final progressPercentage =
            budgetProgress['progressPercentage'] as double;

        if (progressPercentage >= 1.0) {
          return 'You\'ve achieved your ${budget.name} goal! 🎯';
        } else {
          return 'You\'ve saved ${NumberFormat.percentPattern().format(progressPercentage)} of your ${budget.name} target — ${NumberFormat.currency(symbol: budget.currency.symbol).format(remainingToGoal)} left to go!';
        }
    }
  }

  List<String> getAllBudgetInsights(
    List<Map<String, dynamic>> allBudgetProgress,
  ) {
    final insights = <String>[];
    for (final budgetProgress in allBudgetProgress) {
      insights.add(getBudgetInsight(budgetProgress));
    }
    return insights;
  }
}
