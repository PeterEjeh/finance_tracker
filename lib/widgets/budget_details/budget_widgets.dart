import 'package:flutter/material.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';

class BudgetOverviewWidget extends StatelessWidget {
  final double spent;
  final double remaining;
  final double progress;
  final bool isOverBudget;
  final bool shouldAlert;
  final Budget budget;
  final Category? category;

  const BudgetOverviewWidget({
    Key? key,
    required this.spent,
    required this.remaining,
    required this.progress,
    required this.isOverBudget,
    required this.shouldAlert,
    required this.budget,
    this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: category?.color ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Unknown Category',
                      style: TextStyle(
                        color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                            .withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      budget.type.displayName,
                      style: TextStyle(
                        color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                            .withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Over Budget',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (shouldAlert)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Alert',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% used',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${budget.daysRemaining} days left',
                    style: TextStyle(
                      color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                          .withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget
                        ? Colors.red
                        : shouldAlert
                        ? Colors.orange
                        : const Color(0xFF00D4AA),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${(progress * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF2C2C2C),
            ),
          ),
          Text(
            isOverBudget
                ? 'Over budget'
                : shouldAlert
                ? 'Warning'
                : 'On track',
            style: TextStyle(
              fontSize: 12,
              color: isOverBudget
                  ? Colors.red
                  : shouldAlert
                  ? Colors.orange
                  : const Color(0xFF6C5CE7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetInfoWidget extends StatelessWidget {
  final Budget budget;

  const BudgetInfoWidget({Key? key, required this.budget}) : super(key: key);

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                    .withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Information',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF2C2C2C),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Period', budget.period.displayName),
          _buildInfoRow(
            context,
            'Start Date',
            '${budget.startDate.day}/${budget.startDate.month}/${budget.startDate.year}',
          ),
          _buildInfoRow(
            context,
            'End Date',
            '${budget.endDate.day}/${budget.endDate.month}/${budget.endDate.year}',
          ),
          _buildInfoRow(
            context,
            'Status',
            budget.isActive ? 'Active' : 'Inactive',
          ),
          if (budget.alertEnabled)
            _buildInfoRow(
              context,
              'Alert Threshold',
              '${(budget.alertThreshold * 100).toInt()}%',
            ),
          if (budget.description != null && budget.description!.isNotEmpty)
            _buildInfoRow(context, 'Description', budget.description!),
        ],
      ),
    );
  }
}

class TransactionsListWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final Category? category;

  const TransactionsListWidget({
    Key? key,
    required this.transactions,
    this.category,
  }) : super(key: key);

  Widget _buildTransactionItem(BuildContext context, Transaction transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (category?.color ?? Colors.grey).withOpacity(
              isDark ? 0.2 : 0.1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            transaction.type == TransactionType.income
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: transaction.type == TransactionType.income
                ? const Color(0xFF00D4AA)
                : Colors.red,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                style: TextStyle(
                  color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                      .withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${transaction.type == TransactionType.income ? '+' : '-'}${transaction.currency.formatAmount(transaction.amount)}',
          style: TextStyle(
            color: transaction.type == TransactionType.income
                ? const Color(0xFF00D4AA)
                : (isDark ? Colors.white : const Color(0xFF2C2C2C)),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Related Transactions',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${transactions.length} transactions',
                style: TextStyle(
                  color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                      .withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                            .withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Transactions in this category will appear here',
                      style: TextStyle(
                        color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                            .withOpacity(0.4),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 5 ? 5 : transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _buildTransactionItem(context, transaction);
              },
            ),
          if (transactions.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full transactions list filtered by category
                    // This would be implemented when we have the transactions screen
                  },
                  child: Text(
                    'View all ${transactions.length} transactions',
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
