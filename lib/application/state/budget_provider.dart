import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/budget_tracker.dart';
import '../../domain/services/notification_service.dart';
import '../../infrastructure/services/budget_tracker_impl.dart';
import '../../infrastructure/services/budget_alert_monitor.dart';
import '../../infrastructure/data_sources/local/budget_local_data_source.dart';
import '../../infrastructure/data_sources/local/category_local_data_source.dart';
import 'auth_provider.dart';
import 'savings_goal_provider.dart';
import 'dashboard_provider.dart';

/// Provider for BudgetLocalDataSource
final budgetLocalDataSourceProvider = Provider<BudgetLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return BudgetLocalDataSource(database);
});

/// Provider for CategoryLocalDataSource
final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return CategoryLocalDataSource(database);
});

/// Provider for BudgetTracker
final budgetTrackerProvider = Provider<BudgetTracker>((ref) {
  final localDataSource = ref.watch(budgetLocalDataSourceProvider);
  return BudgetTrackerImpl(localDataSource);
});

/// Provider for BudgetAlertMonitor
final budgetAlertMonitorProvider = Provider<BudgetAlertMonitor>((ref) {
  final budgetTracker = ref.watch(budgetTrackerProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  
  final monitor = BudgetAlertMonitor(
    budgetTracker,
    notificationService,
  );
  
  // Start monitoring when user is logged in
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    monitor.startMonitoring(user.id);
  }
  
  // Clean up when provider is disposed
  ref.onDispose(() {
    monitor.dispose();
  });
  
  return monitor;
});
