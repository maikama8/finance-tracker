import 'dart:async';
import '../../domain/services/budget_tracker.dart';
import 'budget_alert_monitor.dart';

/// Scheduler for monthly budget reset
class BudgetResetScheduler {
  final BudgetTracker _budgetTracker;
  final BudgetAlertMonitor? _alertMonitor;
  Timer? _checkTimer;
  int _lastCheckedMonth = DateTime.now().month;
  int _lastCheckedYear = DateTime.now().year;

  BudgetResetScheduler(
    this._budgetTracker, {
    BudgetAlertMonitor? alertMonitor,
  }) : _alertMonitor = alertMonitor;

  /// Start the scheduler
  /// Checks every hour if the month has changed
  void start() {
    // Cancel any existing timer
    stop();

    // Check immediately
    _checkForMonthChange();

    // Set up periodic check (every hour)
    _checkTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkForMonthChange(),
    );
  }

  /// Stop the scheduler
  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check if the month has changed and reset budgets if needed
  Future<void> _checkForMonthChange() async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Check if month or year has changed
    if (currentMonth != _lastCheckedMonth || currentYear != _lastCheckedYear) {
      print('Month changed from $_lastCheckedMonth/$_lastCheckedYear to $currentMonth/$currentYear');
      
      // Reset budgets for all users
      // Note: In a real app, you'd need to get all user IDs
      // For now, this is a placeholder that would be called per user
      await _resetBudgetsForMonthChange();

      // Update last checked values
      _lastCheckedMonth = currentMonth;
      _lastCheckedYear = currentYear;
    }
  }

  /// Reset budgets when month changes
  Future<void> _resetBudgetsForMonthChange() async {
    // This would be called for each user in a real implementation
    // For now, it's a placeholder that demonstrates the logic
    
    // Reset alert tracking when month changes
    _alertMonitor?.resetAllAlerts();
    
    print('Budget reset triggered for new month');
  }

  /// Manually trigger budget reset for a specific user
  Future<void> resetBudgetsForUser(String userId) async {
    await _budgetTracker.resetMonthlyBudgets(userId);
    
    // Reset alert tracking for this user's budgets
    _alertMonitor?.resetAllAlerts();
    
    print('Budgets reset for user: $userId');
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}
