import 'package:hive/hive.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/value_objects/date_range.dart';
import 'hive_database.dart';

/// Local data source for Transaction entities using Hive
class TransactionLocalDataSource {
  final HiveDatabase _database;

  TransactionLocalDataSource(this._database);

  /// Get the transactions box
  Box _getBox() => _database.getBox(HiveBoxNames.transactions);

  /// Create a new transaction
  Future<Transaction> create(Transaction transaction) async {
    final box = _getBox();
    await box.put(transaction.id, transaction);
    return transaction;
  }

  /// Update an existing transaction
  Future<Transaction> update(Transaction transaction) async {
    final box = _getBox();
    if (!box.containsKey(transaction.id)) {
      throw Exception('Transaction not found: ${transaction.id}');
    }
    await box.put(transaction.id, transaction);
    return transaction;
  }

  /// Delete a transaction by ID
  Future<void> delete(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// Get a transaction by ID
  Future<Transaction?> getById(String id) async {
    final box = _getBox();
    return box.get(id) as Transaction?;
  }

  /// Get all transactions for a user
  Future<List<Transaction>> getAll({
    required String userId,
    DateRange? dateRange,
    String? categoryId,
    TransactionType? type,
  }) async {
    final box = _getBox();
    final allTransactions = box.values.cast<Transaction>();

    // Filter by userId
    var filtered = allTransactions.where((t) => t.userId == userId);

    // Filter by date range if provided
    if (dateRange != null) {
      filtered = filtered.where((t) => dateRange.contains(t.date));
    }

    // Filter by category if provided
    if (categoryId != null) {
      filtered = filtered.where((t) => t.categoryId == categoryId);
    }

    // Filter by type if provided
    if (type != null) {
      filtered = filtered.where((t) => t.type == type);
    }

    // Sort by date descending (newest first)
    final result = filtered.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

  /// Get transactions by date range
  Future<List<Transaction>> getByDateRange({
    required String userId,
    required DateRange dateRange,
  }) async {
    return getAll(userId: userId, dateRange: dateRange);
  }

  /// Get transactions by category
  Future<List<Transaction>> getByCategory({
    required String userId,
    required String categoryId,
  }) async {
    return getAll(userId: userId, categoryId: categoryId);
  }

  /// Get transactions by type (income or expense)
  Future<List<Transaction>> getByType({
    required String userId,
    required TransactionType type,
  }) async {
    return getAll(userId: userId, type: type);
  }

  /// Get all pending sync transactions
  Future<List<Transaction>> getPendingSync(String userId) async {
    final box = _getBox();
    final allTransactions = box.values.cast<Transaction>();

    return allTransactions
        .where((t) => t.userId == userId && t.syncStatus == SyncStatus.pending)
        .toList();
  }

  /// Get all transactions with conflicts
  Future<List<Transaction>> getConflicts(String userId) async {
    final box = _getBox();
    final allTransactions = box.values.cast<Transaction>();

    return allTransactions
        .where((t) => t.userId == userId && t.syncStatus == SyncStatus.conflict)
        .toList();
  }

  /// Watch all transactions for a user (returns a stream)
  Stream<List<Transaction>> watchAll({
    required String userId,
    DateRange? dateRange,
    String? categoryId,
    TransactionType? type,
  }) {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getAll(
        userId: userId,
        dateRange: dateRange,
        categoryId: categoryId,
        type: type,
      );
    });
  }

  /// Get count of transactions for a user
  Future<int> getCount(String userId) async {
    final box = _getBox();
    final allTransactions = box.values.cast<Transaction>();
    return allTransactions.where((t) => t.userId == userId).length;
  }

  /// Clear all transactions for a user
  Future<void> clearAll(String userId) async {
    final box = _getBox();
    final allTransactions = box.values.cast<Transaction>();
    final userTransactionIds = allTransactions
        .where((t) => t.userId == userId)
        .map((t) => t.id)
        .toList();

    for (final id in userTransactionIds) {
      await box.delete(id);
    }
  }

  /// Batch create multiple transactions
  Future<void> batchCreate(List<Transaction> transactions) async {
    final box = _getBox();
    final Map<String, Transaction> entries = {
      for (var t in transactions) t.id: t
    };
    await box.putAll(entries);
  }

  /// Batch update multiple transactions
  Future<void> batchUpdate(List<Transaction> transactions) async {
    await batchCreate(transactions); // Same implementation as create
  }

  /// Batch delete multiple transactions
  Future<void> batchDelete(List<String> ids) async {
    final box = _getBox();
    await box.deleteAll(ids);
  }
}
