import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:decimal/decimal.dart';
import 'package:personal_finance_tracker/domain/entities/transaction.dart' as domain;
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/domain/services/sync_manager.dart';
import 'package:personal_finance_tracker/infrastructure/services/sync_manager_impl.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/sync_queue_local_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/hive_type_adapters.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/transaction_local_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/category_local_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/savings_goal_local_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/budget_local_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/datasources/cloud/transaction_cloud_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/datasources/cloud/category_cloud_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/datasources/cloud/savings_goal_cloud_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/datasources/cloud/budget_cloud_data_source.dart';

@GenerateMocks([
  SyncQueueLocalDataSource,
  Connectivity,
  TransactionLocalDataSource,
  CategoryLocalDataSource,
  SavingsGoalLocalDataSource,
  BudgetLocalDataSource,
  TransactionCloudDataSource,
  CategoryCloudDataSource,
  SavingsGoalCloudDataSource,
  BudgetCloudDataSource,
])
import 'sync_manager_integration_test.mocks.dart';

void main() {
  late SyncManagerImpl syncManager;
  late MockSyncQueueLocalDataSource mockSyncQueue;
  late MockConnectivity mockConnectivity;
  late SharedPreferences prefs;
  late MockTransactionLocalDataSource mockTransactionLocal;
  late MockCategoryLocalDataSource mockCategoryLocal;
  late MockSavingsGoalLocalDataSource mockSavingsGoalLocal;
  late MockBudgetLocalDataSource mockBudgetLocal;
  late MockTransactionCloudDataSource mockTransactionCloud;
  late MockCategoryCloudDataSource mockCategoryCloud;
  late MockSavingsGoalCloudDataSource mockSavingsGoalCloud;
  late MockBudgetCloudDataSource mockBudgetCloud;

  setUp(() async {
    // Initialize mocks
    mockSyncQueue = MockSyncQueueLocalDataSource();
    mockConnectivity = MockConnectivity();
    mockTransactionLocal = MockTransactionLocalDataSource();
    mockCategoryLocal = MockCategoryLocalDataSource();
    mockSavingsGoalLocal = MockSavingsGoalLocalDataSource();
    mockBudgetLocal = MockBudgetLocalDataSource();
    mockTransactionCloud = MockTransactionCloudDataSource();
    mockCategoryCloud = MockCategoryCloudDataSource();
    mockSavingsGoalCloud = MockSavingsGoalCloudDataSource();
    mockBudgetCloud = MockBudgetCloudDataSource();

    // Initialize SharedPreferences
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // Mock connectivity stream
    when(mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));
    
    // Mock default sync queue behavior
    when(mockSyncQueue.getCount()).thenAnswer((_) async => 0);

    // Create sync manager
    syncManager = SyncManagerImpl(
      syncQueue: mockSyncQueue,
      connectivity: mockConnectivity,
      prefs: prefs,
      transactionLocal: mockTransactionLocal,
      categoryLocal: mockCategoryLocal,
      savingsGoalLocal: mockSavingsGoalLocal,
      budgetLocal: mockBudgetLocal,
      transactionCloud: mockTransactionCloud,
      categoryCloud: mockCategoryCloud,
      savingsGoalCloud: mockSavingsGoalCloud,
      budgetCloud: mockBudgetCloud,
    );
  });

  tearDown(() {
    syncManager.dispose();
  });

  group('SyncManager Integration', () {
    test('should sync transaction to cloud when online', () async {
      // Arrange
      final transaction = domain.Transaction(
        id: 'test-transaction-1',
        userId: 'user-1',
        amount: Decimal.fromInt(100),
        currency: Currency.USD,
        type: domain.TransactionType.expense,
        categoryId: 'category-1',
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: domain.SyncStatus.pending,
      );

      // Mock connectivity as online
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      // Mock sync queue
      when(mockSyncQueue.getCount()).thenAnswer((_) async => 1);
      when(mockSyncQueue.getAll()).thenAnswer((_) async => [
            SyncQueueItem(
              id: 'queue-1',
              entityType: 'transaction',
              entityId: transaction.id,
              operation: 'create',
              data: {},
              timestamp: DateTime.now(),
              retryCount: 0,
            ),
          ]);

      // Mock local data source
      when(mockTransactionLocal.getById(transaction.id))
          .thenAnswer((_) async => transaction);
      when(mockTransactionLocal.update(any))
          .thenAnswer((_) async => transaction.copyWith(
                syncStatus: domain.SyncStatus.synced,
              ));

      // Mock cloud data source
      when(mockTransactionCloud.getById(transaction.id))
          .thenAnswer((_) async => null); // Doesn't exist yet
      when(mockTransactionCloud.create(any))
          .thenAnswer((_) async => transaction);

      // Mock sync queue operations
      when(mockSyncQueue.batchDequeue(any)).thenAnswer((_) async => {});

      // Act
      final result = await syncManager.syncAll();

      // Assert
      expect(result.success, isTrue);
      expect(result.itemsSynced, equals(1));
      expect(result.failures, equals(0));

      // Verify cloud create was called
      verify(mockTransactionCloud.create(any)).called(1);
      verify(mockTransactionLocal.update(any)).called(1);
    });

    test('should handle offline state gracefully', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      when(mockSyncQueue.getCount()).thenAnswer((_) async => 5);

      // Act
      final result = await syncManager.syncAll();

      // Assert
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('No internet connection'));
      expect(result.itemsSynced, equals(0));
    });

    test('should return early when no pending items', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockSyncQueue.getCount()).thenAnswer((_) async => 0);
      when(mockSyncQueue.getAll()).thenAnswer((_) async => []);

      // Act
      final result = await syncManager.syncAll();

      // Assert
      expect(result.success, isTrue);
      expect(result.itemsSynced, equals(0));
      expect(result.failures, equals(0));
    });

    test('should not sync when already syncing', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockSyncQueue.getCount()).thenAnswer((_) async => 1);
      when(mockSyncQueue.getAll()).thenAnswer((_) async => []);

      // Start first sync (will be slow)
      final firstSync = syncManager.syncAll();

      // Try to start second sync immediately
      final secondSync = await syncManager.syncAll();

      // Assert second sync was rejected
      expect(secondSync.success, isFalse);
      expect(secondSync.errorMessage, contains('already in progress'));

      // Wait for first sync to complete
      await firstSync;
    });
  });

  group('SyncManager Status Stream', () {
    test('should emit status updates during sync', () async {
      // Arrange
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockSyncQueue.getCount()).thenAnswer((_) async => 0);
      when(mockSyncQueue.getAll()).thenAnswer((_) async => []);

      // Listen to status stream
      final statuses = <SyncState>[];
      syncManager.syncStatusStream.listen((status) {
        statuses.add(status.state);
      });

      // Act
      await syncManager.syncAll();

      // Wait a bit for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(statuses, contains(SyncState.syncing));
      expect(statuses, contains(SyncState.success));
    });
  });
}
