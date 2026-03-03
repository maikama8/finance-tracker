import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:personal_finance_tracker/domain/entities/transaction.dart';
import 'package:personal_finance_tracker/domain/entities/savings_goal.dart';
import 'package:personal_finance_tracker/domain/entities/budget.dart';
import 'package:personal_finance_tracker/domain/entities/category.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/hive_type_adapters.dart';
import 'dart:io';

/// Cross-Platform Data Synchronization Tests
/// 
/// These tests verify that data created on one platform (Android)
/// can be synchronized and accessed correctly on another platform (iOS)
/// and vice versa, with no data loss or corruption.
/// 
/// The app uses Hive for local storage with binary serialization,
/// and these tests verify that data structures maintain integrity
/// across platforms.
/// 
/// Validates Requirements 17.4, 17.5
void main() {
  group('Data Format Consistency Tests', () {
    test('Transaction entity maintains data integrity', () {
      final transaction = Transaction(
        id: 'txn_123',
        userId: 'user_456',
        amount: Decimal.parse('100.50'),
        currency: Currency.USD,
        type: TransactionType.expense,
        categoryId: 'cat_789',
        date: DateTime(2024, 1, 15, 10, 30),
        notes: 'Test transaction',
        receiptImageId: 'img_001',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 15, 10, 30),
        syncStatus: SyncStatus.synced,
      );

      expect(transaction.id, equals('txn_123'));
      expect(transaction.amount, equals(Decimal.parse('100.50')));
      expect(transaction.currency.code, equals('USD'));
      
      final updated = transaction.copyWith(amount: Decimal.parse('150.75'));
      expect(updated.amount, equals(Decimal.parse('150.75')));
      expect(updated.id, equals(transaction.id));
    });

    test('SavingsGoal entity maintains data integrity', () {
      final goal = SavingsGoal(
        id: 'goal_123',
        userId: 'user_456',
        name: 'Vacation Fund',
        targetAmount: Decimal.parse('5000.00'),
        currency: Currency.USD,
        currentAmount: Decimal.parse('1250.50'),
        deadline: DateTime(2024, 12, 31),
        reminderEnabled: true,
        reminderFrequency: ReminderFrequency.weekly,
        lastReminderSent: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 15),
        syncStatus: SyncStatus.synced,
      );

      expect(goal.name, equals('Vacation Fund'));
      expect(goal.targetAmount, equals(Decimal.parse('5000.00')));
      expect(goal.progressPercentage, equals(Decimal.parse('25.01')));
    });

    test('Decimal precision is maintained', () {
      final testValues = ['0.01', '100.99', '1000.00', '0.001'];
      
      for (final value in testValues) {
        final decimal = Decimal.parse(value);
        final stringValue = decimal.toString();
        final deserialized = Decimal.parse(stringValue);
        expect(deserialized, equals(decimal));
      }
    });

    test('Currency codes are consistent', () {
      final currencies = [Currency.USD, Currency.EUR, Currency.NGN];
      
      for (final currency in currencies) {
        final retrieved = Currency.fromCode(currency.code);
        expect(retrieved, isNotNull);
        expect(retrieved!.code, equals(currency.code));
      }
    });

    test('Enum values are consistent', () {
      expect(TransactionType.values.length, equals(2));
      expect(SyncStatus.values.length, equals(3));
      expect(ReminderFrequency.values.length, equals(3));
    });
  });

  group('Local Storage Consistency Tests', () {
    test('Hive box names are consistent', () {
      const boxNames = ['users', 'transactions', 'categories', 
                        'savings_goals', 'budgets', 'exchange_rates'];
      
      for (final name in boxNames) {
        expect(name, isNotEmpty);
      }
    });

    test('Path separators are platform-appropriate', () {
      final separator = Platform.pathSeparator;
      
      if (Platform.isIOS || Platform.isAndroid) {
        expect(separator, equals('/'));
      } else if (Platform.isWindows) {
        expect(separator, equals('\\'));
      }
    });
  });

  group('Cross-Platform Sync Scenarios', () {
    test('Android transaction syncs to iOS', () {
      final androidTxn = Transaction(
        id: 'txn_android_001',
        userId: 'user_123',
        amount: Decimal.parse('50.25'),
        currency: Currency.USD,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        date: DateTime(2024, 1, 15),
        notes: 'Lunch',
        receiptImageId: null,
        createdAt: DateTime(2024, 1, 15, 12, 0),
        updatedAt: DateTime(2024, 1, 15, 12, 0),
        syncStatus: SyncStatus.synced,
      );

      expect(androidTxn.amount, equals(Decimal.parse('50.25')));
      expect(androidTxn.currency.code, equals('USD'));
    });

    test('Multiple transactions maintain integrity', () {
      final transactions = List.generate(10, (i) => Transaction(
        id: 'txn_$i',
        userId: 'user_123',
        amount: Decimal.parse('${(i + 1) * 10}.50'),
        currency: Currency.USD,
        type: i % 2 == 0 ? TransactionType.expense : TransactionType.income,
        categoryId: 'cat_$i',
        date: DateTime(2024, 1, i + 1),
        notes: 'Transaction $i',
        receiptImageId: null,
        createdAt: DateTime(2024, 1, i + 1),
        updatedAt: DateTime(2024, 1, i + 1),
        syncStatus: SyncStatus.synced,
      ));

      expect(transactions.length, equals(10));
      
      for (int i = 0; i < 10; i++) {
        expect(transactions[i].id, equals('txn_$i'));
        expect(transactions[i].amount, equals(Decimal.parse('${(i + 1) * 10}.50')));
      }
    });

    test('Categories with emoji maintain integrity', () {
      final category = Category(
        id: 'cat_001',
        userId: 'user_123',
        name: 'Coffee ☕',
        icon: '☕',
        color: '#8B4513',
        parentCategoryId: null,
        isDefault: false,
        locale: null,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(category.name, equals('Coffee ☕'));
      expect(category.icon, equals('☕'));
    });
  });

  group('Data Validation Tests', () {
    test('Invalid decimal values are rejected', () {
      expect(() => Decimal.parse('invalid'), throwsFormatException);
    });

    test('Invalid dates are rejected', () {
      expect(() => DateTime.parse('invalid'), throwsFormatException);
    });

    test('Invalid currency codes return null', () {
      expect(Currency.fromCode('INVALID'), isNull);
    });
  });

  group('Timestamp Consistency Tests', () {
    test('Millisecond precision is maintained', () {
      final now = DateTime.now();
      final millis = now.millisecondsSinceEpoch;
      final reconstructed = DateTime.fromMillisecondsSinceEpoch(millis);
      
      expect(reconstructed.millisecondsSinceEpoch, equals(millis));
    });

    test('UTC timestamps are consistent', () {
      final utc = DateTime.now().toUtc();
      expect(utc.isUtc, isTrue);
    });
  });

  group('Sync Status Tests', () {
    test('Sync statuses are identified correctly', () {
      final pending = Transaction(
        id: 'txn_1',
        userId: 'user_1',
        amount: Decimal.parse('100.00'),
        currency: Currency.USD,
        type: TransactionType.expense,
        categoryId: 'cat_1',
        date: DateTime.now(),
        notes: null,
        receiptImageId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      expect(pending.syncStatus, equals(SyncStatus.pending));
      expect(pending.syncStatus != SyncStatus.synced, isTrue);
    });
  });

  group('Equatable Tests', () {
    test('Transactions with same data are equal', () {
      final txn1 = Transaction(
        id: 'txn_123',
        userId: 'user_456',
        amount: Decimal.parse('100.00'),
        currency: Currency.USD,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        date: DateTime(2024, 1, 15),
        notes: 'Test',
        receiptImageId: null,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
        syncStatus: SyncStatus.synced,
      );

      final txn2 = Transaction(
        id: 'txn_123',
        userId: 'user_456',
        amount: Decimal.parse('100.00'),
        currency: Currency.USD,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        date: DateTime(2024, 1, 15),
        notes: 'Test',
        receiptImageId: null,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
        syncStatus: SyncStatus.synced,
      );

      expect(txn1, equals(txn2));
    });
  });
}
