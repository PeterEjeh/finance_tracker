import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/analytics_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/report.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/currency.dart';
import '../services/currency_settings_service.dart';

class AnalyticsSnippet extends StatefulWidget {
  const AnalyticsSnippet({super.key});

  // Static method to refresh all AnalyticsSnippet instances
  static void refreshAll() {
    _refreshController?.add(null);
  }

  @override
  State<AnalyticsSnippet> createState() => _AnalyticsSnippetState();
}

// Static controller for global refresh
StreamController<void>? _refreshController;

class _AnalyticsSnippetState extends State<AnalyticsSnippet> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  SpendingReport? _currentMonthReport;
  List<SpendingTrend> _spendingTrends = [];
  List<CategorySpending> _topCategories = [];
  PeriodComparison? _periodComparison;
  bool _isLoading = true;

  // Stream controller for real-time updates
  StreamController<void> _refreshController =
      StreamController<void>.broadcast();
  StreamSubscription? _dataSubscription;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _refreshController?.close();
    _dataSubscription?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }

  void _setupRealTimeUpdates() {
    // Initialize static controller if not already done
    _refreshController ??= StreamController<void>.broadcast();

    // Listen for refresh triggers from external sources
    _dataSubscription = _refreshController!.stream.listen((_) {
      _loadAnalyticsData();
    });

    // Set up periodic refresh every 30 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadAnalyticsData();
      }
    });
  }

  void refreshData() {
    _refreshController?.add(null);
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';

      if (!DatabaseService.instance.isInitialized) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current month's data
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Generate current month expense report (expenses only)
      _currentMonthReport = _analyticsService.generateExpenseReport(
        userId: userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
        period: ReportPeriod.monthly,
      );

      // Get expense trends (last 3 months for snippet) - expenses only
      _spendingTrends = _analyticsService.getExpenseTrends(
        userId: userId,
        period: ReportPeriod.monthly,
        periodCount: 3,
      );

      // Get top expense categories (expenses only)
      _topCategories = _analyticsService.getTopExpenseCategories(
        userId: userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
        limit: 3,
      );

      // Get period comparison (current vs previous month) - expenses only
      final previousMonthStart = DateTime(now.year, now.month - 1, 1);
      final previousMonthEnd = DateTime(now.year, now.month, 0);
      _periodComparison = _analyticsService.compareExpensePeriods(
        userId: userId,
        currentStart: startOfMonth,
        currentEnd: endOfMonth,
        previousStart: previousMonthStart,
        previousEnd: previousMonthEnd,
      );
    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with View All button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full analytics screen
                Navigator.pushNamed(context, '/reports');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Monthly Summary and Comparison
        if (_currentMonthReport != null && _periodComparison != null)
          _buildSpendingSummaryAndComparison(),

        const SizedBox(height: 16),

        // Mini Charts Row
        if (_currentMonthReport != null && _spendingTrends.isNotEmpty)
          _buildMiniChartsRow(),

        const SizedBox(height: 16),

        // Top Categories
        if (_topCategories.isNotEmpty) _buildTopCategoriesMini(),
      ],
    );
  }

  Widget _buildSpendingSummaryAndComparison() {
    final report = _currentMonthReport!;
    final comparison = _periodComparison!;

    return Row(
      children: [
        // Monthly Spending Summary
        Expanded(
          child: _buildMiniSummaryCard(
            title: 'This Month',
            amount: report.totalExpenses,
            subtitle: 'Total Spending',
          ),
        ),
        const SizedBox(width: 12),
        // Period Comparison
        Expanded(child: _buildMiniComparisonCard(comparison)),
      ],
    );
  }

  Widget _buildMiniSummaryCard({
    required String title,
    required double amount,
    required String subtitle,
  }) {
    final settings = Provider.of<CurrencySettingsService>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1F3A)
            : Colors.white,
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
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF666666),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount, settings.baseCurrency.code),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2C2C2C),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.6)
                  : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniComparisonCard(PeriodComparison comparison) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1F3A)
            : Colors.white,
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
          Text(
            'vs Last Month',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF666666),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                comparison.expenseChange >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: comparison.expenseChange >= 0
                    ? Colors.red
                    : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${comparison.expenseChangePercentage.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: comparison.expenseChange >= 0
                      ? Colors.red
                      : Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            comparison.expenseChange >= 0 ? 'Increase' : 'Decrease',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.6)
                  : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChartsRow() {
    return Row(
      children: [
        // Mini Pie Chart for Expense Distribution
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
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
                Text(
                  'Top Spending Categories',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                      sections: _topCategories.take(3).map((category) {
                        return PieChartSectionData(
                          color: Color(category.categoryColor),
                          value: category.totalAmount,
                          title: '',
                          radius: 20,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Mini Bar Graph for Spending Trends
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
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
                Text(
                  'Trend',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2C2C2C),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _spendingTrends.isNotEmpty
                          ? _spendingTrends
                                    .map((t) => t.totalExpenses)
                                    .reduce((a, b) => a > b ? a : b) *
                                1.2
                          : 1000,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: _spendingTrends
                          .take(3)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.totalExpenses,
                                  color: const Color(0xFF6C5CE7),
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                ),
                              ],
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategoriesMini() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1F3A)
            : Colors.white,
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
          Text(
            'Top Spending Categories',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF2C2C2C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._topCategories.take(3).map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(category.categoryColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _formatCurrency(category.totalAmount, 'NGN'),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF2C2C2C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, String currencyCode) {
    final settings = Provider.of<CurrencySettingsService>(
      context,
      listen: false,
    );

    final currency = SupportedCurrencies.getCurrency(currencyCode);
    if (currency != null) {
      return settings.formatAmount(amount, currency: currency);
    }

    // Fallback for unknown currency
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 2);
    return '${formatter.format(amount).trim()} $currencyCode';
  }
}
