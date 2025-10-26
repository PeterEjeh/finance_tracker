import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/models/category.dart';
import 'package:finance_tracker/models/transaction.dart';
import 'package:finance_tracker/services/smart_categorization_service.dart';

void main() {
  group('SmartCategorizationService Tests', () {
    late List<Category> testCategories;

    setUp(() {
      testCategories = Category.getDefaultCategories('test_user_id');
    });

    test('should categorize Uber ride correctly', () {
      // Debug: Print available categories
      print('Available categories:');
      testCategories.forEach((cat) => print('${cat.id}: ${cat.name}'));

      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'Uber ride to airport',
        description: 'Business trip to Lagos',
        availableCategories: testCategories,
        transactionType: TransactionType.expense,
      );

      print('Number of suggestions: ${suggestions.length}');
      suggestions.forEach(
        (s) => print('Suggestion: ${s.category.name} (${s.confidence})'),
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first.category.id, 'expense_transport');
      expect(suggestions.first.confidence, greaterThan(0.8));
    });

    test('should categorize Jumia purchase correctly', () {
      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'Jumia online shopping',
        description: 'Electronics and gadgets',
        availableCategories: testCategories,
        transactionType: TransactionType.expense,
      );

      expect(suggestions.isNotEmpty, true);
      // Should match personal/lifestyle category for shopping
      expect(suggestions.first.category.id, 'expense_personal');
    });

    test('should categorize salary correctly', () {
      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'Monthly salary payment',
        description: 'Salary for September 2024',
        availableCategories: testCategories,
        transactionType: TransactionType.income,
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first.category.id, 'income_salary');
      expect(suggestions.first.confidence, greaterThan(0.9));
    });

    test('should categorize fuel purchase correctly', () {
      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'NNPC fuel station',
        description: 'Petrol for car',
        availableCategories: testCategories,
        transactionType: TransactionType.expense,
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first.category.id, 'expense_transport');
    });

    test('should categorize restaurant correctly', () {
      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'Chicken Republic lunch',
        description: 'Team lunch meeting',
        availableCategories: testCategories,
        transactionType: TransactionType.expense,
      );

      expect(suggestions.isNotEmpty, true);
      expect(suggestions.first.category.id, 'expense_food');
    });

    test(
      'should return suggestions for merchant with miscellaneous keywords',
      () {
        final suggestions = SmartCategorizationService.getCategorySuggestions(
          title: 'Store purchase miscellaneous',
          description: 'Various items bought',
          availableCategories: testCategories,
          transactionType: TransactionType.expense,
        );

        print('Miscellaneous suggestions: ${suggestions.length}');
        suggestions.forEach(
          (s) => print('Misc: ${s.category.name} (${s.confidence})'),
        );

        // Should return suggestions for miscellaneous category with lower confidence
        expect(suggestions.isNotEmpty, true);
        expect(suggestions.first.confidence, lessThan(0.8));
      },
    );

    test('should auto-assign high confidence suggestions', () {
      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'Uber ride to office',
        description: 'Daily commute',
        availableCategories: testCategories,
        transactionType: TransactionType.expense,
      );

      expect(suggestions.isNotEmpty, true);
      final bestSuggestion = suggestions.first;
      expect(SmartCategorizationService.shouldAutoAssign(bestSuggestion), true);
    });

    test('should not auto-assign low confidence suggestions', () {
      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'Store purchase miscellaneous',
        description: 'Various items bought',
        availableCategories: testCategories,
        transactionType: TransactionType.expense,
      );

      print('Random purchase suggestions: ${suggestions.length}');
      suggestions.forEach(
        (s) => print('Random: ${s.category.name} (${s.confidence})'),
      );

      expect(suggestions.isNotEmpty, true);
      final bestSuggestion = suggestions.first;
      expect(
        SmartCategorizationService.shouldAutoAssign(
          bestSuggestion,
          threshold: 0.9,
        ),
        false,
      );
    });

    test('should handle multiple keyword matches', () {
      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'Bolt ride to mall',
        description: 'Shopping at Shoprite',
        availableCategories: testCategories,
        transactionType: TransactionType.expense,
      );

      expect(suggestions.isNotEmpty, true);
      // Should match transport for Bolt and food for Shoprite
      final transportSuggestions = suggestions.where(
        (s) => s.category.id == 'expense_transport',
      );
      final foodSuggestions = suggestions.where(
        (s) => s.category.id == 'expense_food',
      );

      expect(transportSuggestions.isNotEmpty, true);
      expect(foodSuggestions.isNotEmpty, true);
    });

    test('should prioritize exact keyword matches', () {
      final suggestions = SmartCategorizationService.getCategorySuggestions(
        title: 'Jumia food delivery',
        description: 'Dinner order',
        availableCategories: testCategories,
        transactionType: TransactionType.expense,
      );

      expect(suggestions.isNotEmpty, true);
      // Should prioritize food category over general shopping
      expect(suggestions.first.category.id, 'expense_food');
    });
  });
}
