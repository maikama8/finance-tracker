import 'package:flutter/material.dart';
import 'app_routes.dart';

/// Handles deep linking from notifications and external sources
class DeepLinkHandler {
  /// Parses a deep link URI and returns the appropriate route
  static String? parseDeepLink(Uri uri) {
    // Handle app-specific scheme: financetracker://
    if (uri.scheme == 'financetracker') {
      return _handleAppScheme(uri);
    }
    
    // Handle universal links: https://financetracker.app/
    if (uri.scheme == 'https' && uri.host == 'financetracker.app') {
      return _handleUniversalLink(uri);
    }
    
    return null;
  }

  /// Handles app-specific scheme deep links
  static String? _handleAppScheme(Uri uri) {
    final path = uri.host;
    
    switch (path) {
      case 'dashboard':
        return AppRoutes.dashboard;
      
      case 'transactions':
        return AppRoutes.transactions;
      
      case 'goals':
        // Check if there's a specific goal ID
        final goalId = uri.queryParameters['id'];
        if (goalId != null) {
          return AppRoutes.goalDetail;
        }
        return AppRoutes.savingsGoals;
      
      case 'budgets':
        return AppRoutes.budgets;
      
      case 'reports':
        return AppRoutes.reports;
      
      case 'settings':
        return AppRoutes.settings;
      
      default:
        return AppRoutes.dashboard;
    }
  }

  /// Handles universal links (HTTPS)
  static String? _handleUniversalLink(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.isEmpty) {
      return AppRoutes.dashboard;
    }
    
    switch (pathSegments[0]) {
      case 'dashboard':
        return AppRoutes.dashboard;
      
      case 'transactions':
        return AppRoutes.transactions;
      
      case 'goals':
        if (pathSegments.length > 1) {
          // Specific goal: /goals/{goalId}
          return AppRoutes.goalDetail;
        }
        return AppRoutes.savingsGoals;
      
      case 'budgets':
        return AppRoutes.budgets;
      
      case 'reports':
        return AppRoutes.reports;
      
      case 'settings':
        return AppRoutes.settings;
      
      default:
        return AppRoutes.dashboard;
    }
  }

  /// Navigates to a route based on notification data
  static void handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notificationData,
  ) {
    final type = notificationData['type'] as String?;
    final id = notificationData['id'] as String?;
    
    switch (type) {
      case 'budget_alert':
        // Navigate to budgets screen
        Navigator.pushNamed(context, AppRoutes.budgets);
        break;
      
      case 'goal_reminder':
      case 'goal_achievement':
        // Navigate to specific goal if ID provided
        if (id != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.goalDetail,
            arguments: id,
          );
        } else {
          Navigator.pushNamed(context, AppRoutes.savingsGoals);
        }
        break;
      
      case 'sync_status':
        // Navigate to settings for sync status
        Navigator.pushNamed(context, AppRoutes.settings);
        break;
      
      default:
        // Default to dashboard
        Navigator.pushNamed(context, AppRoutes.dashboard);
    }
  }

  /// Extracts arguments from a deep link URI
  static dynamic extractArguments(Uri uri) {
    final goalId = uri.queryParameters['goalId'] ?? 
                   uri.queryParameters['id'];
    
    if (goalId != null) {
      return goalId;
    }
    
    return null;
  }
}
