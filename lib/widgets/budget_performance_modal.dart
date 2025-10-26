import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../services/budget_auto_end_service.dart';

/// Modal to display budget performance summary at the end of period
class BudgetPerformanceModal extends StatelessWidget {
  final Budget budget;
  final Map<String, dynamic> progress;
  final VoidCallback? onRenew;
  final VoidCallback? onClose;

  const BudgetPerformanceModal({
    Key? key,
    required this.budget,
    required this.progress,
    this.onRenew,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalSpent = progress['totalSpent'] as double;
    final spentPercentage = progress['spentPercentage'] as double;
    final isOverBudget = progress['isOverBudget'] as bool;
    final rating = BudgetAutoEndService().calculateBudgetRating(progress);
    final stars = BudgetAutoEndService().getBudgetRatingStars(rating);
    
    final currencyFormat = NumberFormat.currency(
      symbol: budget.currency.symbol,
      decimalDigits: 0,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Budget Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Budget name and period
            Text(
              budget.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            Text(
              '${DateFormat('MMM d').format(budget.startDate)} - ${DateFormat('MMM d, y').format(budget.endDate)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            
            // Rating stars
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: _getRatingColor(rating).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    stars,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingText(rating, isOverBudget),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getRatingColor(rating),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Spending details
            _buildDetailRow(
              context,
              'Budget Amount',
              budget.formattedAmount,
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Total Spent',
              currencyFormat.format(totalSpent),
              Icons.shopping_cart,
              valueColor: isOverBudget ? Colors.red : null,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              'Remaining',
              currencyFormat.format(progress['remaining']),
              isOverBudget ? Icons.warning : Icons.savings,
              valueColor: isOverBudget ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 24),
            
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Used',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(spentPercentage * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: spentPercentage.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(spentPercentage, isOverBudget),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Performance message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    _getPerformanceEmoji(rating, isOverBudget),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getPerformanceMessage(
                        rating,
                        isOverBudget,
                        totalSpent,
                        budget.amount,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                if (onRenew != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRenew,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Renew Budget'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (onRenew != null) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.blue;
    if (rating >= 2.0) return Colors.orange;
    return Colors.red;
  }

  String _getRatingText(double rating, bool isOverBudget) {
    if (isOverBudget) {
      if (rating <= 1.0) return 'Needs Improvement';
      if (rating <= 2.0) return 'Over Budget';
      return 'Slightly Over';
    }
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 4.0) return 'Great Job!';
    if (rating >= 3.5) return 'Well Done!';
    if (rating >= 3.0) return 'Good';
    return 'Acceptable';
  }

  Color _getProgressColor(double percentage, bool isOverBudget) {
    if (isOverBudget) return Colors.red;
    if (percentage >= 0.95) return Colors.orange;
    if (percentage >= 0.8) return Colors.amber;
    return Colors.green;
  }

  String _getPerformanceEmoji(double rating, bool isOverBudget) {
    if (isOverBudget) return '❌';
    if (rating >= 4.5) return '🎉';
    if (rating >= 4.0) return '✅';
    if (rating >= 3.0) return '👍';
    return '✓';
  }

  String _getPerformanceMessage(
    double rating,
    bool isOverBudget,
    double spent,
    double budgetAmount,
  ) {
    if (isOverBudget) {
      final overAmount = spent - budgetAmount;
      final overPercentage = ((overAmount / budgetAmount) * 100).round();
      return 'You exceeded your budget by $overPercentage%. Consider reviewing your spending habits or adjusting your budget for next period.';
    }
    
    if (rating >= 4.5) {
      final savedPercentage = ((budgetAmount - spent) / budgetAmount * 100).round();
      return 'Amazing! You saved $savedPercentage% of your budget. Keep up the excellent financial discipline!';
    }
    
    if (rating >= 4.0) {
      return 'Great spending control! You stayed well within your budget while meeting your needs.';
    }
    
    if (rating >= 3.0) {
      return 'Good job staying within budget! There\'s still room for more savings next period.';
    }
    
    return 'You managed to stay within budget. Consider ways to increase savings in the next period.';
  }

  static Future<void> show({
    required BuildContext context,
    required Budget budget,
    required Map<String, dynamic> progress,
    VoidCallback? onRenew,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BudgetPerformanceModal(
        budget: budget,
        progress: progress,
        onRenew: onRenew,
        onClose: onClose,
      ),
    );
  }
}
