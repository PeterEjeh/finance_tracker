import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import 'add_budget_screen.dart';
import '../../widgets/budget_details/budget_widgets.dart';

class BudgetDetailsScreen extends StatefulWidget {
  final Budget budget;

  const BudgetDetailsScreen({super.key, required this.budget});

  @override
  State<BudgetDetailsScreen> createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends State<BudgetDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  late Budget _budget;
  Category? _category;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authService = context.read<AuthService>();
      _userId = authService.currentUser?.uid ?? '';
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Get budget data
      if (_budget.categoryId.isNotEmpty) {
        _category = _databaseService.getCategory(_budget.categoryId);
      }

      // Get transactions for this budget period and category
      _transactions = _databaseService
          .getTransactionsByDateRange(
            startDate: _budget.startDate,
            endDate: _budget.endDate,
            userId: _userId,
          )
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                t.categoryId == _budget.categoryId,
          )
          .toList();

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budget details: $e')),
      );
    }
  }

  Future<void> _editBudget() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddBudgetScreen(budget: _budget)),
    );

    if (result == true && mounted) {
      final updatedBudget = _databaseService.getBudget(_budget.id);
      if (updatedBudget != null) {
        setState(() {
          _budget = updatedBudget;
        });
        _loadData();
      }
    }
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text('Delete Budget'),
        content: Text(
          'Are you sure you want to delete "${_budget.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _databaseService.deleteBudget(_budget.id);
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting budget: $e')));
      }
    }
  }

  Future<void> _toggleBudgetStatus() async {
    if (!mounted) return;
    try {
      final updatedBudget = _budget.copyWith(isActive: !_budget.isActive);
      await _databaseService.updateBudget(updatedBudget);
      setState(() {
        _budget = updatedBudget;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating budget status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: BudgetService.getBudgetProgress(_budget.id, _userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(_budget.name, style: theme.textTheme.titleLarge),
            ),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(_budget.name, style: theme.textTheme.titleLarge),
            ),
            body: Center(
              child: Text(
                'Error loading budget data',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          );
        }

        final budgetProgress = snapshot.data!;
        final totalSpent = budgetProgress['totalSpent'] as double;
        final remaining = budgetProgress['remaining'] as double;
        final spentPercentage = budgetProgress['spentPercentage'] as double;
        final isOverBudget = budgetProgress['isOverBudget'] as bool;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(_budget.name, style: theme.textTheme.titleLarge),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                color: theme.popupMenuTheme.color,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editBudget();
                      break;
                    case 'toggle':
                      _toggleBudgetStatus();
                      break;
                    case 'delete':
                      _deleteBudget();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 20,
                          color: theme.iconTheme.color,
                        ),
                        const SizedBox(width: 12),
                        Text('Edit Budget', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          _budget.isActive ? Icons.pause : Icons.play_arrow,
                          size: 20,
                          color: theme.iconTheme.color,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _budget.isActive ? 'Pause Budget' : 'Activate Budget',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Delete Budget',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              BudgetOverviewWidget(
                spent: totalSpent,
                remaining: remaining,
                progress: spentPercentage,
                isOverBudget: isOverBudget,
                shouldAlert: false,
                budget: _budget,
                category: _category,
              ),
              const SizedBox(height: 24),
              BudgetProgressWidget(
                progress: spentPercentage,
                isOverBudget: isOverBudget,
                shouldAlert: false,
              ),
              const SizedBox(height: 24),
              BudgetInfoWidget(budget: _budget),
              const SizedBox(height: 24),
              TransactionsListWidget(
                transactions: _transactions,
                category: _category,
              ),
            ],
          ),
        );
      },
    );
  }
}
