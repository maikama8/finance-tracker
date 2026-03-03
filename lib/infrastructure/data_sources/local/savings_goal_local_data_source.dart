import 'package:decimal/decimal.dart';
import 'package:hive/hive.dart';
import '../../../domain/entities/savings_goal.dart';
import '../../../domain/entities/transaction.dart';
import 'hive_database.dart';

/// Local data source for SavingsGoal entities using Hive
class SavingsGoalLocalDataSource {
  final HiveDatabase _database;

  SavingsGoalLocalDataSource(this._database);

  /// Get the savings goals box
  Box _getBox() => _database.getBox(HiveBoxNames.savingsGoals);

  /// Create a new savings goal
  Future<SavingsGoal> create(SavingsGoal goal) async {
    final box = _getBox();
    await box.put(goal.id, goal);
    return goal;
  }

  /// Update an existing savings goal
  Future<SavingsGoal> update(SavingsGoal goal) async {
    final box = _getBox();
    if (!box.containsKey(goal.id)) {
      throw Exception('Savings goal not found: ${goal.id}');
    }
    await box.put(goal.id, goal);
    return goal;
  }

  /// Delete a savings goal by ID
  Future<void> delete(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// Get a savings goal by ID
  Future<SavingsGoal?> getById(String id) async {
    final box = _getBox();
    return box.get(id) as SavingsGoal?;
  }

  /// Get all savings goals for a user
  Future<List<SavingsGoal>> getAll(String userId) async {
    final box = _getBox();
    final allGoals = box.values.cast<SavingsGoal>();

    return allGoals
        .where((g) => g.userId == userId)
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  /// Get active savings goals (not completed)
  Future<List<SavingsGoal>> getActive(String userId) async {
    final allGoals = await getAll(userId);
    return allGoals.where((g) => !g.isCompleted).toList();
  }

  /// Get completed savings goals
  Future<List<SavingsGoal>> getCompleted(String userId) async {
    final allGoals = await getAll(userId);
    return allGoals.where((g) => g.isCompleted).toList();
  }

  /// Get overdue savings goals (deadline passed and not completed)
  Future<List<SavingsGoal>> getOverdue(String userId) async {
    final allGoals = await getAll(userId);
    return allGoals.where((g) => g.isOverdue).toList();
  }

  /// Get goals with reminders enabled
  Future<List<SavingsGoal>> getWithReminders(String userId) async {
    final allGoals = await getAll(userId);
    return allGoals.where((g) => g.reminderEnabled).toList();
  }

  /// Get goals that need reminder (reminder enabled and time for next reminder)
  Future<List<SavingsGoal>> getNeedingReminder(String userId) async {
    final goalsWithReminders = await getWithReminders(userId);
    final now = DateTime.now();

    return goalsWithReminders.where((goal) {
      if (goal.lastReminderSent == null) return true;

      final daysSinceLastReminder =
          now.difference(goal.lastReminderSent!).inDays;

      switch (goal.reminderFrequency) {
        case ReminderFrequency.daily:
          return daysSinceLastReminder >= 1;
        case ReminderFrequency.weekly:
          return daysSinceLastReminder >= 7;
        case ReminderFrequency.monthly:
          return daysSinceLastReminder >= 30;
        case null:
          return false;
      }
    }).toList();
  }

  /// Add contribution to a savings goal
  Future<SavingsGoal> addContribution({
    required String goalId,
    required Decimal amount,
  }) async {
    final goal = await getById(goalId);
    if (goal == null) {
      throw Exception('Savings goal not found: $goalId');
    }

    final updatedGoal = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
      updatedAt: DateTime.now(),
    );

    return update(updatedGoal);
  }

  /// Subtract from a savings goal (e.g., withdrawal)
  Future<SavingsGoal> subtractAmount({
    required String goalId,
    required Decimal amount,
  }) async {
    final goal = await getById(goalId);
    if (goal == null) {
      throw Exception('Savings goal not found: $goalId');
    }

    final newAmount = goal.currentAmount - amount;
    if (newAmount < Decimal.zero) {
      throw Exception('Cannot subtract more than current amount');
    }

    final updatedGoal = goal.copyWith(
      currentAmount: newAmount,
      updatedAt: DateTime.now(),
    );

    return update(updatedGoal);
  }

  /// Update last reminder sent timestamp
  Future<SavingsGoal> updateLastReminderSent(String goalId) async {
    final goal = await getById(goalId);
    if (goal == null) {
      throw Exception('Savings goal not found: $goalId');
    }

    final updatedGoal = goal.copyWith(
      lastReminderSent: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return update(updatedGoal);
  }

  /// Get all pending sync goals
  Future<List<SavingsGoal>> getPendingSync(String userId) async {
    final box = _getBox();
    final allGoals = box.values.cast<SavingsGoal>();

    return allGoals
        .where((g) => g.userId == userId && g.syncStatus == SyncStatus.pending)
        .toList();
  }

  /// Get all goals with conflicts
  Future<List<SavingsGoal>> getConflicts(String userId) async {
    final box = _getBox();
    final allGoals = box.values.cast<SavingsGoal>();

    return allGoals
        .where((g) => g.userId == userId && g.syncStatus == SyncStatus.conflict)
        .toList();
  }

  /// Watch all savings goals for a user (returns a stream)
  Stream<List<SavingsGoal>> watchAll(String userId) {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getAll(userId);
    });
  }

  /// Watch a specific savings goal (returns a stream)
  Stream<SavingsGoal?> watchGoal(String goalId) {
    final box = _getBox();

    return box.watch(key: goalId).asyncMap((_) async {
      return getById(goalId);
    });
  }

  /// Get count of savings goals for a user
  Future<int> getCount(String userId) async {
    final goals = await getAll(userId);
    return goals.length;
  }

  /// Get total target amount across all goals
  Future<Decimal> getTotalTargetAmount(String userId) async {
    final goals = await getAll(userId);
    Decimal total = Decimal.zero;
    for (final goal in goals) {
      total = total + goal.targetAmount;
    }
    return total;
  }

  /// Get total current amount across all goals
  Future<Decimal> getTotalCurrentAmount(String userId) async {
    final goals = await getAll(userId);
    Decimal total = Decimal.zero;
    for (final goal in goals) {
      total = total + goal.currentAmount;
    }
    return total;
  }

  /// Clear all savings goals for a user
  Future<void> clearAll(String userId) async {
    final box = _getBox();
    final allGoals = box.values.cast<SavingsGoal>();
    final userGoalIds = allGoals
        .where((g) => g.userId == userId)
        .map((g) => g.id)
        .toList();

    for (final id in userGoalIds) {
      await box.delete(id);
    }
  }

  /// Batch create multiple savings goals
  Future<void> batchCreate(List<SavingsGoal> goals) async {
    final box = _getBox();
    final Map<String, SavingsGoal> entries = {
      for (var g in goals) g.id: g
    };
    await box.putAll(entries);
  }

  /// Batch update multiple savings goals
  Future<void> batchUpdate(List<SavingsGoal> goals) async {
    await batchCreate(goals); // Same implementation as create
  }

  /// Batch delete multiple savings goals
  Future<void> batchDelete(List<String> ids) async {
    final box = _getBox();
    await box.deleteAll(ids);
  }
}
