import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/domain/entities/budget.dart';
import 'package:personal_finance_tracker/domain/services/budget_tracker.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';

void main() {
  group('BudgetInput', () {
    test('should create BudgetInput with required fields', () {
      final input = BudgetInput(
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        month: 1,
        year: 2024,
      );

      expect(input.categoryId, 'cat_1');
      expect(input.monthlyLimit, Decimal.fromInt(1000));
      expect(input.currency, Currency.USD);
      expect(input.month, 1);
      expect(input.year, 2024);
    });
  });

  group('BudgetStatus', () {
    test('should create BudgetStatus with all fields', () {
      final budget = Budget(
        id: 'budget_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(500),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final status = BudgetStatus(
        budget: budget,
        percentageUsed: Decimal.fromInt(50),
        remainingAmount: Decimal.fromInt(500),
        isNearLimit: false,
        isOverLimit: false,
      );

      expect(status.budget, budget);
      expect(status.percentageUsed, Decimal.fromInt(50));
      expect(status.remainingAmount, Decimal.fromInt(500));
      expect(status.isNearLimit, false);
      expect(status.isOverLimit, false);
    });
  });

  group('BudgetAlert', () {
    test('should create BudgetAlert with all fields', () {
      final budget = Budget(
        id: 'budget_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(800),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final timestamp = DateTime.now();
      final alert = BudgetAlert(
        budget: budget,
        type: BudgetAlertType.nearLimit,
        percentageUsed: Decimal.fromInt(80),
        timestamp: timestamp,
      );

      expect(alert.budget, budget);
      expect(alert.type, BudgetAlertType.nearLimit);
      expect(alert.percentageUsed, Decimal.fromInt(80));
      expect(alert.timestamp, timestamp);
    });

    test('should support both alert types', () {
      expect(BudgetAlertType.nearLimit, isNotNull);
      expect(BudgetAlertType.overLimit, isNotNull);
    });
  });

  group('Budget Entity - Computed Properties', () {
    test('should calculate percentageUsed correctly', () {
      final budget = Budget(
        id: 'budget_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(500),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.percentageUsed, Decimal.parse('50.00'));
    });

    test('should detect near limit at 80%', () {
      final budget = Budget(
        id: 'budget_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(800),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.isNearLimit, true);
      expect(budget.isOverLimit, false);
    });

    test('should detect over limit at 100%', () {
      final budget = Budget(
        id: 'budget_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(1000),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.isNearLimit, true);
      expect(budget.isOverLimit, true);
    });

    test('should detect over limit above 100%', () {
      final budget = Budget(
        id: 'budget_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(1200),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.isNearLimit, true);
      expect(budget.isOverLimit, true);
      expect(budget.percentageUsed, Decimal.parse('120.00'));
    });

    test('should calculate remaining amount correctly', () {
      final budget = Budget(
        id: 'budget_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(300),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.remainingAmount, Decimal.fromInt(700));
    });

    test('should return zero remaining when over budget', () {
      final budget = Budget(
        id: 'budget_1',
        userId: 'user_1',
        categoryId: 'cat_1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(1200),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.remainingAmount, Decimal.zero);
    });
  });
}
