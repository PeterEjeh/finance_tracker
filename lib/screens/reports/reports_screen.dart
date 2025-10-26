import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'expense_trends_detail_screen.dart';
import '../../models/report.dart';
import '../../models/category.dart';
import '../../services/analytics_service.dart';
import '../../services/insights_service.dart';
import '../../services/export_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/budget_service.dart'; // Import BudgetService
import '../../models/transaction.dart';
import '../../services/settings_service.dart';
import 'spending_analysis_screen.dart';
import 'budget_performance_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final InsightsService _insightsService =
      InsightsService(); // Make it an instance
  final ExportService _exportService = ExportService();

  ReportPeriod _selectedPeriod = ReportPeriod.monthly;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  SpendingReport? _currentReport;
  List<String> _insights = []; // Changed to List<String>
  List<SpendingTrend> _trends = [];
  FinancialHealthScore? _healthScore;

  late ColorScheme _colorScheme;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId != null) {
        final periodDates = _getPeriodDates(_selectedPeriod, _selectedDate);

        // Generate expense-only report (excludes income)
        final report = _analyticsService.generateExpenseReport(
          userId: userId,
          startDate: periodDates.start,
          endDate: periodDates.end,
          period: _selectedPeriod,
        );

        // Get budget progress for insights
        final allBudgetProgress = await BudgetService.getAllBudgetProgress(
          userId,
        );

        // Get insights
        final insights = _insightsService.getAllBudgetInsights(
          allBudgetProgress,
        );

        // Get expense-only trends
        final trends = _analyticsService.getExpenseTrends(
          userId: userId,
          period: _selectedPeriod,
          periodCount: 6,
        );

        // Get financial health score
        final healthScore = _analyticsService.calculateFinancialHealthScore(
          userId: userId,
        );

        setState(() {
          _currentReport = report;
          _insights = insights;
          _trends = trends;
          _healthScore = healthScore;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report data: $e')),
        );
      }
    }
  }

  ({DateTime start, DateTime end}) _getPeriodDates(
    ReportPeriod period,
    DateTime referenceDate,
  ) {
    switch (period) {
      case ReportPeriod.weekly:
        final weekStart = referenceDate.subtract(
          Duration(days: referenceDate.weekday - 1),
        );
        return (
          start: DateTime(weekStart.year, weekStart.month, weekStart.day),
          end: DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day + 6,
            23,
            59,
            59,
          ),
        );
      case ReportPeriod.monthly:
        return (
          start: DateTime(referenceDate.year, referenceDate.month, 1),
          end: DateTime(
            referenceDate.year,
            referenceDate.month + 1,
            0,
            23,
            59,
            59,
          ),
        );
      case ReportPeriod.quarterly:
        final quarterStartMonth = ((referenceDate.month - 1) ~/ 3) * 3 + 1;
        return (
          start: DateTime(referenceDate.year, quarterStartMonth, 1),
          end: DateTime(
            referenceDate.year,
            quarterStartMonth + 3,
            0,
            23,
            59,
            59,
          ),
        );
      case ReportPeriod.yearly:
        return (
          start: DateTime(referenceDate.year, 1, 1),
          end: DateTime(referenceDate.year, 12, 31, 23, 59, 59),
        );
      default:
        return (
          start: DateTime(referenceDate.year, referenceDate.month, 1),
          end: DateTime(
            referenceDate.year,
            referenceDate.month + 1,
            0,
            23,
            59,
            59,
          ),
        );
    }
  }

  String _formatTrendDate(DateTime date, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.weekly:
      case ReportPeriod.daily: // Although daily is excluded, handle defensively
        return DateFormat('M/d').format(date);
      case ReportPeriod.monthly:
        return DateFormat('MMM').format(date);
      case ReportPeriod.quarterly:
        return 'Q${((date.month - 1) ~/ 3) + 1} ${DateFormat('yy').format(date)}';
      case ReportPeriod.yearly:
        return DateFormat('yyyy').format(date);
      case ReportPeriod.custom:
        return DateFormat('M/d').format(date); // Fallback for custom
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _colorScheme = theme.colorScheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        title: Text(
          'Spending Reports & Insights',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            color: colorScheme.surface,
            onSelected: (value) async {
              switch (value) {
                case 'export_pdf':
                  await _exportReportAsPDF();
                  break;
                case 'export_csv':
                  await _exportReportAsCSV();
                  break;
                case 'refresh':
                  await _loadReportData();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Export as PDF',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Export as CSV',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: colorScheme.onSurface, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Refresh',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  if (_healthScore != null) _buildFinancialHealthCard(),
                  const SizedBox(height: 20),
                  if (_currentReport != null) _buildSummaryCards(),
                  const SizedBox(height: 20),
                  if (_currentReport != null) _buildSpendingChart(),
                  const SizedBox(height: 20),
                  if (_trends.isNotEmpty) _buildTrendsChart(),
                  const SizedBox(height: 20),
                  if (_insights.isNotEmpty) _buildInsightsSection(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Period',
            style: TextStyle(
              color: _colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportPeriod.values
                .where(
                  (p) => p != ReportPeriod.custom && p != ReportPeriod.daily,
                )
                .map((period) {
                  final isSelected = _selectedPeriod == period;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                      _loadReportData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C5CE7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6C5CE7)
                              : _colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        period.displayName,
                        style: TextStyle(
                          color: isSelected
                              ? _colorScheme.onPrimary
                              : _colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard() {
    final score = _healthScore!;
    Color scoreColor;
    if (score.score >= 80) {
      scoreColor = const Color(0xFF00D4AA);
    } else if (score.score >= 60) {
      scoreColor = const Color(0xFF6C5CE7);
    } else if (score.score >= 40) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Health Score',
                style: TextStyle(
                  color: _colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score.healthLevel,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${score.score.toStringAsFixed(0)}/100',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Overall Score',
                      style: TextStyle(
                        color: _colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildHealthMetric(
                      'Savings Rate',
                      '${(score.savingsRate * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 8),
                    if (_healthScore?.hasBudgets ?? false)
                      _buildHealthMetric(
                        'Budget Adherence',
                        '${(score.budgetAdherence * 100).toStringAsFixed(1)}%',
                      )
                    else
                      _buildHealthMetric(
                        'Income-Expense Ratio',
                        '${(score.incomeExpenseRatio * 100).toStringAsFixed(1)}%',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final report = _currentReport!;

    // Calculate consumption expenses (excluding savings)
    final consumptionExpenses = report.categoryBreakdown
        .where((cat) => cat.categoryId != 'expense_savings')
        .fold<double>(0, (sum, cat) => sum + cat.totalAmount);

    // Calculate savings
    final savings = report.categoryBreakdown
        .firstWhere(
          (cat) => cat.categoryId == 'expense_savings',
          orElse: () => CategorySpending(
            categoryId: '',
            categoryName: '',
            categoryIcon: '',
            categoryColor: 0,
            totalAmount: 0,
            transactionCount: 0,
            percentage: 0,
            transactions: [],
          ),
        )
        .totalAmount;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Consumption',
                NumberFormat.currency(symbol: '₦').format(consumptionExpenses),
                Colors.red,
                Icons.shopping_cart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Savings',
                NumberFormat.currency(symbol: '₦').format(savings),
                Colors.blue,
                Icons.savings,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Outflow',
                NumberFormat.currency(symbol: '₦').format(report.totalExpenses),
                Colors.orange,
                Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Transactions',
                '${report.categoryBreakdown.fold<int>(0, (sum, category) => sum + category.transactionCount)}',
                const Color(0xFF6C5CE7),
                Icons.receipt_long,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart() {
    final report = _currentReport!;
    final topCategories = report.categoryBreakdown.take(5).toList();

    if (topCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No spending data available',
            style: TextStyle(color: _colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expenses by Category',
                style: TextStyle(
                  color: _colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_currentReport != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SpendingAnalysisScreen(report: _currentReport!),
                      ),
                    );
                  }
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(color: Color(0xFF6C5CE7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: topCategories.map((category) {
                  return PieChartSectionData(
                    color: Color(category.categoryColor),
                    value: category.totalAmount,
                    title: '',
                    radius: 40,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...topCategories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(category.categoryColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: TextStyle(
                        color: _colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: '₦',
                    ).format(category.totalAmount),
                    style: TextStyle(
                      color: _colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expense Trends',
                style: TextStyle(
                  color: _colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpenseTrendsDetailScreen(
                        trends: _trends,
                        selectedPeriod: _selectedPeriod,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Expand',
                  style: TextStyle(color: Color(0xFF6C5CE7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Check if we have data to display
          _trends.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 48,
                          color: _colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No spending data yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add transactions to see your expense trends',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 150, // Reduced height for simplified view
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: false,
                      ), // Hide grid for simplicity
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
                            reservedSize: 22,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() % 2 == 0 &&
                                  value.toInt() < _trends.length) {
                                final trend = _trends[value.toInt()];
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    _formatTrendDate(
                                      trend.period,
                                      _selectedPeriod,
                                    ),
                                    style: TextStyle(
                                      color: _colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                      fontSize: 9,
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
                            interval: _trends.isNotEmpty
                                ? () {
                                    final maxExpense = _trends
                                        .map((t) => t.totalExpenses)
                                        .reduce((a, b) => a > b ? a : b);
                                    final calculatedInterval = maxExpense / 3;
                                    // Ensure interval is never 0
                                    return calculatedInterval > 0
                                        ? calculatedInterval.toDouble()
                                        : 1.0;
                                  }()
                                : 1.0, // Default interval
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '₦${(value / 1000).toStringAsFixed(0)}k',
                                style: TextStyle(
                                  color: _colorScheme.onSurface.withOpacity(
                                    0.6,
                                  ),
                                  fontSize: 9,
                                ),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_trends.length - 1).toDouble(),
                      minY: 0,
                      maxY: _trends.isNotEmpty
                          ? _trends
                                    .map((t) => t.totalExpenses)
                                    .reduce((a, b) => a > b ? a : b) *
                                1.2
                          : 1000, // Default maxY if no trends
                      lineBarsData: [
                        LineChartBarData(
                          spots: _trends.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.totalExpenses,
                            );
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF6C5CE7),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    final topInsights = _insights.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Insights',
            style: TextStyle(
              color: _colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...topInsights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String insightMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: _colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insightMessage,
              style: TextStyle(color: _colorScheme.onSurface, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: _colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Spending Analysis',
                  Icons.analytics,
                  () {
                    if (_currentReport != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SpendingAnalysisScreen(report: _currentReport!),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Budget Performance',
                  Icons.account_balance_wallet,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetPerformanceScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6C5CE7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6C5CE7), size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReportAsPDF() async {
    if (_currentReport == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
          ),
        ),
      );

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId != null) {
        // Get categories for the export
        final categories = await _getCategories(userId);

        final filePath = await _exportService.exportSpendingReportToPDF(
          report: _currentReport!,
          categories: categories,
        );

        Navigator.pop(context); // Close loading dialog

        await _exportService.showDownloadSuccess(
          filePath: filePath,
          fileType: 'PDF Report',
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
    }
  }

  Future<void> _exportReportAsCSV() async {
    if (_currentReport == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
          ),
        ),
      );

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId != null) {
        // Get all transactions for the period
        final transactions = await _getTransactionsForPeriod(userId);
        final categories = await _getCategories(userId);

        final filePath = await _exportService.exportTransactionsToCSV(
          transactions: transactions,
          categories: categories,
          startDate: _currentReport!.startDate,
          endDate: _currentReport!.endDate,
        );

        Navigator.pop(context); // Close loading dialog

        await _exportService.showDownloadSuccess(
          filePath: filePath,
          fileType: 'CSV Report',
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting CSV: $e')));
    }
  }

  Future<List<Category>> _getCategories(String userId) async {
    final databaseService = DatabaseService.instance;
    return databaseService.getAllCategories(userId: userId);
  }

  Future<List<Transaction>> _getTransactionsForPeriod(String userId) async {
    final databaseService = DatabaseService.instance;
    final periodDates = _getPeriodDates(_selectedPeriod, _selectedDate);
    return databaseService.getTransactionsByDateRange(
      startDate: periodDates.start,
      endDate: periodDates.end,
      userId: userId,
    );
  }
}
