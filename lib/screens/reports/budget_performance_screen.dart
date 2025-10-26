import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
// import '../../models/budget.dart';
// import '../../models/category.dart';
import '../../models/report.dart';
import '../../services/analytics_service.dart';
// import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class BudgetPerformanceScreen extends StatefulWidget {
  const BudgetPerformanceScreen({super.key});

  @override
  State<BudgetPerformanceScreen> createState() =>
      _BudgetPerformanceScreenState();
}

class _BudgetPerformanceScreenState extends State<BudgetPerformanceScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  // final DatabaseService _databaseService = DatabaseService.instance;

  List<BudgetPerformanceReport> _budgetReports = [];
  // List<Category> _categories = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadBudgetPerformance();
  }

  Future<void> _loadBudgetPerformance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId != null) {
        final budgetReports = _analyticsService.getBudgetPerformanceReports(
          userId: userId,
          tolerancePercentage: 0.1, // 10% tolerance as default
        );
        // Load categories if needed in the future
        // final categories = _databaseService.getAllCategories(userId: userId);

        setState(() {
          _budgetReports = budgetReports;
          // _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget performance: $e')),
        );
      }
    }
  }

  List<BudgetPerformanceReport> get _filteredReports {
    switch (_selectedFilter) {
      case 'On Track':
        return _budgetReports
            .where((r) => r.status == BudgetPerformanceStatus.onTrack)
            .toList();
      case 'Over Budget':
        return _budgetReports
            .where((r) => r.status == BudgetPerformanceStatus.overBudget)
            .toList();
      case 'Under Budget':
        return _budgetReports
            .where((r) => r.status == BudgetPerformanceStatus.underBudget)
            .toList();
      default:
        return _budgetReports;
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Budget Performance',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: colorScheme.onSurface),
            color: colorScheme.surface,
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Text(
                  'All Budgets',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'On Track',
                child: Text(
                  '🔵 On Track',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'Over Budget',
                child: Text(
                  '🔴 Over Budget',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'Under Budget',
                child: Text(
                  '🟢 Under Budget',
                  style: TextStyle(color: Colors.white),
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
              onRefresh: _loadBudgetPerformance,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_budgetReports.isNotEmpty) ...[
                    _buildOverallSummary(),
                    const SizedBox(height: 20),
                    _buildPerformanceChart(),
                    const SizedBox(height: 20),
                  ],
                  _buildFilterChips(),
                  const SizedBox(height: 20),
                  _buildBudgetsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallSummary() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalBudgeted = _budgetReports.fold<double>(
      0,
      (sum, report) => sum + report.budgetAmount,
    );
    final totalSpent = _budgetReports.fold<double>(
      0,
      (sum, report) => sum + report.actualSpent,
    );
    final onTrackCount = _budgetReports
        .where((r) => r.status == BudgetPerformanceStatus.onTrack)
        .length;
    final overBudgetCount = _budgetReports
        .where((r) => r.status == BudgetPerformanceStatus.overBudget)
        .length;
    final underBudgetCount = _budgetReports
        .where((r) => r.status == BudgetPerformanceStatus.underBudget)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Performance',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Budgeted',
                  NumberFormat.currency(symbol: '₦').format(totalBudgeted),
                  const Color(0xFF6C5CE7),
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Spent',
                  NumberFormat.currency(symbol: '₦').format(totalSpent),
                  Colors.orange,
                  Icons.money_off,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'On Track',
                  '$onTrackCount/${_budgetReports.length}',
                  const Color(0xFF00D4AA),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Over Budget',
                  '$overBudgetCount',
                  Colors.red,
                  Icons.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Under Budget',
                  '$underBudgetCount',
                  const Color(0xFF6C5CE7),
                  Icons.thumb_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
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

  Widget _buildPerformanceChart() {
    if (_budgetReports.isEmpty) return const SizedBox();

    final chartData = _budgetReports.take(6).map((report) {
      return BarChartGroupData(
        x: _budgetReports.indexOf(report),
        barRods: [
          BarChartRodData(
            toY: report.budgetAmount,
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: report.actualSpent,
            color: _getStatusColor(report.status),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget vs Actual Spending',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    _budgetReports
                        .map((r) => r.budgetAmount)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() < _budgetReports.length) {
                          final report = _budgetReports[value.toInt()];
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              report.categoryName.length > 8
                                  ? '${report.categoryName.substring(0, 8)}...'
                                  : report.categoryName,
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 10,
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '₦${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 10,
                          ),
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
                borderData: FlBorderData(show: false),
                barGroups: chartData,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                'Budgeted',
                const Color(0xFF6C5CE7).withOpacity(0.3),
              ),
              const SizedBox(width: 20),
              _buildLegendItem('Actual', const Color(0xFF6C5CE7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filters = ['All', 'On Track', 'Over Budget', 'Under Budget'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFilter = filter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF6C5CE7) : colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C5CE7)
                    : colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            child: Text(
              filter == 'On Track'
                  ? '🔵 On Track'
                  : filter == 'Over Budget'
                  ? '🔴 Over Budget'
                  : filter == 'Under Budget'
                  ? '🟢 Under Budget'
                  : filter,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetsList() {
    final filteredReports = _filteredReports;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (filteredReports.isEmpty) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 60,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedFilter == 'All'
                    ? 'No budgets found'
                    : 'No ${_selectedFilter.toLowerCase()} budgets',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create budgets to track your spending performance',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Details (${filteredReports.length})',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...filteredReports.map((report) => _buildBudgetCard(report)),
      ],
    );
  }

  Widget _buildBudgetCard(BudgetPerformanceReport report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progress = report.budgetAmount > 0
        ? report.actualSpent / report.budgetAmount
        : 0.0;
    final statusColor = _getStatusColor(report.status);
    final statusText = _getStatusText(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.budgetName,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      report.categoryName,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: '₦',
                    ).format(report.actualSpent),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: '₦',
                    ).format(report.budgetAmount),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: '₦',
                    ).format(report.variance.clamp(0, report.budgetAmount)),
                    style: TextStyle(
                      color: report.variance > 0
                          ? const Color(0xFF00D4AA)
                          : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).clamp(0, 100).toStringAsFixed(1)}% used',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${report.daysRemaining} days left',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily avg: ${NumberFormat.currency(symbol: '₦').format(report.dailyAverageSpent)}',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                'Projected: ${NumberFormat.currency(symbol: '₦').format(report.projectedSpending)}',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BudgetPerformanceStatus status) {
    switch (status) {
      case BudgetPerformanceStatus.onTrack:
        return const Color(0xFF00D4AA); // Green for On Track
      case BudgetPerformanceStatus.warning:
        return Colors.orange; // Orange for Warning (if still used)
      case BudgetPerformanceStatus.overBudget:
        return Colors.red; // Red for Over Budget
      case BudgetPerformanceStatus.underBudget:
        return const Color(0xFF6C5CE7); // Purple for Under Budget
    }
  }

  String _getStatusText(BudgetPerformanceStatus status) {
    switch (status) {
      case BudgetPerformanceStatus.onTrack:
        return '🔵 On Track';
      case BudgetPerformanceStatus.warning:
        return 'Warning'; // Keep for backward compatibility
      case BudgetPerformanceStatus.overBudget:
        return '🔴 Over Budget';
      case BudgetPerformanceStatus.underBudget:
        return '🟢 Under Budget';
    }
  }
}
