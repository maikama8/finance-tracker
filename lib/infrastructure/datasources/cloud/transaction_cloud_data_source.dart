import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../../../domain/entities/transaction.dart' as domain;
import '../../../domain/value_objects/currency.dart';
import '../../../domain/value_objects/date_range.dart';

/// Cloud data source for Transaction entities using Firebase Firestore
class TransactionCloudDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'transactions';

  TransactionCloudDataSource(this._firestore);

  /// Get the transactions collection reference
  CollectionReference get _collection => _firestore.collection(_collectionName);

  /// Create a new transaction
  Future<domain.Transaction> create(domain.Transaction transaction) async {
    final data = _toFirestore(transaction);
    await _collection.doc(transaction.id).set(data);
    return transaction;
  }

  /// Update an existing transaction
  Future<domain.Transaction> update(domain.Transaction transaction) async {
    final data = _toFirestore(transaction);
    await _collection.doc(transaction.id).update(data);
    return transaction;
  }

  /// Delete a transaction by ID
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get a transaction by ID
  Future<domain.Transaction?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return _fromFirestore(doc);
  }

  /// Get all transactions for a user
  Future<List<domain.Transaction>> getAll({
    required String userId,
    DateRange? dateRange,
    String? categoryId,
    domain.TransactionType? type,
  }) async {
    Query query = _collection.where('userId', isEqualTo: userId);

    // Filter by date range if provided
    if (dateRange != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end));
    }

    // Filter by category if provided
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    // Filter by type if provided
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    // Order by date descending (newest first)
    query = query.orderBy('date', descending: true);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get transactions by date range
  Future<List<domain.Transaction>> getByDateRange({
    required String userId,
    required DateRange dateRange,
  }) async {
    return getAll(userId: userId, dateRange: dateRange);
  }

  /// Get transactions by category
  Future<List<domain.Transaction>> getByCategory({
    required String userId,
    required String categoryId,
  }) async {
    return getAll(userId: userId, categoryId: categoryId);
  }

  /// Get transactions by type (income or expense)
  Future<List<domain.Transaction>> getByType({
    required String userId,
    required domain.TransactionType type,
  }) async {
    return getAll(userId: userId, type: type);
  }

  /// Get all pending sync transactions
  Future<List<domain.Transaction>> getPendingSync(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('syncStatus', isEqualTo: domain.SyncStatus.pending.name)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get all transactions with conflicts
  Future<List<domain.Transaction>> getConflicts(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('syncStatus', isEqualTo: domain.SyncStatus.conflict.name)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Watch all transactions for a user (returns a stream)
  Stream<List<domain.Transaction>> watchAll({
    required String userId,
    DateRange? dateRange,
    String? categoryId,
    domain.TransactionType? type,
  }) {
    Query query = _collection.where('userId', isEqualTo: userId);

    // Filter by date range if provided
    if (dateRange != null) {
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end));
    }

    // Filter by category if provided
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    // Filter by type if provided
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    // Order by date descending (newest first)
    query = query.orderBy('date', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  /// Get count of transactions for a user
  Future<int> getCount(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Batch create multiple transactions
  Future<void> batchCreate(List<domain.Transaction> transactions) async {
    final batch = _firestore.batch();
    for (final transaction in transactions) {
      final docRef = _collection.doc(transaction.id);
      batch.set(docRef, _toFirestore(transaction));
    }
    await batch.commit();
  }

  /// Batch update multiple transactions
  Future<void> batchUpdate(List<domain.Transaction> transactions) async {
    final batch = _firestore.batch();
    for (final transaction in transactions) {
      final docRef = _collection.doc(transaction.id);
      batch.update(docRef, _toFirestore(transaction));
    }
    await batch.commit();
  }

  /// Batch delete multiple transactions
  Future<void> batchDelete(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      final docRef = _collection.doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  /// Convert Transaction entity to Firestore document
  Map<String, dynamic> _toFirestore(domain.Transaction transaction) {
    return {
      'id': transaction.id,
      'userId': transaction.userId,
      'amount': transaction.amount.toString(),
      'currency': {
        'code': transaction.currency.code,
        'symbol': transaction.currency.symbol,
        'name': transaction.currency.name,
        'decimalPlaces': transaction.currency.decimalPlaces,
      },
      'type': transaction.type.name,
      'categoryId': transaction.categoryId,
      'date': Timestamp.fromDate(transaction.date),
      'notes': transaction.notes,
      'receiptImageId': transaction.receiptImageId,
      'createdAt': Timestamp.fromDate(transaction.createdAt),
      'updatedAt': Timestamp.fromDate(transaction.updatedAt),
      'syncStatus': transaction.syncStatus.name,
    };
  }

  /// Convert Firestore document to Transaction entity
  domain.Transaction _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currencyData = data['currency'] as Map<String, dynamic>;

    return domain.Transaction(
      id: data['id'] as String,
      userId: data['userId'] as String,
      amount: Decimal.parse(data['amount'] as String),
      currency: Currency(
        code: currencyData['code'] as String,
        symbol: currencyData['symbol'] as String,
        name: currencyData['name'] as String,
        decimalPlaces: currencyData['decimalPlaces'] as int,
      ),
      type: domain.TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
      ),
      categoryId: data['categoryId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      receiptImageId: data['receiptImageId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      syncStatus: domain.SyncStatus.values.firstWhere(
        (e) => e.name == data['syncStatus'],
        orElse: () => domain.SyncStatus.synced,
      ),
    );
  }
}
