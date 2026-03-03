import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/domain/entities/savings_goal.dart';
import 'package:personal_finance_tracker/domain/services/savings_goal_manager.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';

void main() {
  const testUserId = 'test-user-123';

  group('SavingsGoalInput Validation', () {
    test('should create valid savings goal input', () {
      final input = SavingsGoalInput(
        name: 'Vacation Fund',
        targetAmount: Decimal.parse('5000'),
        currency: Currency.USD,
        deadline: DateTime.now().add(const Duration(days: 365)),
        reminderEnabled: true,
        reminderFrequency: ReminderFrequency.monthly,
      );

      expect(input.name, 'Vacation Fund');
      expect(input.targetAmount, Decimal.parse('5000'));
      expect(input.currency, Currency.USD);
      expect(input.reminderEnabled, true);
      expect(input.reminderFrequency, ReminderFrequency.monthly);
    });

    test('should throw ArgumentError for empty name', () {
      final input = SavingsGoalInput(
        name: '',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        deadline: DateTime.now().add(const Duration(days: 30)),
      );

      expect(
        () => input.validate(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for zero target amount', () {
      final input = SavingsGoalInput(
        name: 'Test Goal',
        targetAmount: Decimal.zero,
        currency: Currency.USD,
        deadline: DateTime.now().add(const Duration(days: 30)),
      );

      expect(
        () => input.validate(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for negative target amount', () {
      final input = SavingsGoalInput(
        name: 'Test Goal',
        targetAmount: Decimal.parse('-100'),
        currency: Currency.USD,
        deadline: DateTime.now().add(const Duration(days: 30)),
      );

      expect(
        () => input.validate(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for past deadline', () {
      final input = SavingsGoalInput(
        name: 'Test Goal',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(
        () => input.validate(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError when reminder enabled without frequency', () {
      final input = SavingsGoalInput(
        name: 'Test Goal',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        deadline: DateTime.now().add(const Duration(days: 30)),
        reminderEnabled: true,
        reminderFrequency: null,
      );

      expect(
        () => input.validate(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Suggested Contribution Calculator Logic', () {
    test('should calculate daily contribution suggestion', () {
      final targetAmount = Decimal.parse('1000');
      final currentAmount = Decimal.zero;
      final daysUntilDeadline = 100;

      final remainingAmount = targetAmount - currentAmount;
      final result = remainingAmount / Decimal.fromInt(daysUntilDeadline);
      final rounded = Decimal.parse(result.toDouble().toStringAsFixed(2));

      // Should be 1000 / 100 = 10.00 per day
      expect(rounded, Decimal.parse('10.00'));
    });

    test('should calculate weekly contribution suggestion', () {
      final targetAmount = Decimal.parse('2100');
      final currentAmount = Decimal.zero;
      final daysUntilDeadline = 70; // 10 weeks

      final remainingAmount = targetAmount - currentAmount;
      final weeksUntilDeadline = (daysUntilDeadline / 7).ceil();
      final result = remainingAmount / Decimal.fromInt(weeksUntilDeadline);
      final rounded = Decimal.parse(result.toDouble().toStringAsFixed(2));

      // Should be 2100 / 10 = 210.00 per week
      expect(rounded, Decimal.parse('210.00'));
    });

    test('should calculate monthly contribution suggestion', () {
      final targetAmount = Decimal.parse('3000');
      final currentAmount = Decimal.zero;
      final daysUntilDeadline = 90; // 3 months

      final remainingAmount = targetAmount - currentAmount;
      final monthsUntilDeadline = (daysUntilDeadline / 30).ceil();
      final result = remainingAmount / Decimal.fromInt(monthsUntilDeadline);
      final rounded = Decimal.parse(result.toDouble().toStringAsFixed(2));

      // Should be 3000 / 3 = 1000.00 per month
      expect(rounded, Decimal.parse('1000.00'));
    });

    test('should account for existing contributions', () {
      final targetAmount = Decimal.parse('1000');
      final currentAmount = Decimal.parse('400');
      final daysUntilDeadline = 100;

      final remainingAmount = targetAmount - currentAmount;
      final result = remainingAmount / Decimal.fromInt(daysUntilDeadline);
      final rounded = Decimal.parse(result.toDouble().toStringAsFixed(2));

      // Should be (1000 - 400) / 100 = 6.00 per day
      expect(rounded, Decimal.parse('6.00'));
    });

    test('should return zero for completed goals', () {
      final targetAmount = Decimal.parse('500');
      final currentAmount = Decimal.parse('500');

      final remainingAmount = targetAmount - currentAmount;

      expect(remainingAmount, Decimal.zero);
    });

    test('should round to 2 decimal places', () {
      final targetAmount = Decimal.parse('1000');
      final currentAmount = Decimal.zero;
      final daysUntilDeadline = 33;

      final remainingAmount = targetAmount - currentAmount;
      final result = remainingAmount / Decimal.fromInt(daysUntilDeadline);
      final rounded = Decimal.parse(result.toDouble().toStringAsFixed(2));

      // 1000 / 33 = 30.303030... should round to 30.30
      expect(rounded, Decimal.parse('30.30'));
    });

    test('should handle very small daily amounts', () {
      final targetAmount = Decimal.parse('100');
      final currentAmount = Decimal.zero;
      final daysUntilDeadline = 365;

      final remainingAmount = targetAmount - currentAmount;
      final result = remainingAmount / Decimal.fromInt(daysUntilDeadline);
      final rounded = Decimal.parse(result.toDouble().toStringAsFixed(2));

      // 100 / 365 = 0.273972... should round to 0.27
      expect(rounded, Decimal.parse('0.27'));
    });

    test('should handle large target amounts', () {
      final targetAmount = Decimal.parse('100000');
      final currentAmount = Decimal.zero;
      final daysUntilDeadline = 365;

      final remainingAmount = targetAmount - currentAmount;
      final result = remainingAmount / Decimal.fromInt(daysUntilDeadline);
      final rounded = Decimal.parse(result.toDouble().toStringAsFixed(2));

      // 100000 / 365 = 273.972602... should round to 273.97
      expect(rounded, Decimal.parse('273.97'));
    });
  });

  group('SavingsGoal Entity', () {
    test('should calculate progress percentage correctly', () {
      final goal = SavingsGoal(
        id: 'goal1',
        userId: testUserId,
        name: 'Test Goal',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        currentAmount: Decimal.parse('250'),
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressPercentage, Decimal.parse('25.00'));
    });

    test('should return 100% when goal is completed', () {
      final goal = SavingsGoal(
        id: 'goal1',
        userId: testUserId,
        name: 'Test Goal',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        currentAmount: Decimal.parse('1000'),
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.progressPercentage, Decimal.parse('100.00'));
      expect(goal.isCompleted, true);
    });

    test('should handle over-contribution', () {
      final goal = SavingsGoal(
        id: 'goal1',
        userId: testUserId,
        name: 'Test Goal',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        currentAmount: Decimal.parse('1200'),
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Progress should be clamped at 100%
      expect(goal.progressPercentage, Decimal.parse('100.00'));
      expect(goal.isCompleted, true);
    });

    test('should identify overdue goals', () {
      final goal = SavingsGoal(
        id: 'goal1',
        userId: testUserId,
        name: 'Test Goal',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        currentAmount: Decimal.parse('500'),
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.isOverdue, true);
      expect(goal.isCompleted, false);
    });

    test('should not mark completed goals as overdue', () {
      final goal = SavingsGoal(
        id: 'goal1',
        userId: testUserId,
        name: 'Test Goal',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        currentAmount: Decimal.parse('1000'),
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(goal.isCompleted, true);
      expect(goal.isOverdue, false);
    });

    test('should support copyWith for updates', () {
      final original = SavingsGoal(
        id: 'goal1',
        userId: testUserId,
        name: 'Original Name',
        targetAmount: Decimal.parse('1000'),
        currency: Currency.USD,
        currentAmount: Decimal.parse('100'),
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        currentAmount: Decimal.parse('250'),
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Updated Name');
      expect(updated.currentAmount, Decimal.parse('250'));
      expect(updated.targetAmount, original.targetAmount);
    });
  });
}
