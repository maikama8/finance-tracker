import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:decimal/decimal.dart';
import '../../domain/services/sync_manager.dart';
import '../data_sources/local/sync_queue_local_data_source.dart';
import '../data_sources/local/hive_type_adapters.dart';
import '../data_sources/local/transaction_local_data_source.dart';
import '../data_sources/local/category_local_data_source.dart';
import '../data_sources/local/savings_goal_local_data_source.dart';
import '../data_sources/local/budget_local_data_source.dart';
import '../datasources/cloud/transaction_cloud_data_source.dart';
import '../datasources/cloud/category_cloud_data_source.dart';
import '../datasources/cloud/savings_goal_cloud_data_source.dart';
import '../datasources/cloud/budget_cloud_data_source.dart';
import '../../domain/entities/transaction.dart' as domain;
import '../../domain/entities/category.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/entities/budget.dart';
import '../../domain/value_objects/currency.dart';

/// Implementation of SyncManager for offline-first synchronization
class SyncManagerImpl implements SyncManager {
  final SyncQueueLocalDataSource _syncQueue;
  final Connectivity _connectivity;
  final SharedPreferences _prefs;
  
  // Local data sources
  final TransactionLocalDataSource _transactionLocal;
  final CategoryLocalDataSource _categoryLocal;
  final SavingsGoalLocalDataSource _savingsGoalLocal;
  final BudgetLocalDataSource _budgetLocal;
  
  // Cloud data sources
  final TransactionCloudDataSource _transactionCloud;
  final CategoryCloudDataSource _categoryCloud;
  final SavingsGoalCloudDataSource _savingsGoalCloud;
  final BudgetCloudDataSource _budgetCloud;
  
  // Stream controllers
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  // Constants
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  
  // State
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;

  SyncManagerImpl({
    required SyncQueueLocalDataSource syncQueue,
    required Connectivity connectivity,
    required SharedPreferences prefs,
    required TransactionLocalDataSource transactionLocal,
    required CategoryLocalDataSource categoryLocal,
    required SavingsGoalLocalDataSource savingsGoalLocal,
    required BudgetLocalDataSource budgetLocal,
    required TransactionCloudDataSource transactionCloud,
    required CategoryCloudDataSource categoryCloud,
    required SavingsGoalCloudDataSource savingsGoalCloud,
    required BudgetCloudDataSource budgetCloud,
  })  : _syncQueue = syncQueue,
        _connectivity = connectivity,
        _prefs = prefs,
        _transactionLocal = transactionLocal,
        _categoryLocal = categoryLocal,
        _savingsGoalLocal = savingsGoalLocal,
        _budgetLocal = budgetLocal,
        _transactionCloud = transactionCloud,
        _categoryCloud = categoryCloud,
        _savingsGoalCloud = savingsGoalCloud,
        _budgetCloud = budgetCloud {
    _initConnectivityMonitoring();
  }

  /// Initialize connectivity monitoring
  void _initConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final isOnline = results.any((result) => 
          result != ConnectivityResult.none
        );
        
