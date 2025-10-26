import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/budget.dart';
import '../../models/currency.dart';
import '../../models/savings_goal.dart';
import '../../services/budget_alert_service.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../budgets/budgets_screen.dart';
import '../savings/savings_goals_screen.dart';
import '../../services/settings_service.dart';
import '../settings/settings_screen.dart';
import '../../services/currency_settings_service.dart';

import '../../widgets/analytics_snippet.dart';
import '../../services/dashboard_personalization_service.dart';
import '../../widgets/skeleton_loader.dart';

// Removed GlobalKey - using static method for refresh instead

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();
  final DashboardPersonalizationService _personalizationService =
      DashboardPersonalizationService();
  String? _username;
  String? _personalizedGreeting;
  List<String> _personalizedTips = [];
  List<QuickAction> _quickActions = [];

  List<Transaction> _recentTransactions = [];
  List<Category> _categories = [];
  List<Budget> _activeBudgets = [];
  List<BudgetAlert> _budgetAlerts = [];
  BudgetSummary? _budgetSummary;
  List<SavingsGoal> _savingsGoals = [];
  List<SavingsGoal> _activeSavingsGoals = [];
  List<SavingsGoal> _completedSavingsGoals = [];
  List<SavingsGoal> _overdueSavingsGoals = [];
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _balance = 0.0;
  double _allTimeIncome = 0.0;
  double _allTimeExpenses = 0.0;
  double _allTimeBalance = 0.0;
  bool _isAllTimeView = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';
      _username = await SettingsService().getUsername();

      // Load personalized content
      _personalizedGreeting = await _personalizationService
          .getPersonalizedGreeting();
      _personalizedTips = await _personalizationService.getPersonalizedTips();
      _quickActions = await _personalizationService
          .getPrioritizedQuickActions();

      // Check if database service is initialized
      if (!DatabaseService.instance.isInitialized) {
        print('⚠️ Database service not initialized - using default values');
        // Set safe defaults when database is not available
        _categories = [];
        _recentTransactions = [];
        _activeBudgets = [];
        _budgetAlerts = [];
        _budgetSummary = null;
        _savingsGoals = [];
        _activeSavingsGoals = [];
        _completedSavingsGoals = [];
        _overdueSavingsGoals = [];
        _totalIncome = 0.0;
        _totalExpenses = 0.0;
        _balance = 0.0;
        _allTimeIncome = 0.0;
        _allTimeExpenses = 0.0;
        _allTimeBalance = 0.0;
        // Analytics variables removed - now handled by AnalyticsSnippet widget
        return;
      }

      // Initialize default categories if none exist
      await _databaseService.initializeDefaultCategories(userId);

      // Get current month's data
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Load transactions for current month (potentially used for future widgets)
      final _ = _databaseService.getTransactionsByDateRange(
        startDate: startOfMonth,
        endDate: endOfMonth,
        userId: userId,
      );

      // Get recent transactions (last 5)
      final allTransactions = _databaseService.getAllTransactions(
        userId: userId,
      );
      _recentTransactions = allTransactions.take(5).toList();

      // Load categories
      _categories = _databaseService.getAllCategories(userId: userId);

      // Load active budgets
      _activeBudgets = _databaseService.getActiveBudgets(userId: userId);

      // Load budget alerts and summary
      final alertService = BudgetAlertService();
      _budgetAlerts = await alertService.getAllAlerts(userId: userId);
      _budgetSummary = await alertService.getBudgetSummary(userId: userId);

      // Load savings goals
      _savingsGoals = _databaseService.getAllSavingsGoals(userId: userId);
      _activeSavingsGoals = _databaseService.getActiveSavingsGoals(
        userId: userId,
      );
      _completedSavingsGoals = _databaseService.getCompletedSavingsGoals(
        userId: userId,
      );
      _overdueSavingsGoals = _databaseService.getOverdueSavingsGoals(
        userId: userId,
      );

      // Calculate totals for current month with error handling
      try {
        _totalIncome = await _databaseService.getTotalAmount(
          type: TransactionType.income,
          startDate: startOfMonth,
          endDate: endOfMonth,
          userId: userId,
        );

        _totalExpenses = await _databaseService.getTotalAmount(
          type: TransactionType.expense,
          startDate: startOfMonth,
          endDate: endOfMonth,
          userId: userId,
        );

        _balance = _totalIncome - _totalExpenses;

        // Calculate all-time totals
        _allTimeIncome = await _databaseService.getTotalAmount(
          type: TransactionType.income,
          userId: userId,
        );

        _allTimeExpenses = await _databaseService.getTotalAmount(
          type: TransactionType.expense,
          userId: userId,
        );

        _allTimeBalance = _allTimeIncome - _allTimeExpenses;
      } catch (e) {
        print('❌ Failed to calculate totals: $e');
        _totalIncome = 0.0;
        _totalExpenses = 0.0;
        _balance = 0.0;
        _allTimeIncome = 0.0;
        _allTimeExpenses = 0.0;
        _allTimeBalance = 0.0;
      }

      // Analytics data removed - now handled by AnalyticsSnippet widget
    } catch (e) {
      print('Error loading dashboard data: $e');
      // Set safe defaults for all fields
      _categories = [];
      _recentTransactions = [];
      _activeBudgets = [];
      _budgetAlerts = [];
      _budgetSummary = null;
      _savingsGoals = [];
      _activeSavingsGoals = [];
      _completedSavingsGoals = [];
      _overdueSavingsGoals = [];
      _totalIncome = 0.0;
      _totalExpenses = 0.0;
      _balance = 0.0;
      _allTimeIncome = 0.0;
      _allTimeExpenses = 0.0;
      _allTimeBalance = 0.0;
      // Set safe defaults for personalization
      _personalizedGreeting = null;
      _personalizedTips = [];
      _quickActions = [];
      // Analytics data removed - now handled by AnalyticsSnippet widget
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on a large screen (web/tablet)
        final isLargeScreen = constraints.maxWidth > 800;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _personalizedGreeting ??
                      'Good ${_getGreeting()}${(_username != null && _username!.trim().isNotEmpty) ? ', ${_username!.trim()}' : ''}!',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 18 : 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : const Color(0xFF666666),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (!(_username != null && _username!.trim().isNotEmpty))
                  Text(
                    _authService.currentUser?.email?.split('@')[0] ?? 'User',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 24 : 20,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF2C2C2C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF2C2C2C),
                    ),
                    onPressed: () {
                      _showBudgetAlerts();
                    },
                  ),
                  if (_budgetAlerts.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color:
                              _budgetAlerts.any(
                                (alert) => alert.severity == AlertSeverity.high,
                              )
                              ? Colors.red
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${_budgetAlerts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF2C2C2C),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _isLoading
              ? FinanceSkeletonLoader.buildDashboardSkeleton(context)
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? 32.0 : 16.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Balance Card
                          _buildBalanceCard(),

                          const SizedBox(height: 24),

                          // Income/Expense Summary - Responsive layout
                          if (isLargeScreen)
                            _buildSummaryCardsLarge()
                          else
                            _buildSummaryCards(),

                          const SizedBox(height: 24),

                          // Summary Cards Row for Large Screens
                          if (isLargeScreen) ...[
                            _buildSummaryCardsRow(),
                            const SizedBox(height: 24),
                          ],

                          // Personalized Tips Section
                          if (_personalizedTips.isNotEmpty) ...[
                            _buildPersonalizedTips(),
                            const SizedBox(height: 24),
                          ],

                          // Quick Actions - Responsive layout
                          if (isLargeScreen)
                            _buildQuickActionsLarge()
                          else
                            _buildQuickActions(),

                          const SizedBox(height: 24),

                          // Analytics Dashboard
                          const AnalyticsSnippet(),

                          const SizedBox(height: 24),

                          // Budget Overview
                          _buildBudgetOverview(),

                          const SizedBox(height: 24),

                          // Recent Transactions and Categories - Side by side on large screens
                          if (isLargeScreen)
                            _buildTransactionsAndCategoriesRow()
                          else ...[
                            _buildRecentTransactions(),
                            const SizedBox(height: 24),
                            _buildCategoriesOverview(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildBalanceCard() {
    final settings = Provider.of<CurrencySettingsService>(context);
    final balanceToShow = _isAllTimeView ? _allTimeBalance : _balance;
    final periodText = _isAllTimeView
        ? 'All Time'
        : 'This Month • ${DateFormat('MMMM yyyy').format(DateTime.now())}';

    return GestureDetector(
      onTap: () {
        setState(() {
          _isAllTimeView = !_isAllTimeView;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFF404040)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Balance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(balanceToShow, settings.baseCurrency.code),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              periodText,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final incomeToShow = _isAllTimeView ? _allTimeIncome : _totalIncome;
    final expensesToShow = _isAllTimeView ? _allTimeExpenses : _totalExpenses;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Income',
            amount: incomeToShow,
            color: Colors.green,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Expenses',
            amount: expensesToShow,
            color: Colors.red,
            icon: Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCardsLarge() {
    final incomeToShow = _isAllTimeView ? _allTimeIncome : _totalIncome;
    final expensesToShow = _isAllTimeView ? _allTimeExpenses : _totalExpenses;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildSummaryCard(
            title: 'Income',
            amount: incomeToShow,
            color: Colors.green,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildSummaryCard(
            title: 'Expenses',
            amount: expensesToShow,
            color: Colors.red,
            icon: Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCardsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget Summary Card
        if (_budgetSummary != null && _budgetSummary!.totalBudgets > 0)
          Expanded(child: _buildBudgetSummaryCard()),

        if (_budgetSummary != null && _budgetSummary!.totalBudgets > 0)
          const SizedBox(width: 24),

        // Savings Goals Summary Card
        if (_savingsGoals.isNotEmpty)
          Expanded(child: _buildSavingsGoalsSummaryCard()),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final settings = Provider.of<CurrencySettingsService>(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
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
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(amount, settings.baseCurrency.code),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Personalized Tips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: _personalizedTips
                .map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 12.0, // Horizontal spacing between cards
            runSpacing: 12.0, // Vertical spacing between rows of cards
            children: _quickActions.take(4).map((action) {
              return _buildQuickActionCard(
                title: action.title,
                icon: action.icon,
                color: action.color,
                onTap: () => _handleQuickAction(action.title),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsLarge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: _quickActions.take(4).map((action) {
            return _buildQuickActionCardLarge(
              title: action.title,
              icon: action.icon,
              color: action.color,
              onTap: () => _handleQuickAction(action.title),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _handleQuickAction(String title) async {
    switch (title) {
      case 'Add Transaction':
      case 'Add Income':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const AddTransactionScreen(initialType: TransactionType.income),
          ),
        );
        if (result == true) {
          _loadDashboardData();
          AnalyticsSnippet.refreshAll();
        }
        break;
      case 'Add Expense':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddTransactionScreen(
              initialType: TransactionType.expense,
            ),
          ),
        );
        if (result == true) {
          _loadDashboardData();
          AnalyticsSnippet.refreshAll();
        }
        break;
      case 'Budgets':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetsScreen()),
        );
        break;
      case 'Savings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SavingsGoalsScreen()),
        );
        break;
      case 'Business Expenses':
        // Navigate to business expense screen (could be a filtered transaction screen)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddTransactionScreen(
              initialType: TransactionType.expense,
            ),
          ),
        );
        break;
      case 'Education Savings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SavingsGoalsScreen()),
        );
        break;
      case 'Investment':
        // Could navigate to investment tracking or show a dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investment tracking coming soon!')),
        );
        break;
      case 'Budget Review':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetsScreen()),
        );
        break;
      case 'Emergency Fund':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SavingsGoalsScreen()),
        );
        break;
      case 'Debt Payment':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddTransactionScreen(
              initialType: TransactionType.expense,
            ),
          ),
        );
        break;
      case 'Reports':
        // Navigate to analytics/reports screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports screen coming soon!')),
        );
        break;
      default:
        // Default action
        break;
    }
  }

  Widget _buildTransactionsAndCategoriesRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildRecentTransactions()),
        const SizedBox(width: 24),
        Expanded(flex: 2, child: _buildCategoriesOverview()),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 90, minWidth: 48),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1F3A)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.9)
                    : const Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCardLarge({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1F3A)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1F3A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first transaction to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = _recentTransactions[index];
                final category = _categories.firstWhere(
                  (c) => c.id == transaction.categoryId,
                  orElse: () => Category.create(
                    name: 'Unknown',
                    icon: 'help_outline',
                    color: Colors.grey,
                    type: CategoryType.expense,
                    userId: '',
                  ),
                );

                final settings = Provider.of<CurrencySettingsService>(
                  context,
                  listen: false,
                );

                // Prefer original amount/currency when the transaction is multi-currency
                final hasOriginal =
                    transaction.originalAmount != null &&
                    transaction.originalCurrencyCode != null;
                final sourceAmount = hasOriginal
                    ? transaction
                          .originalAmount! // amount in original currency (e.g., EUR)
                    : transaction.amount; // stored amount
                final sourceCurrencyCode = hasOriginal
                    ? transaction.originalCurrencyCode!
                    : transaction.currencyCode;

                final isBaseCurrency =
                    sourceCurrencyCode == settings.baseCurrency.code;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.color.withOpacity(0.1),
                    child: Icon(
                      _getIconData(category.icon),
                      color: category.color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  trailing: FutureBuilder<String>(
                    future: settings.formatAmountInBaseCurrency(
                      sourceAmount,
                      sourceCurrencyCode,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      final formattedAmount =
                          snapshot.data ??
                          // Fallback: format the source amount using its currency
                          _formatCurrency(sourceAmount, sourceCurrencyCode);
                      return Text(
                        '${transaction.type == TransactionType.income ? '+' : '-'}$formattedAmount',
                        style: TextStyle(
                          color: transaction.type == TransactionType.income
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                  // Show date and, when enabled, the original/foreign amount
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(transaction.date),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      // If the source currency is not the base currency and user wants to see exchange rates,
                      // show the original/foreign amount under the title.
                      if (!isBaseCurrency && settings.showExchangeRates)
                        Text(
                          _formatCurrency(sourceAmount, sourceCurrencyCode),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategoriesOverview() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getSortedTopExpenseCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final topCategories = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topCategories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = topCategories[index]['category'] as Category;
                  final categoryTotal = topCategories[index]['total'] as double;
                  final settings = Provider.of<CurrencySettingsService>(
                    context,
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.1),
                      child: Icon(
                        _getIconData(category.icon),
                        color: category.color,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Text(
                      _formatCurrency(
                        categoryTotal,
                        settings.baseCurrency.code,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.7)
                            : const Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getSortedTopExpenseCategories() async {
    final userId = _authService.currentUser?.uid ?? '';
    final expenseCategories = _categories.where(
      (c) => c.type == CategoryType.expense,
    );

    final List<Map<String, dynamic>> categoriesWithTotals = [];

    for (final category in expenseCategories) {
      final total = await _databaseService.getTotalAmount(
        categoryId: category.id,
        type: TransactionType.expense,
        userId: userId,
      );
      categoriesWithTotals.add({'category': category, 'total': total});
    }

    categoriesWithTotals.sort(
      (a, b) => (b['total'] as double).compareTo(a['total'] as double),
    );

    return categoriesWithTotals.take(4).toList();
  }

  Widget _buildBudgetOverview() {
    if (_activeBudgets.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Overview',
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BudgetsScreen(),
                    ),
                  );
                },
                child: const Text('Create Budget'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
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
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active budgets',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first budget to track spending',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Overview',
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BudgetsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activeBudgets.length > 3 ? 3 : _activeBudgets.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final budget = _activeBudgets[index];
              final category = _categories.firstWhere(
                (c) => c.id == budget.categoryId,
                orElse: () => Category.create(
                  name: 'Unknown',
                  icon: 'help_outline',
                  color: Colors.grey,
                  type: CategoryType.expense,
                  userId: '',
                ),
              );

              final userId = _authService.currentUser?.uid ?? '';
              final spent = _databaseService.getBudgetSpent(
                budget: budget,
                userId: userId,
              );
              final progress = _databaseService.getBudgetProgress(
                budget: budget,
                userId: userId,
              );
              final isOverBudget = progress >= 1.0;
              final shouldAlert = _databaseService.shouldAlertForBudget(
                budget: budget,
                userId: userId,
              );

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: category.color.withOpacity(0.1),
                  child: Icon(
                    _getIconData(category.icon),
                    color: category.color,
                    size: 20,
                  ),
                ),
                title: Text(
                  budget.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCurrency(spent, budget.currency.code)} of ${_formatCurrency(budget.amount, budget.currency.code)}',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverBudget
                              ? Colors.red
                              : shouldAlert
                              ? Colors.orange
                              : Colors.green,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isOverBudget
                            ? Colors.red
                            : shouldAlert
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${budget.daysRemaining} days left',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSummaryCard() {
    if (_budgetSummary == null) return const SizedBox.shrink();

    // Calculate totals in original currencies
    double totalBudgeted = 0.0;
    double totalSpent = 0.0;
    String displayCurrency = 'NGN'; // Default fallback

    for (final budget in _activeBudgets) {
      totalBudgeted += budget.amount;
      final userId = _authService.currentUser?.uid ?? '';
      final spent = _databaseService.getBudgetSpent(
        budget: budget,
        userId: userId,
      );
      totalSpent += spent;
      displayCurrency = budget.currency.code; // Use the first budget's currency
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _budgetSummary!.hasAlerts
              ? [Colors.orange.shade400, Colors.red.shade400]
              : [const Color(0xFF6C5CE7), const Color(0xFF9C88FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budget Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_budgetSummary!.totalBudgets} active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                    const Text(
                      'Total Budgeted',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalBudgeted, displayCurrency),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Spent',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(totalSpent, displayCurrency),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
                    '${(_budgetSummary!.overallProgress * 100).toStringAsFixed(1)}% used overall',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _budgetSummary!.statusMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _budgetSummary!.overallProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalsSummaryCard() {
    // Calculate summary statistics
    final totalGoals = _savingsGoals.length;
    final activeGoalsCount = _activeSavingsGoals.length;
    final completedGoalsCount = _completedSavingsGoals.length;
    final overdueGoalsCount = _overdueSavingsGoals.length;

    // Calculate total amounts in original currencies
    double totalTargetAmount = 0.0;
    double totalCurrentAmount = 0.0;
    String displayCurrency = 'NGN'; // Default fallback

    for (final goal in _savingsGoals) {
      totalTargetAmount += goal.targetAmount;
      totalCurrentAmount += goal.currentAmount;
      displayCurrency = goal.currency.code; // Use the first goal's currency
    }

    final overallProgress = totalTargetAmount > 0
        ? totalCurrentAmount / totalTargetAmount
        : 0.0;

    // Determine if there are any issues (overdue goals)
    final hasIssues = overdueGoalsCount > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SavingsGoalsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasIssues
                ? [Colors.orange.shade400, Colors.red.shade400]
                : [Colors.green.shade400, Colors.teal.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Savings Goals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalGoals total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
                      const Text(
                        'Total Saved',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(totalCurrentAmount, displayCurrency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Target',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(totalTargetAmount, displayCurrency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
                      '${(overallProgress * 100).toStringAsFixed(1)}% of goals achieved',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        if (activeGoalsCount > 0)
                          _buildGoalStatusChip(
                            'Active',
                            activeGoalsCount,
                            Colors.blue,
                          ),
                        if (completedGoalsCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildGoalStatusChip(
                            'Completed',
                            completedGoalsCount,
                            Colors.green,
                          ),
                        ],
                        if (overdueGoalsCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildGoalStatusChip(
                            'Overdue',
                            overdueGoalsCount,
                            Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: overallProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showBudgetAlerts() {
    if (_budgetAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No budget alerts at this time'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceTextColor = Theme.of(context).colorScheme.onSurface;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0A0E27)
                : Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Budget Alerts',
                      style: TextStyle(
                        color: isDark ? Colors.white : surfaceTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : surfaceTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _budgetAlerts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final alert = _budgetAlerts[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1F3A)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getAlertColor(
                            alert.severity,
                          ).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getAlertIcon(alert.type),
                                color: _getAlertColor(alert.severity),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  alert.budget.name,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : surfaceTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getAlertColor(
                                    alert.severity,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  alert.severity.name.toUpperCase(),
                                  style: TextStyle(
                                    color: _getAlertColor(alert.severity),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            alert.message,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.8)
                                  : surfaceTextColor.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BudgetsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Manage Budgets',
                      style: TextStyle(
                        color: isDark ? Colors.white : surfaceTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.low:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(BudgetAlertType type) {
    switch (type) {
      case BudgetAlertType.overBudget:
        return Icons.error;
      case BudgetAlertType.thresholdReached:
        return Icons.warning;
      case BudgetAlertType.expiringSoon:
        return Icons.schedule;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
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

  // Analytics section removed - now handled by AnalyticsSnippet widget

  // Analytics helper methods removed - now handled by AnalyticsSnippet widget

  // Chart methods removed - now handled by AnalyticsSnippet widget

  // Top categories and goals method removed - now handled by AnalyticsSnippet widget
}
