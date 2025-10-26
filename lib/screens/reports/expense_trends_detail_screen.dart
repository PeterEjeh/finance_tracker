import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/report.dart'; // Assuming SpendingTrend is defined here

class ExpenseTrendsDetailScreen extends StatelessWidget {
  final List<SpendingTrend> trends;
  final ReportPeriod selectedPeriod;

  const ExpenseTrendsDetailScreen({
    super.key,
    required this.trends,
    required this.selectedPeriod,
  });

  String _formatTrendDate(DateTime date, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.weekly:
      case ReportPeriod.daily:
        return DateFormat('M/d').format(date);
      case ReportPeriod.monthly:
        return DateFormat('MMM').format(date);
      case ReportPeriod.quarterly:
        return 'Q${((date.month - 1) ~/ 3) + 1} ${DateFormat('yy').format(date)}';
      case ReportPeriod.yearly:
        return DateFormat('yyyy').format(date);
      case ReportPeriod.custom:
        return DateFormat('M/d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        title: Text(
          'Expense Trends Details',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: trends.isEmpty
          ? Center(
              child: Text(
                'No expense trend data available.',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Expense Trends',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300, // Increased height for better detail
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1000,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: colorScheme.onSurface.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                      if (value.toInt() < trends.length) {
                                        final trend = trends[value.toInt()];
                                        return SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                            _formatTrendDate(
                                              trend.period,
                                              selectedPeriod,
                                            ),
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1000,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  return Text(
                                    '₦${(value / 1000).toStringAsFixed(0)}k',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 10,
                                    ),
                                  );
                                },
                                reservedSize: 42,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: trends.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.totalExpenses,
                                  color: const Color(0xFF6C5CE7),
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              trends
                                  .map((t) => t.totalExpenses)
                                  .reduce((a, b) => a > b ? a : b) *
                              1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
