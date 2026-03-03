import 'dart:async';
import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/services/budget_tracker.dart';
import '../data_sources/local/budget_local_data_source.dart';

/// Implementation of BudgetTracker service
class BudgetTrackerImpl implements BudgetTracker {
  final BudgetLocalDataSource _localDataSource;
  final _alertController = StreamController<BudgetAlert>.broadcast();
  final _uuid = const Uuid();

  BudgetTrackerImpl(this._localDataSource);

  @override
  Future<Budget> create(String userId, BudgetInput input) async {
    // Check if budget already exists for this category and month
    final existing = await _localDataSource.getByCategoryAndMonth(
      userId: userId,
      categoryId: input.categoryId,
      month: input.month,
      year: input.year,
    );

    if (existing != null) {
      throw Exception(
        'Budget already exists for category ${input.categoryId} in ${input.month}/${input.year}',
      );
    }

    final now = DateTime.now();
    final budget = Budget(
      id: _uuid.v4(),
      userId: userId,
      categoryId: input.categoryId,
      monthlyLimit: input.monthlyLimit,
      currency: input.currency,
      currentSpending: Decimal.zero,
      month: input.month,
      year: input.year,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    return _localDataSource.create(budget);
  }

  @override
  Future<Budget> update(String id, BudgetInput input) async {
    final existing = await _localDataSource.getById(id);
    if (existing == null) {
      throw Exception('Budget not found: $id');
    }

    final updated = existing.copyWith(
      categoryId: input.categoryId,
      monthlyLimit: input.monthlyLimit,
      currency: input.currency,
      month: input.month,
      year: input.year,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    return _localDataSource.update(updated);
  }

  @override
  Future<void> delete(String id) async {
    return _localDataSource.delete(id);
  }

  @override
  Future<List<Budget>> getAll(String userId) async {
    return _localDataSource.getAll(userId);
  }

  @override
  Future<BudgetStatus> getStatus(String budgetId) async {
    final budget = await _localDataSource.getById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    return BudgetStatus(
      budget: budget,
      percentageUsed: budget.percentageUsed,
      remainingAmount: budget.remainingAmount,
      isNearLimit: budget.isNearLimit,
      isOverLimit: budget.isOverLimit,
    );
  }

  @override
  Stream<BudgetAlert> watchAlerts(String userId) {
    // Watch all budgets for the user
    _localDataSource.watchAll(userId).listen((budgets) {
      for (final budget in budgets) {
        _checkAndEmitAlert(budget);
      }
    });

    return _alertController.stream;
  }

  /// Check budget thresholds and emit alerts
  void _checkAndEmitAlert(Budget budget) {
    final percentage = budget.percentageUsed;

    // Check for 100% threshold
    if (percentage >= Decimal.fromInt(100)) {
      _alertController.add(BudgetAlert(
        budget: budget,
        type: BudgetAlertType.overLimit,
        percentageUsed: percentage,
        timestamp: DateTime.now(),
      ));
    }
    // Check for 80% threshold (but not over 100%)
    else if (percentage >= Decimal.fromInt(80)) {
      _alertController.add(BudgetAlert(
        budget: budget,
        type: BudgetAlertType.nearLimit,
        percentageUsed: percentage,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> resetMonthlyBudgets(String userId) async {
    final now = DateTime.now();
    await _localDataSource.resetMonthlyBudgets(
      userId: userId,
      month: now.month,
      year: now.year,
    );
  }

  /// Update budget spending when a transaction is added
  Future<void> updateSpendingForTransaction({
    required String userId,
    required String categoryId,
    required Decimal amount,
    required DateTime transactionDate,
  }) async {
    // Find the budget for this category and month
    final budget = await _localDataSource.getByCategoryAndMonth(
      userId: userId,
      categoryId: categoryId,
      month: transactionDate.month,
      year: transactionDate.year,
    );

    if (budget == null) {
      // No budget exists for this category/month, nothing to update
      return;
    }

    // Add the amount to current spending
    final updated = await _localDataSource.addSpending(
      budgetId: budget.id,
      amount: amount,
    );

    // Check if we need to emit an alert
    _checkAndEmitAlert(updated);
  }

  /// Update budget spending when a transaction is removed
  Future<void> removeSpendingForTransaction({
    required String userId,
    required String categoryId,
    required Decimal amount,
    required DateTime transactionDate,
  }) async {
    // Find the budget for this category and month
    final budget = await _localDataSource.getByCategoryAndMonth(
      userId: userId,
      categoryId: categoryId,
      month: transactionDate.month,
      year: transactionDate.year,
    );

    if (budget == null) {
      // No budget exists for this category/month, nothing to update
      return;
    }

    // Subtract the amount from current spending
    await _localDataSource.subtractSpending(
      budgetId: budget.id,
      amount: amount,
    );
  }

  /// Dispose resources
  void dispose() {
    _alertController.close();
  }
}
