import 'dart:async';
import 'dart:developer' as developer;
import '../../domain/entities/savings_goal.dart';
import '../../domain/services/savings_goal_manager.dart';
import '../../domain/services/notification_service.dart';

/// Service that monitors savings goals and triggers achievement notifications
/// when a goal reaches 100% completion
class GoalAchievementMonitor {
  final SavingsGoalManager _savingsGoalManager;
  final NotificationService _notificationService;
  
  // Track goals that have already been notified to avoid duplicate notifications
  final Set<String> _notifiedGoalIds = {};
  
  StreamSubscription<List<SavingsGoal>>? _subscription;

  GoalAchievementMonitor({
    required SavingsGoalManager savingsGoalManager,
    required NotificationService notificationService,
  })  : _savingsGoalManager = savingsGoalManager,
        _notificationService = notificationService;

  /// Start monitoring goals for a specific user
  void startMonitoring(String userId) {
    developer.log(
      'Starting goal achievement monitoring for user: $userId',
      name: 'GoalAchievementMonitor',
    );

    // Cancel any existing subscription
    stopMonitoring();

    // Watch all goals for the user
    _subscription = _savingsGoalManager.watchAll(userId).listen(
      (goals) => _checkGoalsForAchievement(goals),
      onError: (error) {
        developer.log(
          'Error monitoring goals: $error',
          name: 'GoalAchievementMonitor',
        );
      },
    );
  }

  /// Stop monitoring goals
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _notifiedGoalIds.clear();
    
    developer.log(
      'Stopped goal achievement monitoring',
      name: 'GoalAchievementMonitor',
    );
  }

  /// Check goals for achievement and send notifications
  Future<void> _checkGoalsForAchievement(List<SavingsGoal> goals) async {
    for (final goal in goals) {
      // Check if goal is completed and hasn't been notified yet
      if (goal.isCompleted && !_notifiedGoalIds.contains(goal.id)) {
        developer.log(
          'Goal achieved: ${goal.name} (${goal.id})',
          name: 'GoalAchievementMonitor',
        );

        try {
          // Send achievement notification
          await _notificationService.sendGoalAchievement(goal);
          
          // Mark as notified to avoid duplicate notifications
          _notifiedGoalIds.add(goal.id);
          
          developer.log(
            'Achievement notification sent for goal: ${goal.name}',
            name: 'GoalAchievementMonitor',
          );
        } catch (e) {
          developer.log(
            'Error sending achievement notification for goal ${goal.id}: $e',
            name: 'GoalAchievementMonitor',
          );
        }
      }
    }
  }

  /// Manually check a specific goal for achievement
  /// Useful when a contribution is made
  Future<void> checkGoal(String goalId) async {
    try {
      final goal = await _savingsGoalManager.getById(goalId);
      
      if (goal == null) {
        developer.log(
          'Goal not found: $goalId',
          name: 'GoalAchievementMonitor',
        );
        return;
      }

      // Check if goal is completed and hasn't been notified yet
      if (goal.isCompleted && !_notifiedGoalIds.contains(goal.id)) {
        developer.log(
          'Goal achieved: ${goal.name} (${goal.id})',
          name: 'GoalAchievementMonitor',
        );

        // Send achievement notification
        await _notificationService.sendGoalAchievement(goal);
        
        // Mark as notified
        _notifiedGoalIds.add(goal.id);
        
        developer.log(
          'Achievement notification sent for goal: ${goal.name}',
          name: 'GoalAchievementMonitor',
        );
      }
    } catch (e) {
      developer.log(
        'Error checking goal $goalId for achievement: $e',
        name: 'GoalAchievementMonitor',
      );
    }
  }

  /// Reset notification tracking for a specific goal
  /// Useful if a goal is edited and no longer completed
  void resetGoalNotification(String goalId) {
    _notifiedGoalIds.remove(goalId);
    developer.log(
      'Reset notification tracking for goal: $goalId',
      name: 'GoalAchievementMonitor',
    );
  }

  /// Clear all notification tracking
  void clearAllNotifications() {
    _notifiedGoalIds.clear();
    developer.log(
      'Cleared all notification tracking',
      name: 'GoalAchievementMonitor',
    );
  }
}
