import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/currency.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/export_service.dart';
import '../../services/analytics_service.dart';
import '../../services/budget_service.dart';
import 'add_budget_screen.dart';
import 'budget_details_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  bool _isBuildingCard = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId != null) {
        final budgets = _databaseService.getAllBudgets(userId: userId);
        final categories = _databaseService.getAllCategories(userId: userId);

        setState(() {
          _budgets = budgets;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading budgets: $e')));
      }
    }
  }

  List<Budget> get _filteredBudgets {
    switch (_selectedFilter) {
      case 'Active':
        return _budgets
            .where((budget) => budget.isActive && budget.isCurrentPeriod)
            .toList();
      case 'Inactive':
        return _budgets.where((budget) => !budget.isActive).toList();
      case 'Over Budget':
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser?.uid;
        return _budgets
            .where(
              (budget) => _databaseService.isBudgetOverLimit(
                budget: budget,
                userId: userId,
              ),
            )
            .toList();
      default:
        return _budgets;
    }
  }

  String _getCategoryName(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(
        id: '',
        name: 'Unknown',
        icon: '❓',
        colorValue: Colors.grey.value,
        type: CategoryType.expense,
        userId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.name;
  }

  Color _getCategoryColor(String categoryId) {
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(
        id: '',
        name: 'Unknown',
        icon: '❓',
        colorValue: Colors.grey.value,
        type: CategoryType.expense,
        userId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return category.color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Budgets', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'filter_all':
                  setState(() => _selectedFilter = 'All');
                  break;
                case 'filter_active':
                  setState(() => _selectedFilter = 'Active');
                  break;
                case 'filter_inactive':
                  setState(() => _selectedFilter = 'Inactive');
                  break;
                case 'filter_over':
                  setState(() => _selectedFilter = 'Over Budget');
                  break;
                case 'export_csv':
                  await _exportBudgetsCSV();
                  break;
                case 'export_pdf':
                  await _exportBudgetsPDF();
                  break;
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Theme.of(context).colorScheme.surface,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'filter_all', child: Text('All Budgets')),
              PopupMenuItem(value: 'filter_active', child: Text('Active')),
              PopupMenuItem(value: 'filter_inactive', child: Text('Inactive')),
              PopupMenuItem(value: 'filter_over', child: Text('Over Budget')),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'export_csv',
                child: Text('Export Budgets (CSV)'),
              ),
              PopupMenuItem(
                value: 'export_pdf',
                child: Text('Export Budget Report (PDF)'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : _buildBudgetsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Future<void> _exportBudgetsCSV() async {
    try {
      if (_budgets.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No budgets to export')));
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final exportService = ExportService();
      final path = await exportService.exportBudgetsToCSV(
        budgets: _budgets,
        categories: _categories,
      );
      if (mounted) Navigator.pop(context);
      await exportService.showDownloadSuccess(
        context: context,
        filePath: path,
        fileType: 'CSV Export',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting budgets: $e')));
    }
  }

  Future<void> _exportBudgetsPDF() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId == null) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final analytics = AnalyticsService();
      final exportService = ExportService();
      final reports = analytics.getBudgetPerformanceReports(userId: userId);
      final path = await exportService.exportBudgetReportToPDF(
        budgetReports: reports,
        reportDate: DateTime.now(),
      );
      if (mounted) Navigator.pop(context);
      await exportService.showDownloadSuccess(
        context: context,
        filePath: path,
        fileType: 'PDF Report',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting report: $e')));
    }
  }

  Future<Map<String, dynamic>> _getBudgetProgress(String budgetId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid ?? '';
    return await BudgetService.getBudgetProgress(budgetId, userId);
  }

  Widget _buildBudgetsList() {
    final filteredBudgets = _filteredBudgets;

    if (filteredBudgets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'All'
                  ? 'No budgets yet'
                  : 'No ${_selectedFilter.toLowerCase()} budgets',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first budget to start tracking your spending',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_selectedFilter != 'All')
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Showing $_selectedFilter',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'All';
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBudgets.length,
            itemBuilder: (context, index) {
              final budget = filteredBudgets[index];
              return _buildBudgetCard(budget);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    if (_isBuildingCard) return Container();
    _isBuildingCard = true;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getBudgetProgress(budget.id),
      builder: (context, snapshot) {
        _isBuildingCard = false;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Error loading budget')),
            ),
          );
        }

        final budgetProgress = snapshot.data!;
        final totalSpent = budgetProgress['totalSpent'] as double;
        final remaining = budgetProgress['remaining'] as double;
        final spentPercentage = budgetProgress['spentPercentage'] as double;
        final isOverBudget = budgetProgress['isOverBudget'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BudgetDetailsScreen(budget: budget),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(budget.categoryId),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget.name,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _getCategoryName(budget.categoryId),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOverBudget)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Over Budget',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              budget.currency.formatAmount(totalSpent),
                              style: TextStyle(
                                color: isOverBudget
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              budget.currency.formatAmount(
                                remaining.clamp(0, budget.amount),
                              ),
                              style: TextStyle(
                                color: remaining > 0
                                    ? const Color(0xFF00D4AA)
                                    : Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(spentPercentage * 100).toStringAsFixed(1)}% used',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              budget.currency.formatAmount(budget.amount),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: spentPercentage.clamp(0.0, 1.0),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget
                                  ? Colors.red
                                  : const Color(0xFF00D4AA),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${budget.period.name.toUpperCase()} • ${budget.daysRemaining} days left',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (!budget.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'INACTIVE',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
