import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/domain/services/sync_manager.dart';

void main() {
  group('SyncResult', () {
    test('should create successful result', () {
      final result = SyncResult(
        success: true,
        itemsSynced: 5,
        conflicts: 0,
        failures: 0,
        timestamp: DateTime.now(),
      );

      expect(result.success, isTrue);
      expect(result.itemsSynced, equals(5));
      expect(result.conflicts, equals(0));
      expect(result.failures, equals(0));
    });

    test('should create failed result with error message', () {
      final result = SyncResult(
        success: false,
        itemsSynced: 0,
        conflicts: 0,
        failures: 3,
        errorMessage: 'Network error',
        timestamp: DateTime.now(),
      );

      expect(result.success, isFalse);
      expect(result.failures, equals(3));
      expect(result.errorMessage, equals('Network error'));
    });

    test('should have proper toString representation', () {
      final result = SyncResult(
        success: true,
        itemsSynced: 10,
        conflicts: 2,
        failures: 1,
        timestamp: DateTime.now(),
      );

      final str = result.toString();
      expect(str, contains('success: true'));
      expect(str, contains('synced: 10'));
      expect(str, contains('conflicts: 2'));
      expect(str, contains('failures: 1'));
    });
  });

  group('SyncStatus', () {
    test('should create status with all fields', () {
      final now = DateTime.now();
      final status = SyncStatus(
        state: SyncState.syncing,
        message: 'Syncing data...',
        lastSyncTime: now,
        pendingItems: 5,
      );

      expect(status.state, equals(SyncState.syncing));
      expect(status.message, equals('Syncing data...'));
      expect(status.lastSyncTime, equals(now));
      expect(status.pendingItems, equals(5));
    });

    test('should create status with minimal fields', () {
      final status = SyncStatus(
        state: SyncState.idle,
      );

      expect(status.state, equals(SyncState.idle));
      expect(status.message, isNull);
      expect(status.lastSyncTime, isNull);
      expect(status.pendingItems, equals(0));
    });

    test('should have proper toString representation', () {
      final status = SyncStatus(
        state: SyncState.success,
        pendingItems: 3,
      );

      final str = status.toString();
      expect(str, contains('state: SyncState.success'));
      expect(str, contains('pending: 3'));
    });
  });

  group('Conflict', () {
    test('should create conflict with timestamps', () {
      final now = DateTime.now();
      final conflict = Conflict(
        entityType: 'transaction',
        entityId: 'test-id',
        localData: {'amount': 100},
        remoteData: {'amount': 200},
        localTimestamp: now,
        remoteTimestamp: now.subtract(const Duration(hours: 1)),
      );

      expect(conflict.entityType, equals('transaction'));
      expect(conflict.entityId, equals('test-id'));
      expect(conflict.localTimestamp.isAfter(conflict.remoteTimestamp), isTrue);
      expect(conflict.localData['amount'], equals(100));
      expect(conflict.remoteData['amount'], equals(200));
    });

    test('should have proper toString representation', () {
      final now = DateTime.now();
      final conflict = Conflict(
        entityType: 'goal',
        entityId: 'goal-123',
        localData: {},
        remoteData: {},
        localTimestamp: now,
        remoteTimestamp: now.subtract(const Duration(minutes: 30)),
      );

      final str = conflict.toString();
      expect(str, contains('type: goal'));
      expect(str, contains('id: goal-123'));
    });
  });

  group('SyncState enum', () {
    test('should have all expected states', () {
      expect(SyncState.values, contains(SyncState.idle));
      expect(SyncState.values, contains(SyncState.syncing));
      expect(SyncState.values, contains(SyncState.success));
      expect(SyncState.values, contains(SyncState.failure));
      expect(SyncState.values, contains(SyncState.offline));
    });
  });

  group('ResolutionStrategy enum', () {
    test('should have all expected strategies', () {
      expect(ResolutionStrategy.values, contains(ResolutionStrategy.useLocal));
      expect(ResolutionStrategy.values, contains(ResolutionStrategy.useRemote));
      expect(ResolutionStrategy.values, contains(ResolutionStrategy.lastWriteWins));
    });
  });
}
