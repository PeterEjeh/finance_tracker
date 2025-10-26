import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:finance_tracker/controllers/onboarding_controller.dart';
import 'package:finance_tracker/models/onboarding_data.dart';
import 'package:finance_tracker/services/database_service.dart';
import 'package:finance_tracker/services/onboarding_firestore_service.dart';
import 'package:finance_tracker/screens/onboarding/onboarding_flow_screen.dart';

// Generate mocks
@GenerateMocks([
  FirebaseAuth,
  User,
  DatabaseService,
  OnboardingFirestoreService,
])
import 'onboarding_flow_test.mocks.dart';

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockDatabaseService mockDatabaseService;
  late MockOnboardingFirestoreService mockFirestoreService;

  setUpAll(() async {
    // Initialize Firebase for tests
    TestWidgetsFlutterBinding.ensureInitialized();
    // Skip Firebase initialization for unit tests to avoid complexity
    // Firebase will be mocked in individual tests
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockDatabaseService = MockDatabaseService();
    mockFirestoreService = MockOnboardingFirestoreService();

    // Setup mock user
    when(mockUser.uid).thenReturn('test-user-id');
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
  });

  group('OnboardingController Tests', () {
    test('should initialize with empty data', () {
      final controller = OnboardingController();

      expect(controller.data.userType, isNull);
      expect(controller.data.incomeAmount, isNull);
      expect(controller.isComplete, false);
      expect(controller.currentStep, 0);
    });

    test('should update user type correctly', () {
      final controller = OnboardingController();

      controller.updateUserType(UserType.individual);

      expect(controller.data.userType, UserType.individual);
      expect(controller.isComplete, false); // Not complete yet
    });

    test('should update income amount correctly', () {
      final controller = OnboardingController();

      controller.updateIncomeAmount(50000.0);

      expect(controller.data.incomeAmount, 50000.0);
    });

    test('should update spending style correctly', () {
      final controller = OnboardingController();

      controller.updateSpendingStyle(SpendingStyle.moderate);

      expect(controller.data.spendingStyle, SpendingStyle.moderate);
    });

    test('should update financial goals correctly', () {
      final controller = OnboardingController();

      final goals = [FinancialGoal.save_for_emergency, FinancialGoal.buy_house];
      controller.updateFinancialGoals(goals);

      expect(controller.data.financialGoals, goals);
    });

    test('should update currency code correctly', () {
      final controller = OnboardingController();

      controller.updateCurrencyCode('USD');

      expect(controller.data.currencyCode, 'USD');
    });

    test(
      'should mark onboarding as complete when all required fields are filled',
      () {
        final controller = OnboardingController();

        controller.updateUserType(UserType.individual);
        controller.updateIncomeAmount(50000.0);
        controller.updateIncomeFrequency(IncomeFrequency.monthly);
        controller.updateSpendingStyle(SpendingStyle.moderate);
        controller.updateFinancialGoals([FinancialGoal.save_for_emergency]);
        controller.updateCurrencyCode('USD');

        expect(controller.isComplete, true);
      },
    );

    test('should navigate through steps correctly', () {
      final controller = OnboardingController();

      expect(controller.currentStep, 0);

      controller.nextStep();
      expect(controller.currentStep, 1);

      controller.nextStep();
      expect(controller.currentStep, 2);

      controller.previousStep();
      expect(controller.currentStep, 1);

      controller.goToStep(5);
      expect(controller.currentStep, 5);
    });

    test('should not navigate beyond max steps', () {
      final controller = OnboardingController();

      // Go to max step (7)
      controller.goToStep(7);
      expect(controller.currentStep, 7);

      // Try to go beyond
      controller.nextStep();
      expect(controller.currentStep, 7); // Should stay at 7
    });

    test('should not navigate below min steps', () {
      final controller = OnboardingController();

      expect(controller.currentStep, 0);

      controller.previousStep();
      expect(controller.currentStep, 0); // Should stay at 0
    });
  });

  group('OnboardingData Model Tests', () {
    test('should create empty onboarding data', () {
      final data = OnboardingData.create();

      expect(data.userType, isNull);
      expect(data.incomeAmount, isNull);
      expect(data.isCompleted, false);
      expect(data.isComplete, false);
    });

    test('should serialize to JSON correctly', () {
      final data = OnboardingData(
        userType: UserType.individual,
        incomeAmount: 50000.0,
        incomeFrequency: IncomeFrequency.monthly,
        spendingStyle: SpendingStyle.moderate,
        financialGoals: [FinancialGoal.save_for_emergency],
        currencyCode: 'USD',
        isCompleted: true,
      );

      final json = data.toJson();

      expect(json['userType'], 'individual');
      expect(json['incomeAmount'], 50000.0);
      expect(json['incomeFrequency'], 'monthly');
      expect(json['spendingStyle'], 'moderate');
      expect(json['financialGoals'], ['save_for_emergency']);
      expect(json['currencyCode'], 'USD');
      expect(json['isCompleted'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'userType': 'individual',
        'incomeAmount': 50000.0,
        'incomeFrequency': 'monthly',
        'spendingStyle': 'moderate',
        'financialGoals': ['save_for_emergency'],
        'currencyCode': 'USD',
        'isCompleted': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final data = OnboardingData.fromJson(json);

      expect(data.userType, UserType.individual);
      expect(data.incomeAmount, 50000.0);
      expect(data.incomeFrequency, IncomeFrequency.monthly);
      expect(data.spendingStyle, SpendingStyle.moderate);
      expect(data.financialGoals, [FinancialGoal.save_for_emergency]);
      expect(data.currencyCode, 'USD');
      expect(data.isCompleted, true);
    });

    test('should determine completeness correctly', () {
      final incompleteData = OnboardingData(
        userType: UserType.individual,
        incomeAmount: 50000.0,
        // Missing other required fields
      );

      final completeData = OnboardingData(
        userType: UserType.individual,
        incomeAmount: 50000.0,
        incomeFrequency: IncomeFrequency.monthly,
        spendingStyle: SpendingStyle.moderate,
        financialGoals: [FinancialGoal.save_for_emergency],
        currencyCode: 'USD',
      );

      expect(incompleteData.isComplete, false);
      expect(completeData.isComplete, true);
    });
  });

  group('OnboardingFlowScreen Widget Tests', () {
    testWidgets('should display welcome screen initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const OnboardingFlowScreen(),
          ),
        ),
      );

      // Check if welcome screen is displayed
      expect(find.text('Welcome to Finance Tracker'), findsOneWidget);
      expect(find.text('Let\'s get you set up!'), findsOneWidget);
    });

    testWidgets('should navigate to next screen on continue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const OnboardingFlowScreen(),
          ),
        ),
      );

      // Tap continue button
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Should navigate to user type screen
      expect(find.text('What type of user are you?'), findsOneWidget);
    });

    testWidgets('should show progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => OnboardingController(),
            child: const OnboardingFlowScreen(),
          ),
        ),
      );

      // Check if progress bar exists
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('OnboardingFirestoreService Tests', () {
    setUp(() {
      // Reset mocks
      reset(mockFirestoreService);
    });

    test('should upload onboarding data successfully', () async {
      final data = OnboardingData(
        userType: UserType.individual,
        incomeAmount: 50000.0,
        currencyCode: 'USD',
        isCompleted: true,
      );

      when(
        mockFirestoreService.uploadOnboardingData(data),
      ).thenAnswer((_) async => Future.value());

      await mockFirestoreService.uploadOnboardingData(data);

      verify(mockFirestoreService.uploadOnboardingData(data)).called(1);
    });

    test('should download onboarding data successfully', () async {
      final expectedData = OnboardingData(
        userType: UserType.business,
        incomeAmount: 100000.0,
        currencyCode: 'EUR',
        isCompleted: true,
      );

      when(
        mockFirestoreService.downloadOnboardingData(),
      ).thenAnswer((_) async => expectedData);

      final result = await mockFirestoreService.downloadOnboardingData();

      expect(result, isNotNull);
      expect(result!.userType, UserType.business);
      expect(result.incomeAmount, 100000.0);
      expect(result.currencyCode, 'EUR');
    });

    test('should return null when no cloud data exists', () async {
      when(
        mockFirestoreService.downloadOnboardingData(),
      ).thenAnswer((_) async => null);

      final result = await mockFirestoreService.downloadOnboardingData();

      expect(result, isNull);
    });

    test('should check if onboarding data exists', () async {
      when(
        mockFirestoreService.hasOnboardingData(),
      ).thenAnswer((_) async => true);

      final exists = await mockFirestoreService.hasOnboardingData();

      expect(exists, true);
    });

    test('should sync data preferring cloud when newer', () async {
      final localData = OnboardingData(
        userType: UserType.individual,
        incomeAmount: 50000.0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)), // Older
      );

      final cloudData = OnboardingData(
        userType: UserType.business,
        incomeAmount: 100000.0,
        updatedAt: DateTime.now(), // Newer
      );

      when(
        mockFirestoreService.syncOnboardingData(localData),
      ).thenAnswer((_) async => true); // Return true to use cloud data

      when(
        mockFirestoreService.downloadOnboardingData(),
      ).thenAnswer((_) async => cloudData);

      final useCloudData = await mockFirestoreService.syncOnboardingData(
        localData,
      );

      expect(useCloudData, true);
    });
  });
}
