import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/savings_goal_manager.dart';
import '../../domain/services/currency_service.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/payment_gateway_service.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../infrastructure/services/savings_goal_manager_impl.dart';
import '../../infrastructure/services/currency_service_impl.dart';
import '../../infrastructure/services/notification_service_impl.dart';
import '../../infrastructure/services/payment_gateway_service_impl.dart';
import '../../infrastructure/services/goal_achievement_monitor.dart';
import '../../infrastructure/repositories/transaction_repository_impl.dart';
import '../../infrastructure/data_sources/local/savings_goal_local_data_source.dart';
import '../../infrastructure/data_sources/local/exchange_rate_local_data_source.dart';
import '../../infrastructure/data_sources/local/transaction_local_data_source.dart';
import 'auth_provider.dart';

/// Provider for SavingsGoalLocalDataSource
final savingsGoalLocalDataSourceProvider = Provider<SavingsGoalLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return SavingsGoalLocalDataSource(database);
});

/// Provider for ExchangeRateLocalDataSource
final exchangeRateLocalDataSourceProvider = Provider<ExchangeRateLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return ExchangeRateLocalDataSource(database);
});

/// Provider for TransactionLocalDataSource
final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return TransactionLocalDataSource(database);
});

/// Provider for SavingsGoalManager
final savingsGoalManagerProvider = Provider<SavingsGoalManager>((ref) {
  final localDataSource = ref.watch(savingsGoalLocalDataSourceProvider);
  return SavingsGoalManagerImpl(localDataSource);
});

/// Provider for CurrencyService
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final exchangeRateDataSource = ref.watch(exchangeRateLocalDataSourceProvider);
  return CurrencyServiceImpl(
    localDataSource: exchangeRateDataSource,
    apiKey: '', // TODO: Add API key from environment
  );
});

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl();
});

/// Provider for PaymentGatewayService implementation
final paymentGatewayServiceImplProvider = Provider<PaymentGatewayService>((ref) {
  return PaymentGatewayServiceImpl(
    testMode: true, // TODO: Configure based on environment
  );
});

/// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final localDataSource = ref.watch(transactionLocalDataSourceProvider);
  return TransactionRepositoryImpl(localDataSource);
});

/// Provider for GoalAchievementMonitor
final goalAchievementMonitorProvider = Provider<GoalAchievementMonitor>((ref) {
  final savingsGoalManager = ref.watch(savingsGoalManagerProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  
  final monitor = GoalAchievementMonitor(
    savingsGoalManager: savingsGoalManager,
    notificationService: notificationService,
  );
  
  // Start monitoring when user is logged in
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    monitor.startMonitoring(user.id);
  }
  
  // Clean up when provider is disposed
  ref.onDispose(() {
    monitor.stopMonitoring();
  });
  
  return monitor;
});
