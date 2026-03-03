import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/value_objects/currency.dart';
import '../../domain/value_objects/date_range.dart';
import '../data_sources/local/transaction_local_data_source.dart';

/// Implementation of TransactionRepository using local data source
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();

  TransactionRepositoryImpl(this._localDataSource);

  @override
  Future<Transaction> create(String userId, TransactionInput input) async {
    // Validate required fields
    if (input.amount <= Decimal.zero) {
      throw ArgumentError('Amount must be greater than zero');
    }

    // Get currency from code
    final currency = Currency.fromCode(input.currencyCode);
    if (currency == null) {
      throw ArgumentError('Invalid currency code: ${input.currencyCode}');
    }

    // Create transaction entity
    final now = DateTime.now();
    final transaction = Transaction(
      id: _uuid.v4(),
      userId: userId,
      amount: input.amount,
      currency: currency,
      type: input.type,
      categoryId: input.categoryId,
      date: input.date,
      notes: input.notes,
      receiptImageId: input.receiptImageId,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    // Save to local storage
    return await _localDataSource.create(transaction);
  }

  @override
  Future<Transaction> update(String id, TransactionInput input) async {
    // Get existing transaction
    final existing = await _localDataSource.getById(id);
    if (existing == null) {
      throw Exception('Transaction not found: $id');
    }

    // Validate required fields
    if (input.amount <= Decimal.zero) {
      throw ArgumentError('Amount must be greater than zero');
    }

    // Get currency from code
    final currency = Currency.fromCode(input.currencyCode);
    if (currency == null) {
      throw ArgumentError('Invalid currency code: ${input.currencyCode}');
    }

    // Update transaction
    final updated = existing.copyWith(
      amount: input.amount,
      currency: currency,
      type: input.type,
      categoryId: input.categoryId,
      date: input.date,
      notes: input.notes,
      receiptImageId: input.receiptImageId,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    return await _localDataSource.update(updated);
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
  }

  @override
  Future<Transaction?> getById(String id) async {
    return await _localDataSource.getById(id);
  }

  @override
  Future<List<Transaction>> getAll({
    required String userId,
    DateRange? range,
    String? categoryId,
  }) async {
    return await _localDataSource.getAll(
      userId: userId,
      dateRange: range,
      categoryId: categoryId,
    );
  }

  @override
  Stream<List<Transaction>> watchAll({
    required String userId,
    DateRange? range,
  }) {
    return _localDataSource.watchAll(
      userId: userId,
      dateRange: range,
    );
  }

  @override
  Future<Decimal> calculateBalance(String userId) async {
    // Get all transactions for the user
    final transactions = await _localDataSource.getAll(userId: userId);

    // Calculate balance: sum of income - sum of expenses
    Decimal balance = Decimal.zero;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        balance += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        balance -= transaction.amount;
      }
    }

    return balance;
  }

  @override
  Future<Map<String, Decimal>> getSpendingBreakdown({
    required String userId,
    required DateRange range,
  }) async {
    // Get all expense transactions in the date range
    final transactions = await _localDataSource.getAll(
      userId: userId,
      dateRange: range,
      type: TransactionType.expense,
    );

    // Group by category and sum amounts
    final Map<String, Decimal> breakdown = {};

    for (final transaction in transactions) {
      final categoryId = transaction.categoryId;
      final amount = transaction.amount;

      if (breakdown.containsKey(categoryId)) {
        breakdown[categoryId] = breakdown[categoryId]! + amount;
      } else {
        breakdown[categoryId] = amount;
      }
    }

    return breakdown;
  }
}
