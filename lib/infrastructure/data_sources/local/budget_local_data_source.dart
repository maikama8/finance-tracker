import 'package:decimal/decimal.dart';
import 'package:hive/hive.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/transaction.dart';
import 'hive_database.dart';

/// Local data source for Budget entities using Hive
class BudgetLocalDataSource {
  final HiveDatabase _database;

  BudgetLocalDataSource(this._database);

  /// Get the budgets box
  Box _getBox() => _database.getBox(HiveBoxNames.budgets);

  /// Create a new budget
  Future<Budget> create(Budget budget) async {
    final box = _getBox();
    await box.put(budget.id, budget);
    return budget;
  }

  /// Update an existing budget
  Future<Budget> update(Budget budget) async {
    final box = _getBox();
    if (!box.containsKey(budget.id)) {
      throw Exception('Budget not found: ${budget.id}');
    }
    await box.put(budget.id, budget);
    return budget;
  }

  /// Delete a budget by ID
  Future<void> delete(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// Get a budget by ID
  Future<Budget?> getById(String id) async {
    final box = _getBox();
    return box.get(id) as Budget?;
  }

  /// Get all budgets for a user
  Future<List<Budget>> getAll(String userId) async {
    final box = _getBox();
    final allBudgets = box.values.cast<Budget>();

    return allBudgets.where((b) => b.userId == userId).toList();
  }

  /// Get budgets for a specific month and year
  Future<List<Budget>> getByMonth({
    required String userId,
    required int month,
    required int year,
  }) async {
    final allBudgets = await getAll(userId);
    return allBudgets
        .where((b) => b.month == month && b.year == year)
        .toList();
  }

  /// Get current month's budgets
  Future<List<Budget>> getCurrentMonth(String userId) async {
    final now = DateTime.now();
    return getByMonth(userId: userId, month: now.month, year: now.year);
  }

  /// Get budget for a specific category in a specific month
  Future<Budget?> getByCategoryAndMonth({
    required String userId,
    required String categoryId,
    required int month,
    required int year,
  }) async {
    final monthBudgets = await getByMonth(
      userId: userId,
      month: month,
      year: year,
    );

    try {
      return monthBudgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Get budgets that are near the limit (>= 80%)
  Future<List<Budget>> getNearLimit(String userId) async {
    final allBudgets = await getAll(userId);
    return allBudgets.where((b) => b.isNearLimit).toList();
  }

  /// Get budgets that are over the limit (>= 100%)
  Future<List<Budget>> getOverLimit(String userId) async {
    final allBudgets = await getAll(userId);
    return allBudgets.where((b) => b.isOverLimit).toList();
  }

  /// Update spending for a budget
  Future<Budget> updateSpending({
    required String budgetId,
    required Decimal newSpending,
  }) async {
    final budget = await getById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final updatedBudget = budget.copyWith(
      currentSpending: newSpending,
      updatedAt: DateTime.now(),
    );

    return update(updatedBudget);
  }

  /// Add to current spending
  Future<Budget> addSpending({
    required String budgetId,
    required Decimal amount,
  }) async {
    final budget = await getById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final updatedBudget = budget.copyWith(
      currentSpending: budget.currentSpending + amount,
      updatedAt: DateTime.now(),
    );

    return update(updatedBudget);
  }

  /// Subtract from current spending
  Future<Budget> subtractSpending({
    required String budgetId,
    required Decimal amount,
  }) async {
    final budget = await getById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final newSpending = budget.currentSpending - amount;
    final updatedBudget = budget.copyWith(
      currentSpending: newSpending < Decimal.zero ? Decimal.zero : newSpending,
      updatedAt: DateTime.now(),
    );

    return update(updatedBudget);
  }

  /// Reset spending for a budget (set to zero)
  Future<Budget> resetSpending(String budgetId) async {
    final budget = await getById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final updatedBudget = budget.copyWith(
      currentSpending: Decimal.zero,
      updatedAt: DateTime.now(),
    );

    return update(updatedBudget);
  }

  /// Reset all budgets for a specific month (set spending to zero)
  Future<void> resetMonthlyBudgets({
    required String userId,
    required int month,
    required int year,
  }) async {
    final monthBudgets = await getByMonth(
      userId: userId,
      month: month,
      year: year,
    );

    for (final budget in monthBudgets) {
      await resetSpending(budget.id);
    }
  }

  /// Reset all current month budgets
  Future<void> resetCurrentMonthBudgets(String userId) async {
    final now = DateTime.now();
    await resetMonthlyBudgets(
      userId: userId,
      month: now.month,
      year: now.year,
    );
  }

  /// Copy budgets from one month to another (for recurring budgets)
  Future<List<Budget>> copyToNextMonth({
    required String userId,
    required int fromMonth,
    required int fromYear,
  }) async {
    final sourceBudgets = await getByMonth(
      userId: userId,
      month: fromMonth,
      year: fromYear,
    );

    // Calculate next month
    int nextMonth = fromMonth + 1;
    int nextYear = fromYear;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    final List<Budget> newBudgets = [];
    for (final budget in sourceBudgets) {
      final newBudget = budget.copyWith(
        id: '${budget.categoryId}_${nextMonth}_$nextYear',
        month: nextMonth,
        year: nextYear,
        currentSpending: Decimal.zero,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      await create(newBudget);
      newBudgets.add(newBudget);
    }

    return newBudgets;
  }

  /// Get all pending sync budgets
  Future<List<Budget>> getPendingSync(String userId) async {
    final box = _getBox();
    final allBudgets = box.values.cast<Budget>();

    return allBudgets
        .where((b) => b.userId == userId && b.syncStatus == SyncStatus.pending)
        .toList();
  }

  /// Get all budgets with conflicts
  Future<List<Budget>> getConflicts(String userId) async {
    final box = _getBox();
    final allBudgets = box.values.cast<Budget>();

    return allBudgets
        .where((b) => b.userId == userId && b.syncStatus == SyncStatus.conflict)
        .toList();
  }

  /// Watch all budgets for a user (returns a stream)
  Stream<List<Budget>> watchAll(String userId) {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getAll(userId);
    });
  }

  /// Watch budgets for a specific month (returns a stream)
  Stream<List<Budget>> watchMonth({
    required String userId,
    required int month,
    required int year,
  }) {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getByMonth(userId: userId, month: month, year: year);
    });
  }

  /// Watch a specific budget (returns a stream)
  Stream<Budget?> watchBudget(String budgetId) {
    final box = _getBox();

    return box.watch(key: budgetId).asyncMap((_) async {
      return getById(budgetId);
    });
  }

  /// Get count of budgets for a user
  Future<int> getCount(String userId) async {
    final budgets = await getAll(userId);
    return budgets.length;
  }

  /// Clear all budgets for a user
  Future<void> clearAll(String userId) async {
    final box = _getBox();
    final allBudgets = box.values.cast<Budget>();
    final userBudgetIds = allBudgets
        .where((b) => b.userId == userId)
        .map((b) => b.id)
        .toList();

    for (final id in userBudgetIds) {
      await box.delete(id);
    }
  }

  /// Batch create multiple budgets
  Future<void> batchCreate(List<Budget> budgets) async {
    final box = _getBox();
    final Map<String, Budget> entries = {
      for (var b in budgets) b.id: b
    };
    await box.putAll(entries);
  }

  /// Batch update multiple budgets
  Future<void> batchUpdate(List<Budget> budgets) async {
    await batchCreate(budgets); // Same implementation as create
  }

  /// Batch delete multiple budgets
  Future<void> batchDelete(List<String> ids) async {
    final box = _getBox();
    await box.deleteAll(ids);
  }
}
