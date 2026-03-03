import 'package:hive/hive.dart';
import 'hive_database.dart';
import 'hive_type_adapters.dart';

/// Local data source for receipt image metadata using Hive
class ReceiptImageLocalDataSource {
  final HiveDatabase _database;

  ReceiptImageLocalDataSource(this._database);

  /// Get the receipt images box
  Box _getBox() => _database.getBox(HiveBoxNames.receiptImages);

  /// Store receipt image metadata
  Future<ReceiptImageMetadata> store(ReceiptImageMetadata metadata) async {
    final box = _getBox();
    await box.put(metadata.id, metadata);
    return metadata;
  }

  /// Get receipt image metadata by ID
  Future<ReceiptImageMetadata?> getById(String id) async {
    final box = _getBox();
    return box.get(id) as ReceiptImageMetadata?;
  }

  /// Get all receipt images for a user
  Future<List<ReceiptImageMetadata>> getByUser(String userId) async {
    final box = _getBox();
    final allMetadata = box.values.cast<ReceiptImageMetadata>();

    return allMetadata
        .where((m) => m.userId == userId)
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  /// Get receipt image metadata by transaction ID
  Future<ReceiptImageMetadata?> getByTransaction(String transactionId) async {
    final box = _getBox();
    final allMetadata = box.values.cast<ReceiptImageMetadata>();

    try {
      return allMetadata.firstWhere((m) => m.transactionId == transactionId);
    } catch (e) {
      return null;
    }
  }

  /// Delete receipt image metadata by ID
  Future<void> delete(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// Delete all receipt images for a user
  Future<void> deleteByUser(String userId) async {
    final userMetadata = await getByUser(userId);
    final box = _getBox();

    for (final metadata in userMetadata) {
      await box.delete(metadata.id);
    }
  }

  /// Get total storage size for a user (in bytes)
  Future<int> getTotalStorageSize(String userId) async {
    final userMetadata = await getByUser(userId);
    int total = 0;
    for (final m in userMetadata) {
      total += m.fileSizeBytes;
    }
    return total;
  }

  /// Get count of receipt images for a user
  Future<int> getCount(String userId) async {
    final userMetadata = await getByUser(userId);
    return userMetadata.length;
  }

  /// Clear all receipt image metadata
  Future<void> clearAll() async {
    final box = _getBox();
    await box.clear();
  }

  /// Batch store multiple receipt image metadata
  Future<void> batchStore(List<ReceiptImageMetadata> metadataList) async {
    final box = _getBox();
    final Map<String, ReceiptImageMetadata> entries = {
      for (var m in metadataList) m.id: m
    };
    await box.putAll(entries);
  }

  /// Batch delete multiple receipt image metadata
  Future<void> batchDelete(List<String> ids) async {
    final box = _getBox();
    await box.deleteAll(ids);
  }

  /// Watch all receipt images for a user (returns a stream)
  Stream<List<ReceiptImageMetadata>> watchByUser(String userId) {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getByUser(userId);
    });
  }

  /// Get storage statistics for a user
  Future<Map<String, dynamic>> getStorageStats(String userId) async {
    final userMetadata = await getByUser(userId);
    final totalSize = await getTotalStorageSize(userId);

    return {
      'count': userMetadata.length,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'averageSizeBytes': userMetadata.isNotEmpty ? (totalSize / userMetadata.length).round() : 0,
    };
  }
}
