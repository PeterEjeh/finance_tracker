import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget.dart';
import '../services/budget_auto_end_service.dart';

/// Widget to display historical budget performance as a bar chart
class BudgetHistoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final String categoryName;

  const BudgetHistoryChart({
    Key? key,
    required this.history,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No historical data yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a budget period to see performance history',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Budget Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              categoryName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Chart
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final historyItem = history[groupIndex];
                        final totalSpent = historyItem['totalSpent'] as double;
                        final budgetAmount =
                            historyItem['budgetAmount'] as double;
                        final isOverBudget =
                            historyItem['isOverBudget'] as bool;
                        final rating = historyItem['rating'] as double;

                        return BarTooltipItem(
                          '${historyItem['period']}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: 'Spent: ${totalSpent.toStringAsFixed(0)}\n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Budget: ${budgetAmount.toStringAsFixed(0)}\n',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(
                              text: BudgetAutoEndService().getBudgetRatingStars(
                                rating,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < history.length) {
                            final period =
                                history[value.toInt()]['period'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                period,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatAmount(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getMaxY() / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300], strokeWidth: 1);
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                      left: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  barGroups: _createBarGroups(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  context,
                  'Budget',
                  Colors.blue.withOpacity(0.3),
                ),
                const SizedBox(width: 24),
                _buildLegendItem(context, 'Spent', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem(context, 'Over Budget', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    return history.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      final totalSpent = item['totalSpent'] as double;
      final budgetAmount = item['budgetAmount'] as double;
      final isOverBudget = item['isOverBudget'] as bool;

      return BarChartGroupData(
        x: index,
        barRods: [
          // Budget bar (background)
          BarChartRodData(
            toY: budgetAmount,
            color: Colors.blue.withOpacity(0.3),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          // Spent bar (foreground)
          BarChartRodData(
            toY: totalSpent,
            color: isOverBudget ? Colors.red : Colors.green,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY() {
    if (history.isEmpty) return 100;

    double max = 0;
    for (final item in history) {
      final totalSpent = item['totalSpent'] as double;
      final budgetAmount = item['budgetAmount'] as double;
      final highest = totalSpent > budgetAmount ? totalSpent : budgetAmount;
      if (highest > max) max = highest;
    }

    // Add 20% padding to the top
    return max * 1.2;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
