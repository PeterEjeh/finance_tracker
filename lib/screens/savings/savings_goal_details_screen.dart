import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/currency.dart';
import '../../models/savings_goal.dart';
import '../../models/savings_contribution.dart';
import '../../models/transaction.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/thousands_separator_input_formatter.dart';
import 'add_savings_goal_screen.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [0.0, _animation.value * 0.5 + 0.5, 1.0],
              transform: GradientRotation(_animation.value * 3.14159),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SavingsGoalDetailsScreen extends StatefulWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailsScreen({super.key, required this.goal});

  @override
  State<SavingsGoalDetailsScreen> createState() =>
      _SavingsGoalDetailsScreenState();
}

class _SavingsGoalDetailsScreenState extends State<SavingsGoalDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  late SavingsGoal _goal;
  List<SavingsContribution> _contributions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';
      final contributions = await Future.value(
        _databaseService.getSavingsContributionsByGoal(
          _goal.id,
          userId: userId,
        ),
      );
      final updatedGoal = await Future.value(
        _databaseService.getSavingsGoal(_goal.id),
      );

      if (mounted) {
        setState(() {
          _contributions = contributions;
          if (updatedGoal != null) {
            _goal = updatedGoal;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contributions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddContributionDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Contribution',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          ),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF1A1F3A), const Color(0xFF252B4A)]
                            : [Colors.white, Colors.grey.shade50],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add Contribution',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF2C2C2C),
                                      ),
                                    ),
                                    Text(
                                      'Add money to your savings goal',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Amount input
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: TextFormField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\.,]'),
                                ),
                                ThousandsSeparatorInputFormatter(
                                  maxDecimalDigits:
                                      _goal.currency.decimalPlaces,
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: '${_goal.currency.symbol} ',
                                prefixStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.8)
                                      : const Color(0xFF2C2C2C),
                                ),
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.grey.shade600,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2C2C2C),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Date picker
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: isDark
                                          ? const ColorScheme.dark(
                                              primary: Color(0xFF6366F1),
                                              surface: Color(0xFF1A1F3A),
                                            )
                                          : const ColorScheme.light(
                                              primary: Color(0xFF3B82F6),
                                              surface: Colors.white,
                                            ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setDialogState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      DateFormat(
                                        'EEEE, MMM dd, yyyy',
                                      ).format(selectedDate),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF2C2C2C),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Note input
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: TextFormField(
                              controller: noteController,
                              decoration: InputDecoration(
                                labelText: 'Note (Optional)',
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.grey.shade600,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                hintText:
                                    'Add a note about this contribution...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.grey.shade400,
                                ),
                              ),
                              maxLines: 3,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2C2C2C),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.7)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final amount = double.tryParse(
                                      amountController.text.replaceAll(',', ''),
                                    );

                                    if (amount == null || amount <= 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Please enter a valid amount',
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    await _addContribution(
                                      amount,
                                      selectedDate,
                                      noteController.text.trim().isEmpty
                                          ? null
                                          : noteController.text.trim(),
                                    );

                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Add Contribution',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addContribution(
    double amount,
    DateTime date,
    String? note,
  ) async {
    try {
      final userId = _authService.currentUser?.uid ?? '';

      final contribution = SavingsContribution.create(
        savingsGoalId: _goal.id,
        amount: amount,
        userId: userId,
        date: date,
        note: note,
        currencyCode: _goal.currencyCode,
      );

      await _databaseService.addSavingsContribution(contribution);

      // Create corresponding expense transaction
      final expenseTransaction = Transaction.create(
        title: 'Savings Contribution - ${_goal.name}',
        amount: amount,
        categoryId: 'expense_savings', // Savings & Investments category
        type: TransactionType.expense,
        userId: userId,
        date: date,
        description: note ?? 'Contribution to ${_goal.name}',
        currencyCode: _goal.currencyCode,
      );

      await _databaseService.addTransaction(expenseTransaction);

      await _loadContributions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_goal.currency.formatAmount(amount)} to ${_goal.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Check if goal is completed
        if (_goal.isCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '🎉 Congratulations! You\'ve reached your savings goal!',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding contribution: $e')),
        );
      }
    }
  }

  Future<void> _deleteContribution(SavingsContribution contribution) async {
    try {
      // Find and delete the corresponding expense transaction
      final userId = _authService.currentUser?.uid ?? '';
      final allTransactions = _databaseService.getAllTransactions(
        userId: userId,
      );
      final correspondingTransaction = allTransactions
          .where((transaction) {
            return transaction.title ==
                    'Savings Contribution - ${_goal.name}' &&
                transaction.type == TransactionType.expense &&
                transaction.amount == contribution.amount &&
                transaction.date.year == contribution.date.year &&
                transaction.date.month == contribution.date.month &&
                transaction.date.day == contribution.date.day;
          })
          .cast<Transaction?>()
          .firstWhere((element) => true, orElse: () => null);

      if (correspondingTransaction != null) {
        await _databaseService.deleteTransaction(correspondingTransaction.id);
      }

      await _databaseService.deleteSavingsContribution(contribution.id);
      await _loadContributions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed ${contribution.formattedAmount} contribution',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing contribution: $e')),
        );
      }
    }
  }

  Future<void> _editGoal() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddSavingsGoalScreen(goal: _goal),
      ),
    );

    if (result == true) {
      await _loadContributions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _goal.isCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF2C2C2C),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _goal.name,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF2C2C2C),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : const Color(0xFF2C2C2C),
            ),
            color: theme.cardColor,
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editGoal();
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
                      color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Goal',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadContributions,
        color: Colors.green.shade600,
        backgroundColor: Colors.white,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSavingsOverview(),
            const SizedBox(height: 24),
            _buildProgressChart(),
            const SizedBox(height: 24),
            _buildGoalInfo(),
            const SizedBox(height: 24),
            _buildContributionsList(),
          ],
        ),
      ),
      floatingActionButton: !isCompleted
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _showAddContributionDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text(
                  'Add Contribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSavingsOverview() {
    final isCompleted = _goal.isCompleted;
    final isOverdue = _goal.isOverdue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : isOverdue
                      ? Colors.orange
                      : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _goal.name,
                      style: TextStyle(
                        color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                            .withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isCompleted
                          ? 'Goal Achieved! 🎉'
                          : isOverdue
                          ? 'Overdue'
                          : 'In Progress',
                      style: TextStyle(
                        color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                            .withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final baseStyle = TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                fontWeight: FontWeight.bold,
              );
              final amountStyle = baseStyle.copyWith(
                fontSize: isNarrow ? 18 : 22,
              );
              final labelStyle = TextStyle(
                color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                    .withOpacity(0.6),
                fontSize: 13,
              );

              Widget item({
                required String label,
                required String value,
                TextStyle? valueStyle,
                TextAlign align = TextAlign.start,
              }) {
                return Column(
                  crossAxisAlignment: align == TextAlign.end
                      ? CrossAxisAlignment.end
                      : align == TextAlign.center
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(label, style: labelStyle),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: align,
                      style: valueStyle ?? amountStyle,
                    ),
                  ],
                );
              }

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    item(
                      label: 'Saved',
                      value: _goal.formattedCurrentAmount,
                      valueStyle: amountStyle.copyWith(
                        color: isCompleted
                            ? Colors.green
                            : isOverdue
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    item(
                      label: 'Target',
                      value: _goal.formattedTargetAmount,
                      valueStyle: amountStyle,
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    item(
                      label: 'Remaining',
                      value: _goal.formattedRemainingAmount,
                      valueStyle: amountStyle.copyWith(
                        color: isCompleted ? Colors.green : Colors.red,
                      ),
                      align: TextAlign.end,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: item(
                      label: 'Saved',
                      value: _goal.formattedCurrentAmount,
                      valueStyle: amountStyle.copyWith(
                        color: isCompleted
                            ? Colors.green
                            : isOverdue
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  ),
                  Expanded(
                    child: item(
                      label: 'Target',
                      value: _goal.formattedTargetAmount,
                      valueStyle: amountStyle,
                      align: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: item(
                      label: 'Remaining',
                      value: _goal.formattedRemainingAmount,
                      valueStyle: amountStyle.copyWith(
                        color: isCompleted ? Colors.green : Colors.red,
                      ),
                      align: TextAlign.end,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_goal.progressPercentage * 100).toStringAsFixed(1)}% completed',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _goal.isCompleted
                        ? 'Goal achieved!'
                        : '${_goal.daysRemaining} days left',
                    style: TextStyle(
                      color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                          .withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _goal.progressPercentage.clamp(0.0, 1.0),
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? Colors.green
                        : isOverdue
                        ? Colors.orange
                        : Colors.blue,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    final progressPercent = (_goal.progressPercentage * 100).toInt();
    final isOverdue = _goal.isOverdue;
    final isCompleted = _goal.isCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Savings Progress',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF2C2C2C),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 70,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(enabled: false),
                    sections: [
                      // Used section with gradient and animation
                      PieChartSectionData(
                        value: (_goal.progressPercentage * 100).clamp(
                          0.0,
                          100.0,
                        ),
                        radius: 48,
                        gradient: LinearGradient(
                          colors: isCompleted
                              ? [Colors.green.shade400, Colors.green]
                              : isOverdue
                              ? [Colors.orange.shade400, Colors.orange]
                              : [
                                  const Color(0xFF6C5CE7),
                                  const Color(0xFF9C88FF),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        title: '',
                      ),
                      // Remaining section (subtle track)
                      PieChartSectionData(
                        value: _goal.progressPercentage >= 1.0
                            ? 0
                            : (100 - (_goal.progressPercentage * 100)),
                        radius: 48,
                        color: const Color(0xFFECECEC),
                        title: '',
                      ),
                    ],
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 900),
                  swapAnimationCurve: Curves.easeInOutCubic,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_goal.progressPercentage * 100).clamp(0.0, 100.0).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                      ),
                    ),
                    Text(
                      isCompleted
                          ? 'Completed!'
                          : isOverdue
                          ? 'Overdue'
                          : 'On track',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? Colors.green
                            : isOverdue
                            ? Colors.orange
                            : const Color(0xFF6C5CE7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contributions',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_contributions.length} contributions',
                style: TextStyle(
                  color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                      .withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_contributions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.savings,
                      size: 48,
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No contributions yet',
                      style: TextStyle(
                        color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                            .withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Start saving towards your goal!',
                      style: TextStyle(
                        color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                            .withOpacity(0.4),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _contributions.length > 5 ? 5 : _contributions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contribution = _contributions[index];
                return _buildContributionItem(contribution);
              },
            ),
          if (_contributions.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full contributions list
                  },
                  child: Text(
                    'View all ${_contributions.length} contributions',
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContributionItem(SavingsContribution contribution) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.add_circle_outline,
            color: Colors.green,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contribution.formattedAmount,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(contribution.date),
                style: TextStyle(
                  color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                      .withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _confirmDeleteContribution(contribution),
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red.withOpacity(0.7),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goal Information',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF2C2C2C),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Period', _goal.contributionFrequency.displayName),
          _buildInfoRow(
            'Target Date',
            '${_goal.targetDate.day}/${_goal.targetDate.month}/${_goal.targetDate.year}',
          ),
          _buildInfoRow(
            'Created Date',
            '${_goal.createdAt.day}/${_goal.createdAt.month}/${_goal.createdAt.year}',
          ),
          _buildInfoRow('Status', _goal.isCompleted ? 'Completed' : 'Active'),
          if (_goal.description != null && _goal.description!.isNotEmpty)
            _buildInfoRow('Description', _goal.description!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: (isDark ? Colors.white : const Color(0xFF2C2C2C))
                    .withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2C2C2C),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteContribution(
    SavingsContribution contribution,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contribution'),
        content: Text(
          'Are you sure you want to delete this ${contribution.formattedAmount} contribution?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteContribution(contribution);
    }
  }
}
