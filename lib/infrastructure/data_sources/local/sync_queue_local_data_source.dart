import 'package:hive/hive.dart';
import 'hive_database.dart';
import 'hive_type_adapters.dart';

/// Local data source for sync queue using Hive
class SyncQueueLocalDataSource {
  final HiveDatabase _database;

  SyncQueueLocalDataSource(this._database);

  /// Get the sync queue box
  Box _getBox() => _database.getBox(HiveBoxNames.syncQueue);

  /// Add an item to the sync queue
  Future<SyncQueueItem> enqueue(SyncQueueItem item) async {
    final box = _getBox();
    await box.put(item.id, item);
    return item;
  }

  /// Remove an item from the sync queue
  Future<void> dequeue(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// Get an item by ID
  Future<SyncQueueItem?> getById(String id) async {
    final box = _getBox();
    return box.get(id) as SyncQueueItem?;
  }

  /// Get all items in the sync queue
  Future<List<SyncQueueItem>> getAll() async {
    final box = _getBox();
    final items = box.values.cast<SyncQueueItem>().toList();
    
    // Sort by timestamp (oldest first)
    items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return items;
  }

  /// Get items by entity type
  Future<List<SyncQueueItem>> getByEntityType(String entityType) async {
    final allItems = await getAll();
    return allItems.where((item) => item.entityType == entityType).toList();
  }

  /// Get items by operation
  Future<List<SyncQueueItem>> getByOperation(String operation) async {
    final allItems = await getAll();
    return allItems.where((item) => item.operation == operation).toList();
  }

  /// Get items that need retry (failed items)
  Future<List<SyncQueueItem>> getRetryItems() async {
    final allItems = await getAll();
    return allItems.where((item) => item.retryCount > 0).toList();
  }

  /// Update retry count for an item
  Future<SyncQueueItem> incrementRetryCount(String id) async {
    final item = await getById(id);
    if (item == null) {
      throw Exception('Sync queue item not found: $id');
    }

    final updatedItem = SyncQueueItem(
      id: item.id,
      entityType: item.entityType,
      entityId: item.entityId,
      operation: item.operation,
      data: item.data,
      timestamp: item.timestamp,
      retryCount: item.retryCount + 1,
    );

    await enqueue(updatedItem);
    return updatedItem;
  }

  /// Get count of items in queue
  Future<int> getCount() async {
    final box = _getBox();
    return box.length;
  }

  /// Check if queue is empty
  Future<bool> isEmpty() async {
    final count = await getCount();
    return count == 0;
  }

  /// Clear all items from the queue
  Future<void> clearAll() async {
    final box = _getBox();
    await box.clear();
  }

  /// Batch enqueue multiple items
  Future<void> batchEnqueue(List<SyncQueueItem> items) async {
    final box = _getBox();
    final Map<String, SyncQueueItem> entries = {
      for (var item in items) item.id: item
    };
    await box.putAll(entries);
  }

  /// Batch dequeue multiple items
  Future<void> batchDequeue(List<String> ids) async {
    final box = _getBox();
    await box.deleteAll(ids);
  }

  /// Watch the sync queue (returns a stream)
  Stream<List<SyncQueueItem>> watchAll() {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getAll();
    });
  }

  /// Get queue statistics
  Future<Map<String, dynamic>> getStats() async {
    final allItems = await getAll();
    final retryItems = await getRetryItems();

    final Map<String, int> byEntityType = {};
    final Map<String, int> byOperation = {};

    for (final item in allItems) {
      byEntityType[item.entityType] = (byEntityType[item.entityType] ?? 0) + 1;
      byOperation[item.operation] = (byOperation[item.operation] ?? 0) + 1;
    }

    return {
      'total': allItems.length,
      'retryCount': retryItems.length,
      'byEntityType': byEntityType,
      'byOperation': byOperation,
      'oldestTimestamp': allItems.isNotEmpty ? allItems.first.timestamp.toIso8601String() : null,
    };
  }
}
