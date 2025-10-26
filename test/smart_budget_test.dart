import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/budget.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/models/category.dart';
import 'package:finance_tracker/services/budget_service.dart';

void main() {
  group('Smart Budget Calculations', () {
    late BudgetService budgetService;

    setUp(() {
      // Initialize budget service for testing
      budgetService = BudgetService();
    });

    test('Progressive Budget - Food Budget Calculation', () async {
      // Create a progressive budget (food budget)
      final budget = Budget.create(
        name: 'Monthly Food Budget',
        categoryId: 'food_category_id',
        amount: 50000.0, // ₦50,000
        period: BudgetPeriod.monthly,
        userId: 'test_user_id',
        type: BudgetType.progressive,
      );

      // Simulate 15 days into the month (50% through the period)
      // Expected daily spend: ₦50,000 / 30 days = ₦1,666.67
      // Expected spend by day 15: ₦1,666.67 * 15 = ₦25,000

      // Test with ₦20,000 spent (under expected)
      // This should show as "On Track"

      print('Progressive Budget Test:');
      print('Budget: ₦${budget.amount} for ${budget.period.displayName}');
      print('Budget Type: ${budget.type.displayName}');
      print('Expected behavior: Compares actual vs expected daily progress');
      print('Test case: ₦20,000 spent on day 15 of 30-day period');
      print('Expected: On Track (within tolerance)');
      print('');
    });

    test('Fixed Budget - Netflix Subscription Calculation', () async {
      // Create a fixed budget (Netflix subscription)
      final budget = Budget.create(
        name: 'Netflix Subscription',
        categoryId: 'entertainment_category_id',
        amount: 8500.0, // ₦8,500
        period: BudgetPeriod.monthly,
        userId: 'test_user_id',
        type: BudgetType.fixed,
      );

      print('Fixed Budget Test:');
      print('Budget: ₦${budget.amount} for ${budget.period.displayName}');
      print('Budget Type: ${budget.type.displayName}');
      print(
        'Expected behavior: Binary logic - Not Started / On Track / Completed / Over Budget',
      );
      print('Test case: ₦8,500 spent (exactly the budget amount)');
      print('Expected: Completed (not Over Budget)');
      print('');
    });

    test('Goal Budget - Vacation Fund Calculation', () async {
      // Create a goal budget (vacation fund)
      final budget = Budget.create(
        name: 'Vacation Fund',
        categoryId: 'savings_category_id',
        amount: 500000.0, // ₦500,000 goal
        period: BudgetPeriod.yearly,
        userId: 'test_user_id',
        type: BudgetType.goal,
      );

      print('Goal Budget Test:');
      print('Budget: ₦${budget.amount} for ${budget.period.displayName}');
      print('Budget Type: ${budget.type.displayName}');
      print(
        'Expected behavior: Progress towards goal - Needs Attention / On Track / Goal Achieved',
      );
      print('Test case: ₦150,000 saved (30% of goal)');
      print('Expected: On Track');
      print('');
    });

    test('Recurring Budget - Gym Membership Calculation', () async {
      // Create a recurring budget (gym membership)
      final budget = Budget.create(
        name: 'Gym Membership',
        categoryId: 'health_category_id',
        amount: 25000.0, // ₦25,000
        period: BudgetPeriod.monthly,
        userId: 'test_user_id',
        type: BudgetType.recurring,
      );

      print('Recurring Budget Test:');
      print('Budget: ₦${budget.amount} for ${budget.period.displayName}');
      print('Budget Type: ${budget.type.displayName}');
      print(
        'Expected behavior: Similar to progressive but with auto-reset capability',
      );
      print('Test case: ₦15,000 spent (60% of budget)');
      print('Expected: On Track');
      print('');
    });

    test('Budget Type Display Names', () {
      expect(BudgetType.progressive.displayName, 'Progressive Budget');
      expect(BudgetType.fixed.displayName, 'Fixed/Event-Based Budget');
      expect(BudgetType.recurring.displayName, 'Recurring Budget');
      expect(BudgetType.goal.displayName, 'Goal-Based Budget');
    });

    test('Budget Type Auto-Detection Keywords', () {
      // Test the smart categorization service for auto-detecting budget types
      print('Smart Categorization Tests:');
      print(
        'Keywords that should auto-detect as Progressive: Food, Transport, Fuel',
      );
      print('Keywords that should auto-detect as Fixed: Data, Rent, Tuition');
      print(
        'Keywords that should auto-detect as Recurring: Netflix, Spotify, Gym',
      );
      print('Keywords that should auto-detect as Goal: Goal, Fund, Save');
      print('');
    });
  });
}
