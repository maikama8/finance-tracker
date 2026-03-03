import 'package:decimal/decimal.dart';
import '../entities/budget.dart';
import '../value_objects/currency.dart';

/// Input data for creating or updating a budget
class BudgetInput {
  final String categoryId;
  final Decimal monthlyLimit;
  final Currency currency;
  final int month;
  final int year;

  const BudgetInput({
    required this.categoryId,
    required this.monthlyLimit,
    required this.currency,
    required this.month,
    required this.year,
  });
}

/// Status information for a budget
class BudgetStatus {
  final Budget budget;
  final Decimal percentageUsed;
  final Decimal remainingAmount;
  final bool isNearLimit;
  final bool isOverLimit;

  const BudgetStatus({
    required this.budget,
    required this.percentageUsed,
    required this.remainingAmount,
    required this.isNearLimit,
    required this.isOverLimit,
  });
}

/// Alert types for budget notifications
enum BudgetAlertType {
  nearLimit, // 80% threshold
  overLimit, // 100% threshold
}

/// Budget alert event
class BudgetAlert {
  final Budget budget;
  final BudgetAlertType type;
  final Decimal percentageUsed;
  final DateTime timestamp;

  const BudgetAlert({
    required this.budget,
    required this.type,
    required this.percentageUsed,
    required this.timestamp,
  });
}

/// Abstract service for managing budgets
abstract class BudgetTracker {
  /// Create a new budget
  Future<Budget> create(String userId, BudgetInput input);

  /// Update an existing budget
  Future<Budget> update(String id, BudgetInput input);

  /// Delete a budget
  Future<void> delete(String id);

  /// Get all budgets for a user
  Future<List<Budget>> getAll(String userId);

  /// Get status information for a specific budget
  Future<BudgetStatus> getStatus(String budgetId);

  /// Watch for budget alerts in real-time
  Stream<BudgetAlert> watchAlerts(String userId);

  /// Reset all monthly budgets (set currentSpending to zero)
  Future<void> resetMonthlyBudgets(String userId);
}
