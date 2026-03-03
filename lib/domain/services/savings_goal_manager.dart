import 'package:decimal/decimal.dart';
import '../entities/savings_goal.dart';
import '../value_objects/currency.dart';

/// Input data for creating or updating a savings goal
class SavingsGoalInput {
  final String name;
  final Decimal targetAmount;
  final Currency currency;
  final DateTime deadline;
  final bool reminderEnabled;
  final ReminderFrequency? reminderFrequency;

  const SavingsGoalInput({
    required this.name,
    required this.targetAmount,
    required this.currency,
    required this.deadline,
    this.reminderEnabled = false,
    this.reminderFrequency,
  });

  /// Validate the input
  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Goal name cannot be empty');
    }
    if (targetAmount <= Decimal.zero) {
      throw ArgumentError('Target amount must be greater than zero');
    }
    if (deadline.isBefore(DateTime.now())) {
      throw ArgumentError('Deadline must be in the future');
    }
    if (reminderEnabled && reminderFrequency == null) {
      throw ArgumentError('Reminder frequency is required when reminders are enabled');
    }
  }
}

/// Service interface for SavingsGoal operations
abstract class SavingsGoalManager {
  /// Create a new savings goal
  /// Throws ArgumentError if input validation fails
  Future<SavingsGoal> create(String userId, SavingsGoalInput input);

  /// Contribute funds to a savings goal
  /// Returns the updated goal with new current amount
  /// Throws Exception if goal not found or amount is invalid
  Future<SavingsGoal> contribute(String goalId, Decimal amount);

  /// Update an existing savings goal
  /// Throws Exception if goal not found
  Future<SavingsGoal> update(String id, SavingsGoalInput input);

  /// Delete a savings goal by ID
  Future<void> delete(String id);

  /// Get all savings goals for a user
  /// Returns goals sorted by deadline (earliest first)
  Future<List<SavingsGoal>> getAll(String userId);

  /// Get a specific savings goal by ID
  Future<SavingsGoal?> getById(String id);

  /// Watch a specific savings goal (returns a stream)
  /// Emits updates whenever the goal changes
  Stream<SavingsGoal?> watchGoal(String goalId);

  /// Watch all savings goals for a user (returns a stream)
  Stream<List<SavingsGoal>> watchAll(String userId);

  /// Calculate suggested contribution amount for a goal
  /// Based on remaining amount, days until deadline, and reminder frequency
  /// Returns Decimal.zero if goal is completed or overdue
  Future<Decimal> calculateSuggestedContribution(String goalId);

  /// Get active (not completed) savings goals
  Future<List<SavingsGoal>> getActive(String userId);

  /// Get completed savings goals
  Future<List<SavingsGoal>> getCompleted(String userId);

  /// Get overdue savings goals (deadline passed and not completed)
  Future<List<SavingsGoal>> getOverdue(String userId);
}
