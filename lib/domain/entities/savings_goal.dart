import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import '../value_objects/currency.dart';
import 'transaction.dart'; // For SyncStatus

/// Enum representing reminder frequency for savings goals
enum ReminderFrequency {
  daily,
  weekly,
  monthly,
}

/// Entity representing a savings goal
class SavingsGoal extends Equatable {
  final String id;
  final String userId;
  final String name;
  final Decimal targetAmount;
  final Currency currency;
  final Decimal currentAmount;
  final DateTime deadline;
  final bool reminderEnabled;
  final ReminderFrequency? reminderFrequency;
  final DateTime? lastReminderSent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currency,
    required this.currentAmount,
    required this.deadline,
    this.reminderEnabled = false,
    this.reminderFrequency,
    this.lastReminderSent,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
  });

  /// Calculate progress percentage (0-100)
  Decimal get progressPercentage {
    if (targetAmount == Decimal.zero) {
      return Decimal.zero;
    }
    // Convert to double for calculation, then back to Decimal
    final currentDouble = currentAmount.toDouble();
    final targetDouble = targetAmount.toDouble();
    final percentageDouble = (currentDouble / targetDouble) * 100.0;
    
    // Clamp between 0 and 100
    final clampedPercentage = percentageDouble.clamp(0.0, 100.0);
    return Decimal.parse(clampedPercentage.toStringAsFixed(2));
  }

  /// Check if the goal is completed
  bool get isCompleted => currentAmount >= targetAmount;

  /// Check if the goal deadline has passed
  bool get isOverdue => DateTime.now().isAfter(deadline) && !isCompleted;

  /// Create a copy of this savings goal with updated fields
  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    Decimal? targetAmount,
    Currency? currency,
    Decimal? currentAmount,
    DateTime? deadline,
    bool? reminderEnabled,
    ReminderFrequency? reminderFrequency,
    DateTime? lastReminderSent,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currency: currency ?? this.currency,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        targetAmount,
        currency,
        currentAmount,
        deadline,
        reminderEnabled,
        reminderFrequency,
        lastReminderSent,
        createdAt,
        updatedAt,
        syncStatus,
      ];

  @override
  String toString() {
    return 'SavingsGoal(id: $id, name: $name, progress: ${progressPercentage.toStringAsFixed(1)}%)';
  }
}
