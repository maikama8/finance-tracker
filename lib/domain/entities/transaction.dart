import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../value_objects/currency.dart';

/// Enum representing the type of transaction
enum TransactionType {
  income,
  expense,
}

/// Enum representing the synchronization status
enum SyncStatus {
  synced,
  pending,
  conflict,
}

/// Entity representing a financial transaction
class Transaction extends Equatable {
  final String id;
  final String userId;
  final Decimal amount;
  final Currency currency;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final String? notes;
  final String? receiptImageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.categoryId,
    required this.date,
    this.notes,
    this.receiptImageId,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  /// Create a copy of this transaction with updated fields
  Transaction copyWith({
    String? id,
    String? userId,
    Decimal? amount,
    Currency? currency,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? notes,
    String? receiptImageId,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptImageId: receiptImageId ?? this.receiptImageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        currency,
        type,
        categoryId,
        date,
        notes,
        receiptImageId,
        createdAt,
        updatedAt,
        syncStatus,
      ];

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount ${currency.code}, type: $type, categoryId: $categoryId, date: $date)';
  }
}
