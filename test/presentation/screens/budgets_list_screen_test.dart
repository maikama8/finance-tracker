import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/application/state/auth_provider.dart';
import 'package:personal_finance_tracker/application/state/budget_provider.dart';
import 'package:personal_finance_tracker/application/state/dashboard_provider.dart';
import 'package:personal_finance_tracker/domain/entities/budget.dart';
import 'package:personal_finance_tracker/domain/entities/category.dart';
import 'package:personal_finance_tracker/domain/entities/user.dart';
import 'package:personal_finance_tracker/domain/services/budget_tracker.dart';
import 'package:personal_finance_tracker/domain/services/category_service.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/presentation/screens/budgets_list_screen.dart';

final _testUser = User(
  id: 'user-1',
  email: 'test@example.com',
  displayName: 'Test User',
  locale: const Locale('en'),
  baseCurrency: Currency.USD,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

class _FakeBudgetTracker implements BudgetTracker {
  @override
  Future<Budget> create(String userId, BudgetInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Budget>> getAll(String userId) async => [];

  @override
  Future<BudgetStatus> getStatus(String budgetId) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetMonthlyBudgets(String userId) async {}

  @override
  Future<Budget> update(String id, BudgetInput input) {
    throw UnimplementedError();
  }

  @override
  Stream<BudgetAlert> watchAlerts(String userId) => const Stream.empty();
}

class _FakeCategoryService implements CategoryService {
  @override
  Future<bool> hasTransactions(String categoryId) async => false;

  @override
  Future<Category> createCustomCategory(String userId, CategoryInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCategory(String id, String reassignToCategoryId) async {}

  @override
  Future<List<Category>> getAllCategories(String userId) async => [];

  @override
  Future<List<Category>> getChildCategories(String parentCategoryId, String userId) async => [];

  @override
  Future<Category?> getCategoryById(String id) async => null;

  @override
  Future<CategoryHierarchy> getCategoryTree(String userId) async => const CategoryHierarchy({});

  @override
  Future<List<Category>> getDefaultCategories(Locale locale) async => [];

  @override
  Future<Category> updateCategory(String id, CategoryInput input) {
    throw UnimplementedError();
  }
}

void main() {
  Future<void> pumpBudgetsScreen(
    WidgetTester tester, {
    User? user,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => user),
          budgetTrackerProvider.overrideWith((ref) => _FakeBudgetTracker()),
          categoryServiceProvider.overrideWith((ref) => _FakeCategoryService()),
        ],
        child: const MaterialApp(
          home: BudgetsListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('BudgetsListScreen shows login prompt when user is null',
      (WidgetTester tester) async {
    await pumpBudgetsScreen(tester);

    expect(find.text('Please log in to view budgets'), findsOneWidget);
  });

  testWidgets('BudgetsListScreen has correct app bar title',
      (WidgetTester tester) async {
    await pumpBudgetsScreen(tester, user: _testUser);

    expect(find.text('Budgets'), findsOneWidget);
  });

  testWidgets('BudgetsListScreen has add button in app bar',
      (WidgetTester tester) async {
    await pumpBudgetsScreen(tester, user: _testUser);

    expect(find.byIcon(Icons.add), findsWidgets);
  });
}
