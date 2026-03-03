import 'package:decimal/decimal.dart';
import '../entities/transaction.dart';
import '../value_objects/date_range.dart';

/// Input data for creating or updating a transaction
class TransactionInput {
  final Decimal amount;
  final String currencyCode;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String? notes;
  final String? receiptImageId;

  const TransactionInput({
    required this.amount,
    required this.currencyCode,
    required this.type,
    required this.categoryId,
    required this.date,
    this.notes,
    this.receiptImageId,
  });
}

/// Repository interface for Transaction operations
abstract class TransactionRepository {
  /// Create a new transaction
  Future<Transaction> create(String userId, TransactionInput input);

  /// Update an existing transaction
  Future<Transaction> update(String id, TransactionInput input);

  /// Delete a transaction by ID
  Future<void> delete(String id);

  /// Get a transaction by ID
  Future<Transaction?> getById(String id);

  /// Get all transactions with optional filters
  Future<List<Transaction>> getAll({
    required String userId,
    DateRange? range,
    String? categoryId,
  });

  /// Watch all transactions with optional filters (returns a stream)
  Stream<List<Transaction>> watchAll({
    required String userId,
    DateRange? range,
  });

  /// Calculate total balance from all transactions
  Future<Decimal> calculateBalance(String userId);

  /// Get spending breakdown by category for a date range
  Future<Map<String, Decimal>> getSpendingBreakdown({
    required String userId,
    required DateRange range,
  });
}
