import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/services/notification_service.dart';
import 'notification_handler.dart';

/// Implementation of NotificationService with Firebase Cloud Messaging
class NotificationServiceImpl implements NotificationService {
  final FirebaseMessaging _messaging;
  final NotificationHandler? _handler;
  final SharedPreferences? _prefs;
  NotificationPreferences _preferences = const NotificationPreferences();

  // Keys for storing preferences
  static const String _keyBudgetAlerts = 'notification_budget_alerts';
  static const String _keyGoalReminders = 'notification_goal_reminders';
  static const String _keyGoalAchievements = 'notification_goal_achievements';
  static const String _keySyncStatus = 'notification_sync_status';

  NotificationServiceImpl({
    FirebaseMessaging? messaging,
    NotificationHandler? handler,
    SharedPreferences? prefs,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _handler = handler,
        _prefs = prefs;

  /// Initialize the notification service and handler
  Future<void> initialize() async {
    await _handler?.initialize();
    await _loadPreferences();
  }

  /// Load notification preferences from storage
  Future<void> _loadPreferences() async {
    if (_prefs == null) return;

    _preferences = NotificationPreferences(
      budgetAlertsEnabled: _prefs!.getBool(_keyBudgetAlerts) ?? true,
      goalRemindersEnabled: _prefs!.getBool(_keyGoalReminders) ?? true,
      goalAchievementsEnabled: _prefs!.getBool(_keyGoalAchievements) ?? true,
      syncStatusEnabled: _prefs!.getBool(_keySyncStatus) ?? true,
    );

    developer.log(
      'Loaded notification preferences from storage',
      name: 'NotificationService',
    );
  }

  /// Save notification preferences to storage
  Future<void> _savePreferences() async {
    if (_prefs == null) return;

    await Future.wait([
      _prefs!.setBool(_keyBudgetAlerts, _preferences.budgetAlertsEnabled),
      _prefs!.setBool(_keyGoalReminders, _preferences.goalRemindersEnabled),
      _prefs!.setBool(_keyGoalAchievements, _preferences.goalAchievementsEnabled),
      _prefs!.setBool(_keySyncStatus, _preferences.syncStatusEnabled),
    ]);

    developer.log(
      'Saved notification preferences to storage',
      name: 'NotificationService',
    );
  }

  @override
  Future<void> requestPermissions() async {
    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log(
        'Notification permission status: ${settings.authorizationStatus}',
        name: 'NotificationService',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('User granted notification permissions', name: 'NotificationService');
        
        // Get FCM token for this device
        final token = await _messaging.getToken();
        developer.log('FCM Token: $token', name: 'NotificationService');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        developer.log('User granted provisional notification permissions', name: 'NotificationService');
      } else {
        developer.log('User declined notification permissions', name: 'NotificationService');
      }
    } catch (e) {
      developer.log('Error requesting notification permissions: $e', name: 'NotificationService');
      rethrow;
    }
  }

  @override
  Future<void> sendBudgetAlert(Budget budget, AlertType type) async {
    if (!_preferences.budgetAlertsEnabled) {
      return;
    }

    final message = type == AlertType.nearLimit
        ? 'Budget Alert: You\'ve reached ${budget.percentageUsed.toStringAsFixed(1)}% of your budget for category ${budget.categoryId}'
        : 'Budget Alert: You\'ve exceeded your budget for category ${budget.categoryId}!';

    developer.log(
      'Budget Alert: $message',
      name: 'NotificationService',
    );

    // In production, this would trigger a backend service to send FCM notification
    // The backend would call FCM API with:
    // - title: 'Budget Alert'
    // - body: message
    // - data: { type: 'budget_alert', budgetId: budget.id, alertType: type.name }
    // - click_action: 'FLUTTER_NOTIFICATION_CLICK'
    // 
    // For now, we log the notification that would be sent
    _logNotificationPayload(
      title: 'Budget Alert',
      body: message,
      data: {
        'type': 'budget_alert',
        'budgetId': budget.id,
        'alertType': type.name,
        'categoryId': budget.categoryId,
      },
    );
  }

  @override
  Future<void> sendGoalReminder(SavingsGoal goal, String suggestedAmount) async {
    if (!_preferences.goalRemindersEnabled) {
      return;
    }

    final message = 'Reminder: Contribute $suggestedAmount to your goal "${goal.name}"';

    developer.log(
      'Goal Reminder: $message',
      name: 'NotificationService',
    );

    // In production, this would trigger a backend service to send FCM notification
    _logNotificationPayload(
      title: 'Savings Goal Reminder',
      body: message,
      data: {
        'type': 'goal_reminder',
        'goalId': goal.id,
        'suggestedAmount': suggestedAmount,
      },
    );
  }

  @override
  Future<void> sendGoalAchievement(SavingsGoal goal) async {
    if (!_preferences.goalAchievementsEnabled) {
      return;
    }

    final message = 'Congratulations! You\'ve achieved your goal "${goal.name}"!';

    developer.log(
      'Goal Achievement: $message',
      name: 'NotificationService',
    );

    // In production, this would trigger a backend service to send FCM notification
    _logNotificationPayload(
      title: '🎉 Goal Achieved!',
      body: message,
      data: {
        'type': 'goal_achievement',
        'goalId': goal.id,
      },
    );
  }

  @override
  Future<void> sendSyncStatus(SyncStatus status) async {
    if (!_preferences.syncStatusEnabled) {
      return;
    }

    // Only send notifications for failures, not for success or syncing
    if (status != SyncStatus.failed) {
      return;
    }

    final message = 'Sync failed. Will retry later.';

    developer.log(
      'Sync Status: $message',
      name: 'NotificationService',
    );

    // In production, this would trigger a backend service to send FCM notification
    _logNotificationPayload(
      title: 'Sync Failed',
      body: message,
      data: {
        'type': 'sync_status',
        'status': status.name,
      },
    );
  }

  @override
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    _preferences = prefs;
    await _savePreferences();
    
    developer.log(
      'Notification preferences updated: '
      'budgetAlerts=${prefs.budgetAlertsEnabled}, '
      'goalReminders=${prefs.goalRemindersEnabled}, '
      'goalAchievements=${prefs.goalAchievementsEnabled}, '
      'syncStatus=${prefs.syncStatusEnabled}',
      name: 'NotificationService',
    );
  }

  /// Get current notification preferences
  NotificationPreferences getPreferences() {
    return _preferences;
  }

  /// Helper method to log notification payload for debugging
  /// In production, this would be replaced with actual FCM API calls
  void _logNotificationPayload({
    required String title,
    required String body,
    required Map<String, String> data,
  }) {
    developer.log(
      'FCM Notification Payload:\n'
      '  Title: $title\n'
      '  Body: $body\n'
      '  Data: $data',
      name: 'NotificationService',
    );
  }
}
