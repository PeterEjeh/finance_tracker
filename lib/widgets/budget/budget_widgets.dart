import 'package:flutter/material.dart';

class BudgetOverviewWidget extends StatelessWidget {
  final double spent;
  final double remaining;
  final double progress;
  final bool isOverBudget;
  final bool shouldAlert;
  final String budgetName;
  final String categoryName;

  const BudgetOverviewWidget({
    Key? key,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.isOverBudget,
    required this.shouldAlert,
    required this.budgetName,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(budgetName, style: Theme.of(context).textTheme.headlineMedium),
        if (categoryName.isNotEmpty)
          Text(
            'Category: $categoryName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Spent: \$${spent.toStringAsFixed(2)}'),
            Text(
              'Remaining: \$${remaining.toStringAsFixed(2)}',
              style: TextStyle(color: isOverBudget ? Colors.red : Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BudgetProgressWidget(
          progress: progress,
          isOverBudget: isOverBudget,
          shouldAlert: shouldAlert,
        ),
      ],
    );
  }
}

class BudgetProgressWidget extends StatelessWidget {
  final double progress;
  final bool isOverBudget;
  final bool shouldAlert;

  const BudgetProgressWidget({
    Key? key,
    required this.progress,
    required this.isOverBudget,
    required this.shouldAlert,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
          minHeight: 10,
        ),
        if (shouldAlert)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Warning: You are ${isOverBudget ? 'over' : 'close to reaching'} your budget limit!',
              style: TextStyle(
                color: isOverBudget ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Color _getProgressColor() {
    if (isOverBudget) {
      return Colors.red;
    } else if (shouldAlert) {
      return Colors.orange;
    }
    return Colors.green;
  }
}
