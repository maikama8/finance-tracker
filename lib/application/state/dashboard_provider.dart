import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/savings_goal_manager.dart';
import '../../domain/services/category_service.dart';
import '../../domain/services/currency_service.dart';
import '../../domain/services/report_generator.dart';
import '../../domain/value_objects/date_range.dart';
import '../../infrastructure/repositories/transaction_repository_impl.dart';
import '../../infrastructure/services/savings_goal_manager_impl.dart';
import '../../infrastructure/services/category_service_impl.dart';
import '../../infrastructure/services/currency_service_impl.dart';
import '../../infrastructure/services/report_generator_impl.dart';
import '../../infrastructure/data_sources/local/transaction_local_data_source.dart';
import '../../infrastructure/data_sources/local/savings_goal_local_data_source.dart';
import '../../infrastructure/data_sources/local/category_local_data_source.dart';
import '../../infrastructure/data_sources/local/exchange_rate_local_data_source.dart';
import 'auth_provider.dart';

/// Provider for TransactionLocalDataSource
final transactionLocalDataSourceProvider = Provider<TransactionLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return TransactionLocalDataSource(database);
});

/// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final localDataSource = ref.watch(transactionLocalDataSourceProvider);
  return TransactionRepositoryImpl(localDataSource);
});

/// Provider for SavingsGoalLocalDataSource
final savingsGoalLocalDataSourceProvider = Provider<SavingsGoalLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return SavingsGoalLocalDataSource(database);
});

/// Provider for SavingsGoalManager
final savingsGoalManagerProvider = Provider<SavingsGoalManager>((ref) {
  final localDataSource = ref.watch(savingsGoalLocalDataSourceProvider);
  return SavingsGoalManagerImpl(localDataSource);
});

/// Provider for CategoryLocalDataSource
final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return CategoryLocalDataSource(database);
});

/// Provider for CategoryService
final categoryServiceProvider = Provider<CategoryService>((ref) {
  final categoryLocalDataSource = ref.watch(categoryLocalDataSourceProvider);
  final transactionLocalDataSource = ref.watch(transactionLocalDataSourceProvider);
  return CategoryServiceImpl(categoryLocalDataSource, transactionLocalDataSource);
});

/// Provider for ExchangeRateLocalDataSource
final exchangeRateLocalDataSourceProvider = Provider<ExchangeRateLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return ExchangeRateLocalDataSource(database);
});

/// Provider for CurrencyService
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final localDataSource = ref.watch(exchangeRateLocalDataSourceProvider);
  return CurrencyServiceImpl(localDataSource: localDataSource);
});

/// Provider for ReportGenerator
final reportGeneratorProvider = Provider<ReportGenerator>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final categoryService = ref.watch(categoryServiceProvider);
  return ReportGeneratorImpl(
    transactionRepository: transactionRepository,
    categoryService: categoryService,
  );
});

/// Dashboard data model
class DashboardData {
  final Decimal balance;
  final Map<String, Decimal> spendingBreakdown;
  final List<SavingsGoal> activeGoals;
  final Map<String, Category> categories;
  final bool hasTransactions;

  const DashboardData({
    required this.balance,
    required this.spendingBreakdown,
    required this.activeGoals,
    required this.categories,
    required this.hasTransactions,
  });
}

/// Provider for dashboard data
final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User not authenticated');
  }

  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final savingsGoalManager = ref.watch(savingsGoalManagerProvider);
  final categoryService = ref.watch(categoryServiceProvider);

  // Calculate balance
  final balance = await transactionRepo.calculateBalance(user.id);

  // Get monthly spending breakdown
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  final monthRange = DateRange(start: startOfMonth, end: endOfMonth);

  final spendingBreakdown = await transactionRepo.getSpendingBreakdown(
    userId: user.id,
    range: monthRange,
  );

  // Get active savings goals
  final activeGoals = await savingsGoalManager.getActive(user.id);

  // Get all categories to map category IDs to names
  final allCategories = await categoryService.getAllCategories(user.id);
  final categoryMap = {for (var cat in allCategories) cat.id: cat};

  // Check if user has any transactions
  final allTransactions = await transactionRepo.getAll(userId: user.id);
  final hasTransactions = allTransactions.isNotEmpty;

  return DashboardData(
    balance: balance,
    spendingBreakdown: spendingBreakdown,
    activeGoals: activeGoals,
    categories: categoryMap,
    hasTransactions: hasTransactions,
  );
});
