import 'package:flutter/material.dart';
import '../../models/savings_goal.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'add_savings_goal_screen.dart';
import 'savings_goal_details_screen.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  List<SavingsGoal> _savingsGoals = [];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavingsGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavingsGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';
      setState(() {
        _savingsGoals = _databaseService.getAllSavingsGoals(userId: userId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading savings goals: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<SavingsGoal> get _activeGoals => _savingsGoals
      .where((goal) => goal.isActive && !goal.isCompleted)
      .toList();

  List<SavingsGoal> get _completedGoals =>
      _savingsGoals.where((goal) => goal.isCompleted).toList();

  List<SavingsGoal> get _overdueGoals => _savingsGoals
      .where((goal) => goal.isOverdue && !goal.isCompleted)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Savings Goals',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF2C2C2C),
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF2C2C2C),
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.6)
              : const Color(0xFF2C2C2C).withOpacity(0.6),
          indicatorColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : const Color(0xFF2C2C2C),
          tabs: [
            Tab(
              text: 'Active (${_activeGoals.length})',
              icon: const Icon(Icons.savings, size: 20),
            ),
            Tab(
              text: 'Completed (${_completedGoals.length})',
              icon: const Icon(Icons.check_circle, size: 20),
            ),
            Tab(
              text: 'Overdue (${_overdueGoals.length})',
              icon: const Icon(Icons.warning, size: 20),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsList(_activeGoals, 'No active savings goals yet.'),
                _buildGoalsList(
                  _completedGoals,
                  'No completed goals yet.',
                  showCreateButton: false,
                ),
                _buildGoalsList(
                  _overdueGoals,
                  'No overdue goals.',
                  showCreateButton: false,
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF6366F1).withOpacity(0.3)
                  : const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddGoal(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: const Text(
            'New Goal',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsList(
    List<SavingsGoal> goals,
    String emptyMessage, {
    bool showCreateButton = true,
  }) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (showCreateButton)
              ElevatedButton.icon(
                onPressed: () => _navigateToAddGoal(),
                icon: const Icon(Icons.add),
                label: const Text('Create Your First Goal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF2C2C2C),
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C2C)
                      : Colors.white,
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSavingsGoals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) => _buildGoalCard(goals[index]),
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal) {
    final progressPercent = (goal.progressPercentage * 100).toInt();
    final isOverdue = goal.isOverdue;
    final isCompleted = goal.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCompleted
              ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
              : isOverdue
              ? [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ]
              : Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF1A1F3A), const Color(0xFF252B4A)]
              : [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigateToGoalDetails(goal),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                            goal.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF2C2C2C),
                            ),
                          ),
                          if (goal.description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                goal.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isCompleted)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          )
                        else if (isOverdue)
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 24,
                          ),
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? Colors.green
                                : isOverdue
                                ? Colors.orange
                                : Theme.of(context).brightness ==
                                      Brightness.dark
                                ? Colors.white
                                : const Color(0xFF2C2C2C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          goal.formattedCurrentAmount,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF2C2C2C),
                          ),
                        ),
                        Text(
                          goal.formattedTargetAmount,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: goal.progressPercentage,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? Colors.green
                                : isOverdue
                                ? Colors.orange
                                : Theme.of(context).brightness ==
                                      Brightness.dark
                                ? const Color(
                                    0xFF6366F1,
                                  ) // Indigo color for dark mode
                                : const Color(
                                    0xFF3B82F6,
                                  ), // Blue color for light mode
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Additional info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.schedule,
                        label: isCompleted
                            ? 'Completed!'
                            : '${goal.daysRemaining} days left',
                        color: isCompleted
                            ? Colors.green
                            : isOverdue
                            ? Colors.orange
                            : null,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.trending_up,
                        label:
                            'Suggest: ${goal.formattedSuggestedContribution}',
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
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color:
              color ??
              (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  color ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToAddGoal() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddSavingsGoalScreen()),
    );

    if (result == true) {
      _loadSavingsGoals();
    }
  }

  Future<void> _navigateToGoalDetails(SavingsGoal goal) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SavingsGoalDetailsScreen(goal: goal),
      ),
    );

    if (result == true) {
      _loadSavingsGoals();
    }
  }
}
