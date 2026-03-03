import '../entities/budget.dart';
import '../entities/savings_goal.dart';

/// Types of alerts for budget notifications
enum AlertType {
  nearLimit, // 80% threshold
  overLimit, // 100% threshold
}

/// User notification preferences
class NotificationPreferences {
  final bool budgetAlertsEnabled;
  final bool goalRemindersEnabled;
  final bool goalAchievementsEnabled;
  final bool syncStatusEnabled;

  const NotificationPreferences({
    this.budgetAlertsEnabled = true,
    this.goalRemindersEnabled = true,
    this.goalAchievementsEnabled = true,
    this.syncStatusEnabled = true,
  });
}

/// Sync status for notifications
enum SyncStatus {
  syncing,
  success,
  failed,
}

/// Abstract service for managing notifications
abstract class NotificationService {
  /// Request notification permissions from the user
  Future<void> requestPermissions();

  /// Send a budget alert notification
  Future<void> sendBudgetAlert(Budget budget, AlertType type);

  /// Send a goal reminder notification
  Future<void> sendGoalReminder(SavingsGoal goal, String suggestedAmount);

  /// Send a goal achievement notification
  Future<void> sendGoalAchievement(SavingsGoal goal);

  /// Send a sync status notification
  Future<void> sendSyncStatus(SyncStatus status);

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences prefs);
}
