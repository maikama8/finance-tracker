import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/domain/entities/transaction.dart';
import 'package:personal_finance_tracker/domain/repositories/transaction_repository.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';

void main() {
  group('TransactionInput Validation', () {
    test('should create valid transaction input', () {
      final input = TransactionInput(
        amount: Decimal.parse('100.50'),
        currencyCode: 'USD',
        type: TransactionType.expense,
        categoryId: 'cat1',
        date: DateTime(2024, 1, 15),
        notes: 'Test transaction',
      );

      expect(input.amount, Decimal.parse('100.50'));
      expect(input.currencyCode, 'USD');
      expect(input.type, TransactionType.expense);
      expect(input.categoryId, 'cat1');
      expect(input.notes, 'Test transaction');
    });

    test('should create transaction input with optional fields as null', () {
      final input = TransactionInput(
        amount: Decimal.parse('100'),
        currencyCode: 'USD',
        type: TransactionType.income,
        categoryId: 'cat1',
        date: DateTime(2024, 1, 15),
      );

      expect(input.notes, isNull);
      expect(input.receiptImageId, isNull);
    });
  });

  group('Balance Calculation Logic', () {
    test('should calculate balance correctly with income and expenses', () {
      // Simulate transactions
      final transactions = [
        Transaction(
          id: '1',
          userId: 'user1',
          amount: Decimal.parse('1000'),
          currency: Currency.USD,
          type: TransactionType.income,
          categoryId: 'cat1',
          date: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          userId: 'user1',
          amount: Decimal.parse('300'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat2',
          date: DateTime(2024, 1, 20),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '3',
          userId: 'user1',
          amount: Decimal.parse('200'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat3',
          date: DateTime(2024, 1, 25),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Calculate balance manually (simulating repository logic)
      Decimal balance = Decimal.zero;
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          balance += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          balance -= transaction.amount;
        }
      }

      // 1000 - 300 - 200 = 500
      expect(balance, Decimal.parse('500'));
    });

    test('should return zero balance when no transactions exist', () {
      final transactions = <Transaction>[];

      Decimal balance = Decimal.zero;
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          balance += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          balance -= transaction.amount;
        }
      }

      expect(balance, Decimal.zero);
    });

    test('should handle only income transactions', () {
      final transactions = [
        Transaction(
          id: '1',
          userId: 'user1',
          amount: Decimal.parse('1000'),
          currency: Currency.USD,
          type: TransactionType.income,
          categoryId: 'cat1',
          date: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          userId: 'user1',
          amount: Decimal.parse('500'),
          currency: Currency.USD,
          type: TransactionType.income,
          categoryId: 'cat2',
          date: DateTime(2024, 1, 20),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      Decimal balance = Decimal.zero;
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          balance += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          balance -= transaction.amount;
        }
      }

      expect(balance, Decimal.parse('1500'));
    });

    test('should handle only expense transactions', () {
      final transactions = [
        Transaction(
          id: '1',
          userId: 'user1',
          amount: Decimal.parse('300'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat1',
          date: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          userId: 'user1',
          amount: Decimal.parse('200'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat2',
          date: DateTime(2024, 1, 20),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      Decimal balance = Decimal.zero;
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          balance += transaction.amount;
        } else if (transaction.type == TransactionType.expense) {
          balance -= transaction.amount;
        }
      }

      expect(balance, Decimal.parse('-500'));
    });
  });

  group('Spending Breakdown Logic', () {
    test('should group expenses by category', () {
      final transactions = [
        Transaction(
          id: '1',
          userId: 'user1',
          amount: Decimal.parse('100'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat1',
          date: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          userId: 'user1',
          amount: Decimal.parse('150'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat1',
          date: DateTime(2024, 1, 20),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '3',
          userId: 'user1',
          amount: Decimal.parse('200'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat2',
          date: DateTime(2024, 1, 25),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Simulate spending breakdown logic
      final Map<String, Decimal> breakdown = {};
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.expense) {
          final categoryId = transaction.categoryId;
          final amount = transaction.amount;

          if (breakdown.containsKey(categoryId)) {
            breakdown[categoryId] = breakdown[categoryId]! + amount;
          } else {
            breakdown[categoryId] = amount;
          }
        }
      }

      expect(breakdown.length, 2);
      expect(breakdown['cat1'], Decimal.parse('250'));
      expect(breakdown['cat2'], Decimal.parse('200'));
    });

    test('should exclude income transactions from breakdown', () {
      final transactions = [
        Transaction(
          id: '1',
          userId: 'user1',
          amount: Decimal.parse('1000'),
          currency: Currency.USD,
          type: TransactionType.income,
          categoryId: 'cat1',
          date: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          userId: 'user1',
          amount: Decimal.parse('200'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat2',
          date: DateTime(2024, 1, 20),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final Map<String, Decimal> breakdown = {};
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.expense) {
          final categoryId = transaction.categoryId;
          final amount = transaction.amount;

          if (breakdown.containsKey(categoryId)) {
            breakdown[categoryId] = breakdown[categoryId]! + amount;
          } else {
            breakdown[categoryId] = amount;
          }
        }
      }

      expect(breakdown.length, 1);
      expect(breakdown.containsKey('cat1'), false);
      expect(breakdown['cat2'], Decimal.parse('200'));
    });

    test('should return empty map when no expenses exist', () {
      final transactions = <Transaction>[];

      final Map<String, Decimal> breakdown = {};
      for (final transaction in transactions) {
        if (transaction.type == TransactionType.expense) {
          final categoryId = transaction.categoryId;
          final amount = transaction.amount;

          if (breakdown.containsKey(categoryId)) {
            breakdown[categoryId] = breakdown[categoryId]! + amount;
          } else {
            breakdown[categoryId] = amount;
          }
        }
      }

      expect(breakdown.isEmpty, true);
    });
  });

  group('Currency Validation', () {
    test('should validate supported currency codes', () {
      expect(Currency.fromCode('USD'), isNotNull);
      expect(Currency.fromCode('EUR'), isNotNull);
      expect(Currency.fromCode('NGN'), isNotNull);
      expect(Currency.fromCode('GBP'), isNotNull);
      expect(Currency.fromCode('JPY'), isNotNull);
    });

    test('should return null for invalid currency code', () {
      expect(Currency.fromCode('INVALID'), isNull);
      expect(Currency.fromCode('XXX'), isNull);
    });

    test('should handle case-insensitive currency codes', () {
      expect(Currency.fromCode('usd'), isNotNull);
      expect(Currency.fromCode('Eur'), isNotNull);
      expect(Currency.fromCode('ngn'), isNotNull);
    });
  });

  group('Transaction Entity', () {
    test('should create transaction with all required fields', () {
      final transaction = Transaction(
        id: 'tx1',
        userId: 'user1',
        amount: Decimal.parse('100.50'),
        currency: Currency.USD,
        type: TransactionType.expense,
        categoryId: 'cat1',
        date: DateTime(2024, 1, 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(transaction.id, 'tx1');
      expect(transaction.userId, 'user1');
      expect(transaction.amount, Decimal.parse('100.50'));
      expect(transaction.currency, Currency.USD);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.categoryId, 'cat1');
      expect(transaction.syncStatus, SyncStatus.pending);
    });

    test('should support copyWith for updates', () {
      final original = Transaction(
        id: 'tx1',
        userId: 'user1',
        amount: Decimal.parse('100'),
        currency: Currency.USD,
        type: TransactionType.expense,
        categoryId: 'cat1',
        date: DateTime(2024, 1, 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        amount: Decimal.parse('200'),
        type: TransactionType.income,
      );

      expect(updated.id, original.id);
      expect(updated.amount, Decimal.parse('200'));
      expect(updated.type, TransactionType.income);
      expect(updated.categoryId, original.categoryId);
    });
  });
}
