import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/services/savings_goal_manager.dart';
import '../data_sources/local/savings_goal_local_data_source.dart';

/// Implementation of SavingsGoalManager using local data source
class SavingsGoalManagerImpl implements SavingsGoalManager {
  final SavingsGoalLocalDataSource _localDataSource;
  final Uuid _uuid;

  SavingsGoalManagerImpl(
    this._localDataSource, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<SavingsGoal> create(String userId, SavingsGoalInput input) async {
    // Validate input
    input.validate();

    // Create new savings goal
    final goal = SavingsGoal(
      id: _uuid.v4(),
      userId: userId,
      name: input.name,
      targetAmount: input.targetAmount,
      currency: input.currency,
      currentAmount: Decimal.zero,
      deadline: input.deadline,
      reminderEnabled: input.reminderEnabled,
      reminderFrequency: input.reminderFrequency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    return _localDataSource.create(goal);
  }

  @override
  Future<SavingsGoal> contribute(String goalId, Decimal amount) async {
    if (amount <= Decimal.zero) {
      throw ArgumentError('Contribution amount must be greater than zero');
    }

    return _localDataSource.addContribution(
      goalId: goalId,
      amount: amount,
    );
  }

  @override
  Future<SavingsGoal> update(String id, SavingsGoalInput input) async {
    // Validate input
    input.validate();

    // Get existing goal
    final existingGoal = await _localDataSource.getById(id);
    if (existingGoal == null) {
      throw Exception('Savings goal not found: $id');
    }

    // Update goal with new values
    final updatedGoal = existingGoal.copyWith(
      name: input.name,
      targetAmount: input.targetAmount,
      currency: input.currency,
      deadline: input.deadline,
      reminderEnabled: input.reminderEnabled,
      reminderFrequency: input.reminderFrequency,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    return _localDataSource.update(updatedGoal);
  }

  @override
  Future<void> delete(String id) async {
    return _localDataSource.delete(id);
  }

  @override
  Future<List<SavingsGoal>> getAll(String userId) async {
    return _localDataSource.getAll(userId);
  }

  @override
  Future<SavingsGoal?> getById(String id) async {
    return _localDataSource.getById(id);
  }

  @override
  Stream<SavingsGoal?> watchGoal(String goalId) {
    return _localDataSource.watchGoal(goalId);
  }

  @override
  Stream<List<SavingsGoal>> watchAll(String userId) {
    return _localDataSource.watchAll(userId);
  }

  @override
  Future<Decimal> calculateSuggestedContribution(String goalId) async {
    final goal = await _localDataSource.getById(goalId);
    if (goal == null) {
      throw Exception('Savings goal not found: $goalId');
    }

    // If goal is completed or overdue, return zero
    if (goal.isCompleted || goal.isOverdue) {
      return Decimal.zero;
    }

    // Calculate remaining amount
    final remainingAmount = goal.targetAmount - goal.currentAmount;
    if (remainingAmount <= Decimal.zero) {
      return Decimal.zero;
    }

    // Calculate days until deadline
    final now = DateTime.now();
    final daysUntilDeadline = goal.deadline.difference(now).inDays;

    // If deadline is today or passed, return remaining amount
    if (daysUntilDeadline <= 0) {
      return remainingAmount;
    }

    // Calculate suggested contribution based on reminder frequency
    // If no reminder frequency, default to monthly
    final frequency = goal.reminderFrequency ?? ReminderFrequency.monthly;

    Decimal suggestedAmount;
    switch (frequency) {
      case ReminderFrequency.daily:
        // Divide remaining amount by days until deadline
        final result = remainingAmount / Decimal.fromInt(daysUntilDeadline);
        suggestedAmount = Decimal.parse(result.toDouble().toStringAsFixed(2));
        break;

      case ReminderFrequency.weekly:
        // Calculate number of weeks until deadline
        final weeksUntilDeadline = (daysUntilDeadline / 7).ceil();
        if (weeksUntilDeadline <= 0) {
          suggestedAmount = remainingAmount;
        } else {
          final result = remainingAmount / Decimal.fromInt(weeksUntilDeadline);
          suggestedAmount = Decimal.parse(result.toDouble().toStringAsFixed(2));
        }
        break;

      case ReminderFrequency.monthly:
        // Calculate number of months until deadline
        final monthsUntilDeadline = (daysUntilDeadline / 30).ceil();
        if (monthsUntilDeadline <= 0) {
          suggestedAmount = remainingAmount;
        } else {
          final result = remainingAmount / Decimal.fromInt(monthsUntilDeadline);
          suggestedAmount = Decimal.parse(result.toDouble().toStringAsFixed(2));
        }
        break;
    }

    // Round to 2 decimal places for currency
    return suggestedAmount;
  }

  @override
  Future<List<SavingsGoal>> getActive(String userId) async {
    return _localDataSource.getActive(userId);
  }

  @override
  Future<List<SavingsGoal>> getCompleted(String userId) async {
    return _localDataSource.getCompleted(userId);
  }

  @override
  Future<List<SavingsGoal>> getOverdue(String userId) async {
    return _localDataSource.getOverdue(userId);
  }
}
