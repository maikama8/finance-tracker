/// Service for managing offline-first synchronization with cloud storage
abstract class SyncManager {
  /// Synchronize all data (transactions, goals, budgets)
  Future<SyncResult> syncAll();

  /// Synchronize only transactions
  Future<SyncResult> syncTransactions();

  /// Synchronize only savings goals
  Future<SyncResult> syncGoals();

  /// Synchronize only budgets
  Future<SyncResult> syncBudgets();

  /// Stream of sync status updates for UI
  Stream<SyncStatus> get syncStatusStream;

  /// Get the last successful sync time
  Future<DateTime?> getLastSyncTime();

  /// Resolve a conflict manually
  Future<void> resolveConflict(Conflict conflict, ResolutionStrategy strategy);
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int itemsSynced;
  final int conflicts;
  final int failures;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    required this.itemsSynced,
    required this.conflicts,
    required this.failures,
    this.errorMessage,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, synced: $itemsSynced, conflicts: $conflicts, failures: $failures)';
  }
}

/// Status of the sync operation
class SyncStatus {
  final SyncState state;
  final String? message;
  final DateTime? lastSyncTime;
  final int pendingItems;

  const SyncStatus({
    required this.state,
    this.message,
    this.lastSyncTime,
    this.pendingItems = 0,
  });

  @override
  String toString() {
    return 'SyncStatus(state: $state, pending: $pendingItems, lastSync: $lastSyncTime)';
  }
}

/// Enum representing the state of synchronization
enum SyncState {
  idle,
  syncing,
  success,
  failure,
  offline,
}

/// Represents a conflict between local and remote data
class Conflict {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;

  const Conflict({
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
  });

  @override
  String toString() {
    return 'Conflict(type: $entityType, id: $entityId, local: $localTimestamp, remote: $remoteTimestamp)';
  }
}

/// Strategy for resolving conflicts
enum ResolutionStrategy {
  useLocal,
  useRemote,
  lastWriteWins,
}
