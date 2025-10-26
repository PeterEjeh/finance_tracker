import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/budget.dart';
import '../models/currency.dart';
import '../models/savings_goal.dart';
import '../models/savings_contribution.dart';
import '../models/report.dart';
import '../models/onboarding_data.dart';
import 'currency_service.dart';

class DatabaseService {
  static const String _transactionsBox = 'transactions';
  static const String _categoriesBox = 'categories';
  static const String _budgetsBox = 'budgets';
  static const String _savingsGoalsBox = 'savingsGoals';
  static const String _savingsContributionsBox = 'savingsContributions';
  static const String _settingsBox = 'settings';

  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  late Box<Transaction> _transactions;
  late Box<Category> _categories;
  late Box<Budget> _budgets;
  late Box<SavingsGoal> _savingsGoals;
  late Box<SavingsContribution> _savingsContributions;
  late Box _settings;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static bool _hasBeenInitialized = false;

  Future<void> init() async {
    if (_isInitialized) {
      print('⚠️ Database service already initialized, skipping...');
      return;
    }

    if (_hasBeenInitialized) {
      print(
        '⚠️ Database service initialization already in progress or completed',
      );
      return;
    }

    print('🔄 Initializing database service...');
    _hasBeenInitialized = true;

    try {
      await Hive.initFlutter();

      // Register adapters only if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TransactionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TransactionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(RecurringTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(CategoryTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(BudgetAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(BudgetPeriodAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(BudgetTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(SubcategoryAdapter());
      }
      if (!Hive.isAdapterRegistered(9)) {
        Hive.registerAdapter(SavingsGoalAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(SavingsGoalFrequencyAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(SavingsContributionAdapter());
      }
      if (!Hive.isAdapterRegistered(12)) {
        Hive.registerAdapter(SavingsContributionTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(13)) {
        Hive.registerAdapter(CurrencyAdapter());
      }
      if (!Hive.isAdapterRegistered(14)) {
        Hive.registerAdapter(ExchangeRateAdapter());
      }
      if (!Hive.isAdapterRegistered(15)) {
        Hive.registerAdapter(CurrencyAmountAdapter());
      }
      if (!Hive.isAdapterRegistered(16)) {
        Hive.registerAdapter(ExchangeRateSourceAdapter());
      }
      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(SpendingReportAdapter());
      }
      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(CategorySpendingAdapter());
      }
      if (!Hive.isAdapterRegistered(19)) {
        Hive.registerAdapter(DailySpendingAdapter());
      }
      if (!Hive.isAdapterRegistered(20)) {
        Hive.registerAdapter(ReportPeriodAdapter());
      }
      if (!Hive.isAdapterRegistered(21)) {
        Hive.registerAdapter(OnboardingDataAdapter());
      }
      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(UserTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(23)) {
        Hive.registerAdapter(IncomeFrequencyAdapter());
      }
      if (!Hive.isAdapterRegistered(24)) {
        Hive.registerAdapter(SpendingStyleAdapter());
      }
      if (!Hive.isAdapterRegistered(25)) {
        Hive.registerAdapter(FinancialGoalAdapter());
      }

      // Open boxes with error handling
      _transactions = await _openBoxSafely<Transaction>(_transactionsBox);
      _categories = await _openBoxSafely<Category>(_categoriesBox);
      _budgets = await _openBoxSafely<Budget>(_budgetsBox);
      _savingsGoals = await _openBoxSafely<SavingsGoal>(_savingsGoalsBox);
      _savingsContributions = await _openBoxSafely<SavingsContribution>(
        _savingsContributionsBox,
      );
      _settings = await Hive.openBox(_settingsBox);

      _isInitialized = true;
      print('✅ Database service initialized successfully');
    } catch (e, stackTrace) {
      print('❌ Error initializing database service: $e');
      print('Stack trace: $stackTrace');

      // Handle null-to-String casting errors by clearing corrupted data
      if (e.toString().contains(
        "type 'Null' is not a subtype of type 'String'",
      )) {
        print(
          '🔧 Detected null-to-String casting error. Clearing corrupted data...',
        );
        await _clearCorruptedData();
        // Retry initialization after clearing data
        await _retryInitialization();
      } else {
        rethrow;
      }
    }
  }

  Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      print('⚠️ Error opening box $boxName: $e');
      // Delete the corrupted box and create a new one
      await Hive.deleteBoxFromDisk(boxName);
      print('🗑️ Deleted corrupted box: $boxName');
      return await Hive.openBox<T>(boxName);
    }
  }

  Future<void> _clearCorruptedData() async {
    try {
      print('🧹 Clearing all Hive data to resolve casting errors...');

      // Close any open boxes first
      await close();

      // Delete all boxes
      await Hive.deleteBoxFromDisk(_transactionsBox);
      await Hive.deleteBoxFromDisk(_categoriesBox);
      await Hive.deleteBoxFromDisk(_budgetsBox);
      await Hive.deleteBoxFromDisk(_savingsGoalsBox);
      await Hive.deleteBoxFromDisk(_savingsContributionsBox);
      await Hive.deleteBoxFromDisk(_settingsBox);

      print('✅ All corrupted data cleared');
    } catch (e) {
      print('❌ Error clearing corrupted data: $e');
    }
  }

  Future<void> _retryInitialization() async {
    print('🔄 Retrying database initialization...');

    // Reset flags to allow re-initialization
    _isInitialized = false;
    _hasBeenInitialized = false;

    // Wait a bit before retrying
    await Future.delayed(const Duration(milliseconds: 500));

    // Retry initialization
    await init();
  }

  // Transaction operations
  Future<void> addTransaction(Transaction transaction) async {
    await _transactions.put(transaction.id, transaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    transaction.updatedAt = DateTime.now();
    await _transactions.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _transactions.delete(id);
  }

  Transaction? getTransaction(String id) {
    return _transactions.get(id);
  }

  List<Transaction> getAllTransactions({String? userId}) {
    if (userId != null) {
      return _transactions.values
          .where((transaction) => transaction.userId == userId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    return _transactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Transaction> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) {
    var transactions = getAllTransactions(userId: userId);
    return transactions
        .where(
          (transaction) =>
              transaction.date.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              transaction.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  List<Transaction> getTransactionsByCategory({
    required String categoryId,
    String? userId,
  }) {
    var transactions = getAllTransactions(userId: userId);
    return transactions
        .where((transaction) => transaction.categoryId == categoryId)
        .toList();
  }

  List<Transaction> getTransactionsByType({
    required TransactionType type,
    String? userId,
  }) {
    var transactions = getAllTransactions(userId: userId);
    return transactions
        .where((transaction) => transaction.type == type)
        .toList();
  }

  Future<double> getTotalAmount({
    TransactionType? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    bool convertToBaseCurrency = true,
  }) async {
    var transactions = getAllTransactions(userId: userId);

    if (startDate != null && endDate != null) {
      transactions = transactions
          .where(
            (transaction) =>
                transaction.date.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                transaction.date.isBefore(endDate.add(const Duration(days: 1))),
          )
          .toList();
    }

    if (type != null) {
      transactions = transactions
          .where((transaction) => transaction.type == type)
          .toList();
    }

    if (categoryId != null) {
      transactions = transactions
          .where((transaction) => transaction.categoryId == categoryId)
          .toList();
    }

    if (!convertToBaseCurrency) {
      // Return sum without conversion
      double total = 0.0;
      for (final transaction in transactions) {
        total += transaction.amount;
      }
      return total;
    }

    // Convert all amounts to the user's selected base currency before summing
    double total = 0.0;
    final currencyService = CurrencyService();
    // Get the actual base currency dynamically (set in settings)
    final actualBaseCurrency = await currencyService.getBaseCurrency();

    // Separate transactions that need async conversion
    final baseCurrencyTransactions = <Transaction>[];
    final storedRateTransactions = <Transaction>[];
    final needsConversionTransactions = <Transaction>[];

    for (final transaction in transactions) {
      if (transaction.currencyCode == actualBaseCurrency) {
        baseCurrencyTransactions.add(transaction);
      } else if (transaction.exchangeRate != null) {
        storedRateTransactions.add(transaction);
      } else {
        needsConversionTransactions.add(transaction);
      }
    }

    // Handle base currency transactions
    for (final transaction in baseCurrencyTransactions) {
      total += transaction.amount;
    }

    // Handle transactions with stored exchange rates
    for (final transaction in storedRateTransactions) {
      final convertedAmount = transaction.amount * transaction.exchangeRate!;
      total += convertedAmount;
    }

    // Handle transactions that need API conversion
    for (final transaction in needsConversionTransactions) {
      try {
        final convertedAmount = await currencyService.convertToBaseCurrency(
          amount: transaction.amount,
          fromCurrency: transaction.currencyCode,
        );
        if (convertedAmount != null) {
          total += convertedAmount.convertedAmount!;
        } else {
          // Fallback to original amount if conversion fails
          total += transaction.amount;
        }
      } catch (e) {
        print(
          'Error converting ${transaction.currencyCode} to base currency: $e',
        );
        // Fallback to original amount if conversion fails
        total += transaction.amount;
      }
    }

    return total;
  }

  // Category operations
  Future<void> addCategory(Category category) async {
    await _categories.put(category.id, category);
  }

  Future<void> updateCategory(Category category) async {
    category.updatedAt = DateTime.now();
    await _categories.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await _categories.delete(id);
  }

  Category? getCategory(String id) {
    return _categories.get(id);
  }

  List<Category> getAllCategories({String? userId}) {
    if (userId != null) {
      return _categories.values
          .where((category) => category.userId == userId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return _categories.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<Category> getCategoriesByType({
    required CategoryType type,
    String? userId,
  }) {
    var categories = getAllCategories(userId: userId);
    return categories.where((category) => category.type == type).toList();
  }

  Future<void> initializeDefaultCategories(String userId) async {
    final existingCategories = getAllCategories(userId: userId);
    if (existingCategories.isEmpty) {
      final defaultCategories = Category.getDefaultCategories(userId);
      for (final category in defaultCategories) {
        await addCategory(category);
      }
    }
  }

  // Budget operations
  Future<void> addBudget(Budget budget) async {
    await _budgets.put(budget.id, budget);
  }

  Future<void> updateBudget(Budget budget) async {
    budget.updatedAt = DateTime.now();
    await _budgets.put(budget.id, budget);
  }

  Future<void> deleteBudget(String id) async {
    await _budgets.delete(id);
  }

  Budget? getBudget(String id) {
    return _budgets.get(id);
  }

  List<Budget> getAllBudgets({String? userId}) {
    if (userId != null) {
      return _budgets.values.where((budget) => budget.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return _budgets.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Budget> getActiveBudgets({String? userId}) {
    var budgets = getAllBudgets(userId: userId);
    return budgets
        .where((budget) => budget.isActive && budget.isCurrentPeriod)
        .toList();
  }

  List<Budget> getBudgetsByCategory({
    required String categoryId,
    String? userId,
  }) {
    var budgets = getAllBudgets(userId: userId);
    return budgets.where((budget) => budget.categoryId == categoryId).toList();
  }

  List<Budget> getBudgetsByPeriod({
    required BudgetPeriod period,
    String? userId,
  }) {
    var budgets = getAllBudgets(userId: userId);
    return budgets.where((budget) => budget.period == period).toList();
  }

  Budget? getCurrentBudgetForCategory({
    required String categoryId,
    String? userId,
  }) {
    final budgets = getBudgetsByCategory(
      categoryId: categoryId,
      userId: userId,
    );
    try {
      return budgets.firstWhere(
        (budget) => budget.isActive && budget.isCurrentPeriod,
      );
    } catch (e) {
      return null;
    }
  }

  List<Budget> getBudgetsByType(BudgetType type, {String? userId}) {
    var budgets = getAllBudgets(userId: userId);
    return budgets.where((budget) => budget.type == type).toList();
  }

  double getBudgetSpent({required Budget budget, String? userId}) {
    final transactions = getTransactionsByDateRange(
      startDate: budget.startDate,
      endDate: budget.endDate,
      userId: userId,
    );

    // If a transaction has a budgetId set, it should count only toward that budget.
    // Otherwise, fall back to the existing category-based logic (including utilities tags).
    final filtered = transactions.where((transaction) {
      // Only expenses count
      if (transaction.type != TransactionType.expense) return false;

      // If transaction explicitly targets a budget, count it only if it matches
      final txBudgetId = transaction.budgetId;
      if (txBudgetId != null && txBudgetId.isNotEmpty) {
        return txBudgetId == budget.id;
      }

      // No explicit budget => fall back to category-based matching (and utility tag logic)
      if (transaction.categoryId != budget.categoryId) return false;

      if (budget.categoryId == 'expense_utilities') {
        return transaction.tags != null &&
            (transaction.tags == 'electricity' || transaction.tags == 'data');
      }

      return true;
    });

    return filtered.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double getBudgetRemaining({required Budget budget, String? userId}) {
    final spent = getBudgetSpent(budget: budget, userId: userId);
    return (budget.amount - spent).clamp(0.0, budget.amount);
  }

  double getBudgetProgress({required Budget budget, String? userId}) {
    final spent = getBudgetSpent(budget: budget, userId: userId);
    return (spent / budget.amount).clamp(0.0, 1.0);
  }

  bool isBudgetOverLimit({required Budget budget, String? userId}) {
    final progress = getBudgetProgress(budget: budget, userId: userId);
    return progress >= 1.0;
  }

  bool shouldAlertForBudget({required Budget budget, String? userId}) {
    if (!budget.alertEnabled) return false;
    final progress = getBudgetProgress(budget: budget, userId: userId);
    return progress >= budget.alertThreshold;
  }

  List<Budget> getBudgetsNeedingAlert({String? userId}) {
    final activeBudgets = getActiveBudgets(userId: userId);
    return activeBudgets
        .where((budget) => shouldAlertForBudget(budget: budget, userId: userId))
        .toList();
  }

  Map<String, double> getBudgetSummary({String? userId}) {
    final activeBudgets = getActiveBudgets(userId: userId);
    double totalBudgeted = 0.0;
    double totalSpent = 0.0;
    double totalRemaining = 0.0;

    for (final budget in activeBudgets) {
      final spent = getBudgetSpent(budget: budget, userId: userId);
      totalBudgeted += budget.amount;
      totalSpent += spent;
      totalRemaining += (budget.amount - spent).clamp(0.0, budget.amount);
    }

    return {
      'totalBudgeted': totalBudgeted,
      'totalSpent': totalSpent,
      'totalRemaining': totalRemaining,
    };
  }

  // Savings Goal operations
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await _savingsGoals.put(goal.id, goal);
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    goal.updatedAt = DateTime.now();
    await _savingsGoals.put(goal.id, goal);
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _savingsGoals.delete(id);
    // Also delete all contributions for this goal
    final contributions = getSavingsContributionsByGoal(id);
    for (final contribution in contributions) {
      await _savingsContributions.delete(contribution.id);
    }
  }

  SavingsGoal? getSavingsGoal(String id) {
    return _savingsGoals.get(id);
  }

  List<SavingsGoal> getAllSavingsGoals({String? userId}) {
    if (userId != null) {
      return _savingsGoals.values
          .where((goal) => goal.userId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return _savingsGoals.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SavingsGoal> getActiveSavingsGoals({String? userId}) {
    var goals = getAllSavingsGoals(userId: userId);
    return goals.where((goal) => goal.isActive).toList();
  }

  List<SavingsGoal> getCompletedSavingsGoals({String? userId}) {
    var goals = getAllSavingsGoals(userId: userId);
    return goals.where((goal) => goal.isCompleted).toList();
  }

  List<SavingsGoal> getOverdueSavingsGoals({String? userId}) {
    var goals = getAllSavingsGoals(userId: userId);
    return goals.where((goal) => goal.isOverdue).toList();
  }

  // Savings Contribution operations
  Future<void> addSavingsContribution(SavingsContribution contribution) async {
    await _savingsContributions.put(contribution.id, contribution);

    // Update the savings goal's current amount
    final goal = getSavingsGoal(contribution.savingsGoalId);
    if (goal != null) {
      goal.addContribution(contribution.amount);
      await updateSavingsGoal(goal);
    }
  }

  Future<void> updateSavingsContribution(
    SavingsContribution contribution,
  ) async {
    final oldContribution = _savingsContributions.get(contribution.id);
    if (oldContribution != null) {
      final goal = getSavingsGoal(contribution.savingsGoalId);
      if (goal != null) {
        // Remove old contribution and add new one
        goal.removeContribution(oldContribution.amount);
        goal.addContribution(contribution.amount);
        await updateSavingsGoal(goal);
      }
    }

    contribution.updatedAt = DateTime.now();
    await _savingsContributions.put(contribution.id, contribution);
  }

  Future<void> deleteSavingsContribution(String id) async {
    final contribution = _savingsContributions.get(id);
    if (contribution != null) {
      final goal = getSavingsGoal(contribution.savingsGoalId);
      if (goal != null) {
        goal.removeContribution(contribution.amount);
        await updateSavingsGoal(goal);
      }
    }
    await _savingsContributions.delete(id);
  }

  SavingsContribution? getSavingsContribution(String id) {
    return _savingsContributions.get(id);
  }

  List<SavingsContribution> getAllSavingsContributions({String? userId}) {
    if (userId != null) {
      return _savingsContributions.values
          .where((contribution) => contribution.userId == userId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    return _savingsContributions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<SavingsContribution> getSavingsContributionsByGoal(
    String goalId, {
    String? userId,
  }) {
    var contributions = getAllSavingsContributions(userId: userId);
    return contributions
        .where((contribution) => contribution.savingsGoalId == goalId)
        .toList();
  }

  List<SavingsContribution> getSavingsContributionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    String? goalId,
  }) {
    var contributions = getAllSavingsContributions(userId: userId);
    return contributions.where((contribution) {
      final isInDateRange =
          contribution.date.isAfter(
            startDate.subtract(const Duration(days: 1)),
          ) &&
          contribution.date.isBefore(endDate.add(const Duration(days: 1)));

      if (goalId != null) {
        return isInDateRange && contribution.savingsGoalId == goalId;
      }

      return isInDateRange;
    }).toList();
  }

  // Settings operations
  Future<void> setSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> deleteSetting(String key) async {
    await _settings.delete(key);
  }

  // Get all settings as a map (synchronous)
  Map<String, dynamic> getAllSettingsSync() {
    final Map<String, dynamic> allSettings = {};
    for (final key in _settings.keys) {
      allSettings[key] = _settings.get(key);
    }
    return allSettings;
  }

  // Utility methods
  Future<void> clearAllData() async {
    await _transactions.clear();
    await _categories.clear();
    await _budgets.clear();
    await _savingsGoals.clear();
    await _savingsContributions.clear();
    await _settings.clear();
  }

  Future<void> clearUserData(String userId) async {
    // Clear transactions for user
    final userTransactions = _transactions.values
        .where((transaction) => transaction.userId == userId)
        .toList();
    for (final transaction in userTransactions) {
      await _transactions.delete(transaction.id);
    }

    // Clear categories for user
    final userCategories = _categories.values
        .where((category) => category.userId == userId)
        .toList();
    for (final category in userCategories) {
      await _categories.delete(category.id);
    }

    // Clear budgets for user
    final userBudgets = _budgets.values
        .where((budget) => budget.userId == userId)
        .toList();
    for (final budget in userBudgets) {
      await _budgets.delete(budget.id);
    }

    // Clear savings goals for user
    final userSavingsGoals = _savingsGoals.values
        .where((goal) => goal.userId == userId)
        .toList();
    for (final goal in userSavingsGoals) {
      await _savingsGoals.delete(goal.id);
    }

    // Clear savings contributions for user
    final userSavingsContributions = _savingsContributions.values
        .where((contribution) => contribution.userId == userId)
        .toList();
    for (final contribution in userSavingsContributions) {
      await _savingsContributions.delete(contribution.id);
    }
  }

  Future<void> close() async {
    await _transactions.close();
    await _categories.close();
    await _budgets.close();
    await _savingsGoals.close();
    await _savingsContributions.close();
    await _settings.close();
    _isInitialized = false;
    _hasBeenInitialized = false;
  }

  /// Reset the database service completely
  static Future<void> reset() async {
    _hasBeenInitialized = false;
    if (instance._isInitialized) {
      await instance.close();
    }
    _instance = null;
  }

  // Backup and restore
  Map<String, dynamic> exportData({String? userId, String? userName}) {
    final transactions = getAllTransactions(userId: userId);
    final categories = getAllCategories(userId: userId);
    final budgets = getAllBudgets(userId: userId);
    final savingsGoals = getAllSavingsGoals(userId: userId);
    final savingsContributions = getAllSavingsContributions(userId: userId);

    return {
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'savingsGoals': savingsGoals.map((g) => g.toJson()).toList(),
      'savingsContributions': savingsContributions
          .map((c) => c.toJson())
          .toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'userName': userName, // Include username in backup
      'userSettings': getAllSettingsSync(), // Include user settings
    };
  }

  Future<void> importData(Map<String, dynamic> data, String userId) async {
    try {
      // Import categories first
      if (data['categories'] != null) {
        final categoriesData = data['categories'] as List;
        for (final categoryJson in categoriesData) {
          final category = Category.fromJson(categoryJson);
          // Update userId to current user
          final updatedCategory = category.copyWith();
          await addCategory(updatedCategory);
        }
      }

      // Import transactions
      if (data['transactions'] != null) {
        final transactionsData = data['transactions'] as List;
        for (final transactionJson in transactionsData) {
          final transaction = Transaction.fromJson(transactionJson);
          // Update userId to current user
          final updatedTransaction = Transaction(
            id: transaction.id,
            title: transaction.title,
            amount: transaction.amount,
            categoryId: transaction.categoryId,
            type: transaction.type,
            date: transaction.date,
            description: transaction.description,
            receiptImagePath: transaction.receiptImagePath,
            userId: userId, // Use current user ID
            createdAt: transaction.createdAt,
            updatedAt: transaction.updatedAt,
            tags: transaction.tags,
            location: transaction.location,
            isRecurring: transaction.isRecurring,
            recurringType: transaction.recurringType,
            nextRecurringDate: transaction.nextRecurringDate,
            currencyCode: transaction.currencyCode,
            originalAmount: transaction.originalAmount,
            originalCurrencyCode: transaction.originalCurrencyCode,
            exchangeRate: transaction.exchangeRate,
          );
          await addTransaction(updatedTransaction);
        }
      }

      // Import budgets
      if (data['budgets'] != null) {
        final budgetsData = data['budgets'] as List;
        for (final budgetJson in budgetsData) {
          final budget = Budget.fromJson(budgetJson);
          // Update userId to current user
          final updatedBudget = budget.copyWith();
          await addBudget(updatedBudget);
        }
      }

      // Import savings goals
      if (data['savingsGoals'] != null) {
        final savingsGoalsData = data['savingsGoals'] as List;
        for (final goalJson in savingsGoalsData) {
          final goal = SavingsGoal.fromJson(goalJson);
          // Update userId to current user
          final updatedGoal = SavingsGoal(
            id: goal.id,
            name: goal.name,
            description: goal.description,
            targetAmount: goal.targetAmount,
            currentAmount: goal.currentAmount,
            targetDate: goal.targetDate,
            contributionFrequency: goal.contributionFrequency,
            suggestedContribution: goal.suggestedContribution,
            isActive: goal.isActive,
            userId: userId, // Use current user ID
            currencyCode: goal.currencyCode,
            createdAt: goal.createdAt,
            updatedAt: goal.updatedAt,
          );
          await addSavingsGoal(updatedGoal);
        }
      }

      // Import savings contributions
      if (data['savingsContributions'] != null) {
        final savingsContributionsData = data['savingsContributions'] as List;
        for (final contributionJson in savingsContributionsData) {
          final contribution = SavingsContribution.fromJson(contributionJson);
          // Update userId to current user
          final updatedContribution = SavingsContribution(
            id: contribution.id,
            savingsGoalId: contribution.savingsGoalId,
            amount: contribution.amount,
            date: contribution.date,
            note: contribution.note,
            type: contribution.type,
            userId: userId, // Use current user ID
            currencyCode: contribution.currencyCode,
            createdAt: contribution.createdAt,
            updatedAt: contribution.updatedAt,
          );
          await addSavingsContribution(updatedContribution);
        }
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }
}
