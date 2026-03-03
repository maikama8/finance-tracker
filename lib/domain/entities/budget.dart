import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../value_objects/currency.dart';
import 'transaction.dart'; // For SyncStatus

/// Entity representing a monthly budget for a category
class Budget extends Equatable {
  final String id;
  final String userId;
  final String categoryId;
  final Decimal monthlyLimit;
  final Currency currency;
  final Decimal currentSpending;
  final int month; // 1-12
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.monthlyLimit,
    required this.currency,
    required this.currentSpending,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  /// Calculate percentage of budget used (0-100+)
  Decimal get percentageUsed {
    if (monthlyLimit == Decimal.zero) {
      return Decimal.zero;
    }
    // Convert to double for calculation, then back to Decimal
    final spendingDouble = currentSpending.toDouble();
    final limitDouble = monthlyLimit.toDouble();
    final percentageDouble = (spendingDouble / limitDouble) * 100.0;
    
    return Decimal.parse(percentageDouble.toStringAsFixed(2));
  }

  /// Check if spending is near the limit (>= 80%)
  bool get isNearLimit {
    return percentageUsed >= Decimal.fromInt(80);
  }

  /// Check if spending is over the limit (>= 100%)
  bool get isOverLimit {
    return percentageUsed >= Decimal.fromInt(100);
  }

  /// Get remaining budget amount
  Decimal get remainingAmount {
    final remaining = monthlyLimit - currentSpending;
    return remaining < Decimal.zero ? Decimal.zero : remaining;
  }

  /// Create a copy of this budget with updated fields
  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    Decimal? monthlyLimit,
    Currency? currency,
    Decimal? currentSpending,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currency: currency ?? this.currency,
      currentSpending: currentSpending ?? this.currentSpending,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        monthlyLimit,
        currency,
        currentSpending,
        month,
        year,
        createdAt,
        updatedAt,
        syncStatus,
      ];

  @override
  String toString() {
    return 'Budget(id: $id, categoryId: $categoryId, month: $month/$year, used: ${percentageUsed.toStringAsFixed(1)}%)';
  }
}
