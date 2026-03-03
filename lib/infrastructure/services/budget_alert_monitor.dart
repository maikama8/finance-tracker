import 'dart:async';
import 'package:decimal/decimal.dart';
import '../../domain/services/budget_tracker.dart';
import '../../domain/services/notification_service.dart';

/// Monitors budget alerts and sends notifications
class BudgetAlertMonitor {
  final BudgetTracker _budgetTracker;
  final NotificationService _notificationService;
  StreamSubscription<BudgetAlert>? _alertSubscription;
  
  // Track which budgets have already triggered alerts to avoid duplicates
  final Map<String, Set<BudgetAlertType>> _triggeredAlerts = {};

  BudgetAlertMonitor(this._budgetTracker, this._notificationService);

  /// Start monitoring budget alerts for a user
  void startMonitoring(String userId) {
    // Cancel any existing subscription
    stopMonitoring();

    // Subscribe to budget alerts
    _alertSubscription = _budgetTracker.watchAlerts(userId).listen(
      (alert) => _handleAlert(alert),
      onError: (error) {
        // Log error but don't crash
        print('Error monitoring budget alerts: $error');
      },
    );
  }

  /// Stop monitoring budget alerts
  void stopMonitoring() {
    _alertSubscription?.cancel();
    _alertSubscription = null;
    _triggeredAlerts.clear();
  }

  /// Handle a budget alert
  Future<void> _handleAlert(BudgetAlert alert) async {
    final budgetId = alert.budget.id;
    
    // Check if we've already sent this alert for this budget
    final triggeredTypes = _triggeredAlerts[budgetId] ?? {};
    
    if (triggeredTypes.contains(alert.type)) {
      // Already sent this alert type for this budget
      return;
    }

    // Mark this alert as triggered
    _triggeredAlerts[budgetId] = {...triggeredTypes, alert.type};

    // Send notification based on alert type
    final notificationType = alert.type == BudgetAlertType.nearLimit
        ? AlertType.nearLimit
        : AlertType.overLimit;

    await _notificationService.sendBudgetAlert(
      alert.budget,
      notificationType,
    );
  }

  /// Reset alert tracking for a budget (e.g., when month changes)
  void resetAlerts(String budgetId) {
    _triggeredAlerts.remove(budgetId);
  }

  /// Reset all alert tracking
  void resetAllAlerts() {
    _triggeredAlerts.clear();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
