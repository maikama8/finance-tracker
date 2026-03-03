import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles incoming FCM notifications and deep linking
class NotificationHandler {
  final FirebaseMessaging _messaging;
  
  /// Callback for handling notification navigation
  final void Function(String route, Map<String, String> params)? onNavigate;

  NotificationHandler({
    FirebaseMessaging? messaging,
    this.onNavigate,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Initialize notification handlers
  Future<void> initialize() async {
    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    developer.log('Notification handler initialized', name: 'NotificationHandler');
  }

  /// Handle notification when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log(
      'Received foreground notification: ${message.notification?.title}',
      name: 'NotificationHandler',
    );

    // In production, you might want to show a local notification here
    // or update the UI to reflect the new notification
  }

  /// Handle notification tap and navigate to relevant screen
  void _handleNotificationTap(RemoteMessage message) {
    developer.log(
      'Notification tapped: ${message.data}',
      name: 'NotificationHandler',
    );

    final data = message.data;
    final type = data['type'] as String?;

    if (type == null) {
      developer.log('No notification type found', name: 'NotificationHandler');
      return;
    }

    // Determine route and parameters based on notification type
    final (route, params) = _getRouteForNotificationType(type, data);
    
    if (route != null) {
      developer.log(
        'Navigating to: $route with params: $params',
        name: 'NotificationHandler',
      );
      onNavigate?.call(route, params);
    }
  }

  /// Get route and parameters for notification type
  (String?, Map<String, String>) _getRouteForNotificationType(
    String type,
    Map<String, dynamic> data,
  ) {
    switch (type) {
      case 'budget_alert':
        final budgetId = data['budgetId'] as String?;
        final categoryId = data['categoryId'] as String?;
        if (budgetId != null) {
          return ('/budgets', {'budgetId': budgetId, if (categoryId != null) 'categoryId': categoryId});
        }
        return ('/budgets', {});

      case 'goal_reminder':
      case 'goal_achievement':
        final goalId = data['goalId'] as String?;
        if (goalId != null) {
          return ('/goals/$goalId', {'goalId': goalId});
        }
        return ('/goals', {});

      case 'sync_status':
        return ('/settings', {});

      default:
        developer.log('Unknown notification type: $type', name: 'NotificationHandler');
        return (null, {});
    }
  }
}