        if (isOnline && !_isSyncing) {
          // Automatically sync when coming online
          final pendingCount = await _syncQueue.getCount();
          if (pendingCount > 0) {
            _emitStatus(SyncStatus(
              state: SyncState.idle,
              message: 'Connection restored. $pendingCount items pending sync.',
              lastSyncTime: await getLastSyncTime(),
              pendingItems: pendingCount,
            ));
            
            // Trigger sync after a short delay
            Future.delayed(const Duration(seconds: 2), () => syncAll());
          }
        } else if (!isOnline) {
          _emitStatus(SyncStatus(
            state: SyncState.offline,
            message: 'No internet connection',
            lastSyncTime: await getLastSyncTime(),
            pendingItems: await _syncQueue.getCount(),
          ));
        }
      },
    );
  }

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  @override
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = _prefs.getInt(_lastSyncTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> _setLastSyncTime(DateTime time) async {
    await _prefs.setInt(_lastSyncTimeKey, time.millisecondsSinceEpoch);
  }

  void _emitStatus(SyncStatus status) {
    if (!_syncStatusController.isClosed) {
      _syncStatusController.add(status);
    }
  }

  @override
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        itemsSynced: 0,
        conflicts: 0,
        failures: 0,
        errorMessage: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }

    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.any((result) => 
      result != ConnectivityResult.none
    );
    
    if (!isOnline) {
      final pendingCount = await _syncQueue.getCount();
      _emitStatus(SyncStatus(
        state: SyncState.offline,
        message: 'Cannot sync: No internet connection',
        lastSyncTime: await getLastSyncTime(),
        pendingItems: pendingCount,
      ));
      
      return SyncResult(
        success: false,
        itemsSynced: 0,
        conflicts: 0,
        failures: 0,
        errorMessage: 'No internet connection',
        timestamp: DateTime.now(),
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();
    
    _emitStatus(SyncStatus(
      state: SyncState.syncing,
      message: 'Synchronizing...',
      lastSyncTime: await getLastSyncTime(),
      pendingItems: await _syncQueue.getCount(),
    ));

    try {
      // Get all pending items from the queue
      final pendingItems = await _syncQueue.getAll();
      
      if (pendingItems.isEmpty) {
        _isSyncing = false;
        final result = SyncResult(
          success: true,
          itemsSynced: 0,
          conflicts: 0,
          failures: 0,
          timestamp: startTime,
        );
        
        await _setLastSyncTime(startTime);
        
        _emitStatus(SyncStatus(
          state: SyncState.success,
          message: 'All data is up to date',
          lastSyncTime: startTime,
          pendingItems: 0,
        ));
        
        return result;
      }

      int synced = 0;
      int conflicts = 0;
      int failures = 0;
      final List<String> syncedIds = [];

      // Process each item
      for (final item in pendingItems) {
        try {
          // Attempt to sync the item
          final syncSuccess = await _syncItem(item);
          
          if (syncSuccess) {
            synced++;
            syncedIds.add(item.id);
          } else {
            // Check if we should retry
            if (item.retryCount < _maxRetries) {
              await _syncQueue.incrementRetryCount(item.id);
              
              // Schedule retry with exponential backoff
              _scheduleRetry(item.retryCount + 1);
            } else {
              // Max retries reached - notify user
              failures++;
              await _notifyUserOfFailure(item);
            }
          }
        } catch (e) {
          // Handle sync error
          if (item.retryCount < _maxRetries) {
            await _syncQueue.incrementRetryCount(item.id);
            _scheduleRetry(item.retryCount + 1);
          } else {
            failures++;
            await _notifyUserOfFailure(item);
          }
        }
      }

      // Remove successfully synced items from queue
      if (syncedIds.isNotEmpty) {
        await _syncQueue.batchDequeue(syncedIds);
      }

      final result = SyncResult(
        success: failures == 0,
        itemsSynced: synced,
        conflicts: conflicts,
        failures: failures,
        errorMessage: failures > 0 ? '$failures items failed to sync' : null,
        timestamp: startTime,
      );

      if (result.success) {
        await _setLastSyncTime(startTime);
      }

      _emitStatus(SyncStatus(
        state: result.success ? SyncState.success : SyncState.failure,
        message: result.success 
          ? 'Sync completed: $synced items synced'
          : 'Sync completed with errors: $failures failures',
        lastSyncTime: result.success ? startTime : await getLastSyncTime(),
        pendingItems: await _syncQueue.getCount(),
      ));

      return result;
    } catch (e) {
      final result = SyncResult(
        success: false,
        itemsSynced: 0,
        conflicts: 0,
        failures: 0,
        errorMessage: e.toString(),
        timestamp: startTime,
      );

      _emitStatus(SyncStatus(
        state: SyncState.failure,
        message: 'Sync failed: ${e.toString()}',
        lastSyncTime: await getLastSyncTime(),
        pendingItems: await _syncQueue.getCount(),
      ));

      return result;
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<SyncResult> syncTransactions() async {
    return await _syncByEntityType('transaction');
  }

  @override
  Future<SyncResult> syncGoals() async {
    return await _syncByEntityType('goal');
  }

  @override
  Future<SyncResult> syncBudgets() async {
    return await _syncByEntityType('budget');
  }

  /// Sync items of a specific entity type
  Future<SyncResult> _syncByEntityType(String entityType) async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        itemsSynced: 0,
        conflicts: 0,
        failures: 0,
        errorMessage: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }

    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    final isOnline = connectivityResult.any((result) => 
      result != ConnectivityResult.none
    );
    
    if (!isOnline) {
      return SyncResult(
        success: false,
        itemsSynced: 0,
        conflicts: 0,
        failures: 0,
        errorMessage: 'No internet connection',
        timestamp: DateTime.now(),
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();

    try {
      final items = await _syncQueue.getByEntityType(entityType);
      
      if (items.isEmpty) {
        _isSyncing = false;
        return SyncResult(
          success: true,
          itemsSynced: 0,
          conflicts: 0,
          failures: 0,
          timestamp: startTime,
        );
      }

      int synced = 0;
      int failures = 0;
      final List<String> syncedIds = [];

      for (final item in items) {
        try {
          final syncSuccess = await _syncItem(item);
          
          if (syncSuccess) {
            synced++;
            syncedIds.add(item.id);
          } else {
            if (item.retryCount < _maxRetries) {
              await _syncQueue.incrementRetryCount(item.id);
            } else {
              failures++;
            }
          }
        } catch (e) {
          if (item.retryCount < _maxRetries) {
            await _syncQueue.incrementRetryCount(item.id);
          } else {
            failures++;
          }
        }
      }

      if (syncedIds.isNotEmpty) {
        await _syncQueue.batchDequeue(syncedIds);
      }

      return SyncResult(
        success: failures == 0,
        itemsSynced: synced,
        conflicts: 0,
        failures: failures,
        errorMessage: failures > 0 ? '$failures items failed to sync' : null,
        timestamp: startTime,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single item to cloud storage
  Future<bool> _syncItem(SyncQueueItem item) async {
    try {
      // Step 1: Fetch remote data to check for conflicts
      final remoteData = await _fetchRemoteData(item.entityType, item.entityId);
      
      // Step 2: Detect conflicts by comparing timestamps
      if (remoteData != null) {
        final conflict = await _detectConflict(item, remoteData);
        
        if (conflict != null) {
          // Step 3: Apply last-write-wins strategy automatically
          await resolveConflict(conflict, ResolutionStrategy.lastWriteWins);
          return true;
        }
      }
      
      // Step 4: No conflict, proceed with sync
      final success = await _uploadToCloud(item);
      return success;
    } catch (e) {
      print('Error syncing item ${item.entityType}:${item.entityId}: $e');
      return false;
    }
  }

  /// Fetch remote data for conflict detection
  Future<Map<String, dynamic>?> _fetchRemoteData(
    String entityType,
    String entityId,
  ) async {
    try {
      switch (entityType) {
        case 'transaction':
          final transaction = await _transactionCloud.getById(entityId);
          if (transaction == null) return null;
          return _transactionToMap(transaction);
          
        case 'category':
          final category = await _categoryCloud.getById(entityId);
          if (category == null) return null;
          return _categoryToMap(category);
          
        case 'goal':
          final goal = await _savingsGoalCloud.getById(entityId);
          if (goal == null) return null;
          return _savingsGoalToMap(goal);
          
        case 'budget':
          final budget = await _budgetCloud.getById(entityId);
          if (budget == null) return null;
          return _budgetToMap(budget);
          
        default:
          print('Unknown entity type: $entityType');
          return null;
      }
    } catch (e) {
      print('Error fetching remote data for $entityType:$entityId: $e');
      return null;
    }
  }

  /// Detect if there's a conflict between local and remote data
  Future<Conflict?> _detectConflict(
    SyncQueueItem item,
    Map<String, dynamic> remoteData,
  ) async {
    // Extract timestamps
    final localTimestamp = item.data['updatedAt'] != null
        ? DateTime.parse(item.data['updatedAt'] as String)
        : item.timestamp;
    
    final remoteTimestamp = remoteData['updatedAt'] != null
        ? DateTime.parse(remoteData['updatedAt'] as String)
        : DateTime.now();

    // Check if timestamps differ significantly (more than 1 second)
    final timeDiff = localTimestamp.difference(remoteTimestamp).abs();
    
    if (timeDiff.inSeconds > 1) {
      // Conflict detected
      return Conflict(
        entityType: item.entityType,
        entityId: item.entityId,
        localData: item.data,
        remoteData: remoteData,
        localTimestamp: localTimestamp,
        remoteTimestamp: remoteTimestamp,
      );
    }
    
    return null;
  }

  /// Upload data to cloud storage
  Future<bool> _uploadToCloud(SyncQueueItem item) async {
    try {
      switch (item.entityType) {
        case 'transaction':
          final transaction = await _transactionLocal.getById(item.entityId);
          if (transaction == null) {
            print('Transaction not found locally: ${item.entityId}');
            return false;
          }
          
          // Check if it exists in cloud (update) or not (create)
          final existing = await _transactionCloud.getById(item.entityId);
          if (existing != null) {
            await _transactionCloud.update(transaction);
          } else {
            await _transactionCloud.create(transaction);
          }
          
          // Update local sync status to synced
          final synced = transaction.copyWith(
            syncStatus: domain.SyncStatus.synced,
          );
          await _transactionLocal.update(synced);
          return true;
          
        case 'category':
          final category = await _categoryLocal.getById(item.entityId);
          if (category == null) {
            print('Category not found locally: ${item.entityId}');
            return false;
          }
          
          final existing = await _categoryCloud.getById(item.entityId);
          if (existing != null) {
            await _categoryCloud.update(category);
          } else {
            await _categoryCloud.create(category);
          }
          
          await _categoryLocal.update(category);
          return true;
          
        case 'goal':
          final goal = await _savingsGoalLocal.getById(item.entityId);
          if (goal == null) {
            print('Savings goal not found locally: ${item.entityId}');
            return false;
          }
          
          final existing = await _savingsGoalCloud.getById(item.entityId);
          if (existing != null) {
            await _savingsGoalCloud.update(goal);
          } else {
            await _savingsGoalCloud.create(goal);
          }
          
          // Update local sync status to synced
          final synced = goal.copyWith(
            syncStatus: domain.SyncStatus.synced,
          );
          await _savingsGoalLocal.update(synced);
          return true;
          
        case 'budget':
          final budget = await _budgetLocal.getById(item.entityId);
          if (budget == null) {
            print('Budget not found locally: ${item.entityId}');
            return false;
          }
          
          final existing = await _budgetCloud.getById(item.entityId);
          if (existing != null) {
            await _budgetCloud.update(budget);
          } else {
            await _budgetCloud.create(budget);
          }
          
          // Update local sync status to synced
          final synced = budget.copyWith(
            syncStatus: domain.SyncStatus.synced,
          );
          await _budgetLocal.update(synced);
          return true;
          
        default:
          print('Unknown entity type: ${item.entityType}');
          return false;
      }
    } catch (e) {
      print('Error uploading to cloud: $e');
      return false;
    }
  }

  @override
  Future<void> resolveConflict(
    Conflict conflict,
    ResolutionStrategy strategy,
  ) async {
    // Determine which data to use based on strategy
    Map<String, dynamic> resolvedData;
    DateTime resolvedTimestamp;
    
    switch (strategy) {
      case ResolutionStrategy.useLocal:
        resolvedData = conflict.localData;
        resolvedTimestamp = conflict.localTimestamp;
        break;
      case ResolutionStrategy.useRemote:
        resolvedData = conflict.remoteData;
        resolvedTimestamp = conflict.remoteTimestamp;
        break;
      case ResolutionStrategy.lastWriteWins:
        // Compare timestamps and use the most recent
        if (conflict.localTimestamp.isAfter(conflict.remoteTimestamp)) {
          resolvedData = conflict.localData;
          resolvedTimestamp = conflict.localTimestamp;
        } else {
          resolvedData = conflict.remoteData;
          resolvedTimestamp = conflict.remoteTimestamp;
        }
        break;
    }

    // Apply the resolved data
    try {
      // Update local storage with resolved data
      await _updateLocalStorage(
        conflict.entityType,
        conflict.entityId,
        resolvedData,
      );
      
      // Update cloud storage with resolved data
      await _updateCloudStorage(
        conflict.entityType,
        conflict.entityId,
        resolvedData,
      );
      
      print('Resolved conflict for ${conflict.entityType}:${conflict.entityId} '
          'using $strategy (timestamp: $resolvedTimestamp)');
    } catch (e) {
      print('Error resolving conflict: $e');
      rethrow;
    }
  }

  /// Update local storage with resolved data
  Future<void> _updateLocalStorage(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (entityType) {
        case 'transaction':
          final transaction = _mapToTransaction(data);
          await _transactionLocal.update(transaction);
          break;
          
        case 'category':
          final category = _mapToCategory(data);
          await _categoryLocal.update(category);
          break;
          
        case 'goal':
          final goal = _mapToSavingsGoal(data);
          await _savingsGoalLocal.update(goal);
          break;
          
        case 'budget':
          final budget = _mapToBudget(data);
          await _budgetLocal.update(budget);
          break;
          
        default:
          print('Unknown entity type: $entityType');
      }
    } catch (e) {
      print('Error updating local storage: $e');
      rethrow;
    }
  }

  /// Update cloud storage with resolved data
  Future<void> _updateCloudStorage(
    String entityType,
    String entityId,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (entityType) {
        case 'transaction':
          final transaction = _mapToTransaction(data);
          await _transactionCloud.update(transaction);
          break;
          
        case 'category':
          final category = _mapToCategory(data);
          await _categoryCloud.update(category);
          break;
          
        case 'goal':
          final goal = _mapToSavingsGoal(data);
          await _savingsGoalCloud.update(goal);
          break;
          
        case 'budget':
          final budget = _mapToBudget(data);
          await _budgetCloud.update(budget);
          break;
          
        default:
          print('Unknown entity type: $entityType');
      }
    } catch (e) {
      print('Error updating cloud storage: $e');
      rethrow;
    }
  }

  /// Schedule a retry with exponential backoff
  void _scheduleRetry(int retryCount) {
    // Cancel existing retry timer
    _retryTimer?.cancel();
    
    // Calculate delay with exponential backoff: 5s, 10s, 20s
    final delay = _retryDelay * (1 << (retryCount - 1));
    
    _retryTimer = Timer(delay, () {
      // Attempt sync again
      syncAll();
    });
    
    _emitStatus(SyncStatus(
      state: SyncState.idle,
      message: 'Retry scheduled in ${delay.inSeconds} seconds (attempt $retryCount/$_maxRetries)',
      lastSyncTime: getLastSyncTime() as DateTime?,
      pendingItems: _syncQueue.getCount() as int,
    ));
  }

  /// Notify user of sync failure after max retries
  Future<void> _notifyUserOfFailure(SyncQueueItem item) async {
    // TODO: Implement actual notification
    // This would use the NotificationService to send a push notification
    
    final message = 'Failed to sync ${item.entityType} after $_maxRetries attempts. '
        'Data will be queued for next sync.';
    
    print('SYNC FAILURE: $message');
    
    _emitStatus(SyncStatus(
      state: SyncState.failure,
      message: message,
      lastSyncTime: await getLastSyncTime(),
      pendingItems: await _syncQueue.getCount(),
    ));
  }

  // ========== Helper Methods for Entity Conversion ==========

  /// Convert Transaction entity to Map
  Map<String, dynamic> _transactionToMap(domain.Transaction transaction) {
    return {
      'id': transaction.id,
      'userId': transaction.userId,
      'amount': transaction.amount.toString(),
      'currency': transaction.currency.code,
      'type': transaction.type.name,
      'categoryId': transaction.categoryId,
      'date': transaction.date.toIso8601String(),
      'notes': transaction.notes,
      'receiptImageId': transaction.receiptImageId,
      'createdAt': transaction.createdAt.toIso8601String(),
      'updatedAt': transaction.updatedAt.toIso8601String(),
      'syncStatus': transaction.syncStatus.name,
    };
  }

  /// Convert Map to Transaction entity
  domain.Transaction _mapToTransaction(Map<String, dynamic> data) {
    final currency = Currency.fromCode(data['currency'] as String);
    if (currency == null) {
      throw Exception('Unknown currency code: ${data['currency']}');
    }
    
    return domain.Transaction(
      id: data['id'] as String,
      userId: data['userId'] as String,
      amount: Decimal.parse(data['amount'] as String),
      currency: currency,
      type: domain.TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
      ),
      categoryId: data['categoryId'] as String,
      date: DateTime.parse(data['date'] as String),
      notes: data['notes'] as String?,
      receiptImageId: data['receiptImageId'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      syncStatus: domain.SyncStatus.values.firstWhere(
        (e) => e.name == data['syncStatus'],
        orElse: () => domain.SyncStatus.synced,
      ),
    );
  }

  /// Convert Category entity to Map
  Map<String, dynamic> _categoryToMap(Category category) {
    return {
      'id': category.id,
      'userId': category.userId,
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
      'parentCategoryId': category.parentCategoryId,
      'isDefault': category.isDefault,
      'locale': category.locale,
      'createdAt': category.createdAt.toIso8601String(),
      'updatedAt': category.updatedAt.toIso8601String(),
    };
  }

  /// Convert Map to Category entity
  Category _mapToCategory(Map<String, dynamic> data) {
    return Category(
      id: data['id'] as String,
      userId: data['userId'] as String?,
      name: data['name'] as String,
      icon: data['icon'] as String,
      color: data['color'] as String,
      parentCategoryId: data['parentCategoryId'] as String?,
      isDefault: data['isDefault'] as bool? ?? false,
      locale: data['locale'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }

  /// Convert SavingsGoal entity to Map
  Map<String, dynamic> _savingsGoalToMap(SavingsGoal goal) {
    return {
      'id': goal.id,
      'userId': goal.userId,
      'name': goal.name,
      'targetAmount': goal.targetAmount.toString(),
      'currency': goal.currency.code,
      'currentAmount': goal.currentAmount.toString(),
      'deadline': goal.deadline.toIso8601String(),
      'reminderEnabled': goal.reminderEnabled,
      'reminderFrequency': goal.reminderFrequency?.name,
      'lastReminderSent': goal.lastReminderSent?.toIso8601String(),
      'createdAt': goal.createdAt.toIso8601String(),
      'updatedAt': goal.updatedAt.toIso8601String(),
      'syncStatus': goal.syncStatus.name,
    };
  }

  /// Convert Map to SavingsGoal entity
  SavingsGoal _mapToSavingsGoal(Map<String, dynamic> data) {
    final currency = Currency.fromCode(data['currency'] as String);
    if (currency == null) {
      throw Exception('Unknown currency code: ${data['currency']}');
    }
    
    return SavingsGoal(
      id: data['id'] as String,
      userId: data['userId'] as String,
      name: data['name'] as String,
      targetAmount: Decimal.parse(data['targetAmount'] as String),
      currency: currency,
      currentAmount: Decimal.parse(data['currentAmount'] as String),
      deadline: DateTime.parse(data['deadline'] as String),
      reminderEnabled: data['reminderEnabled'] as bool? ?? false,
      reminderFrequency: data['reminderFrequency'] != null
          ? ReminderFrequency.values.firstWhere(
              (e) => e.name == data['reminderFrequency'],
            )
          : null,
      lastReminderSent: data['lastReminderSent'] != null
          ? DateTime.parse(data['lastReminderSent'] as String)
          : null,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      syncStatus: domain.SyncStatus.values.firstWhere(
        (e) => e.name == data['syncStatus'],
        orElse: () => domain.SyncStatus.synced,
      ),
    );
  }

  /// Convert Budget entity to Map
  Map<String, dynamic> _budgetToMap(Budget budget) {
    return {
      'id': budget.id,
      'userId': budget.userId,
      'categoryId': budget.categoryId,
      'monthlyLimit': budget.monthlyLimit.toString(),
      'currency': budget.currency.code,
      'currentSpending': budget.currentSpending.toString(),
      'month': budget.month,
      'year': budget.year,
      'createdAt': budget.createdAt.toIso8601String(),
      'updatedAt': budget.updatedAt.toIso8601String(),
      'syncStatus': budget.syncStatus.name,
    };
  }

  /// Convert Map to Budget entity
  Budget _mapToBudget(Map<String, dynamic> data) {
    final currency = Currency.fromCode(data['currency'] as String);
    if (currency == null) {
      throw Exception('Unknown currency code: ${data['currency']}');
    }
    
    return Budget(
      id: data['id'] as String,
      userId: data['userId'] as String,
      categoryId: data['categoryId'] as String,
      monthlyLimit: Decimal.parse(data['monthlyLimit'] as String),
      currency: currency,
      currentSpending: Decimal.parse(data['currentSpending'] as String),
      month: data['month'] as int,
      year: data['year'] as int,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      syncStatus: domain.SyncStatus.values.firstWhere(
        (e) => e.name == data['syncStatus'],
        orElse: () => domain.SyncStatus.synced,
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _syncStatusController.close();
  }
}
