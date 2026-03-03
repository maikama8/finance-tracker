import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../../../domain/entities/budget.dart';
import '../../../domain/entities/transaction.dart' as domain;
import '../../../domain/value_objects/currency.dart';

/// Cloud data source for Budget entities using Firebase Firestore
class BudgetCloudDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'budgets';

  BudgetCloudDataSource(this._firestore);

  /// Get the budgets collection reference
  CollectionReference get _collection => _firestore.collection(_collectionName);

  /// Create a new budget
  Future<Budget> create(Budget budget) async {
    final data = _toFirestore(budget);
    await _collection.doc(budget.id).set(data);
    return budget;
  }

  /// Update an existing budget
  Future<Budget> update(Budget budget) async {
    final data = _toFirestore(budget);
    await _collection.doc(budget.id).update(data);
    return budget;
  }

  /// Delete a budget by ID
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get a budget by ID
  Future<Budget?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return _fromFirestore(doc);
  }

  /// Get all budgets for a user
  Future<List<Budget>> getAll({required String userId}) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get budgets for a specific month and year
  Future<List<Budget>> getByMonth({
    required String userId,
    required int month,
    required int year,
  }) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get budget for a specific category in a specific month
  Future<Budget?> getByCategoryAndMonth({
    required String userId,
    required String categoryId,
    required int month,
    required int year,
  }) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return _fromFirestore(snapshot.docs.first);
  }

  /// Get budgets for a specific category across all months
  Future<List<Budget>> getByCategory({
    required String userId,
    required String categoryId,
  }) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get budgets that are near or over limit
  Future<List<Budget>> getAlerting({required String userId}) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .get();

    // Filter budgets that are near or over limit
    return snapshot.docs
        .map((doc) => _fromFirestore(doc))
        .where((budget) => budget.isNearLimit || budget.isOverLimit)
        .toList();
  }

  /// Get current month's budgets
  Future<List<Budget>> getCurrentMonth({required String userId}) async {
    final now = DateTime.now();
    return getByMonth(
      userId: userId,
      month: now.month,
      year: now.year,
    );
  }

  /// Watch all budgets for a user (returns a stream)
  Stream<List<Budget>> watchAll({required String userId}) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('year', descending: true)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  /// Watch budgets for a specific month
  Stream<List<Budget>> watchByMonth({
    required String userId,
    required int month,
    required int year,
  }) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  /// Get count of budgets for a user
  Future<int> getCount(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Batch create multiple budgets
  Future<void> batchCreate(List<Budget> budgets) async {
    final batch = _firestore.batch();
    for (final budget in budgets) {
      final docRef = _collection.doc(budget.id);
      batch.set(docRef, _toFirestore(budget));
    }
    await batch.commit();
  }

  /// Batch update multiple budgets
  Future<void> batchUpdate(List<Budget> budgets) async {
    final batch = _firestore.batch();
    for (final budget in budgets) {
      final docRef = _collection.doc(budget.id);
      batch.update(docRef, _toFirestore(budget));
    }
    await batch.commit();
  }

  /// Batch delete multiple budgets
  Future<void> batchDelete(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      final docRef = _collection.doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  /// Reset budgets for a new month (set currentSpending to zero)
  Future<void> resetMonthlyBudgets({
    required String userId,
    required int month,
    required int year,
  }) async {
    final budgets = await getByMonth(
      userId: userId,
      month: month,
      year: year,
    );

    final batch = _firestore.batch();
    for (final budget in budgets) {
      final resetBudget = budget.copyWith(
        currentSpending: Decimal.zero,
        updatedAt: DateTime.now(),
      );
      final docRef = _collection.doc(budget.id);
      batch.update(docRef, _toFirestore(resetBudget));
    }
    await batch.commit();
  }

  /// Convert Budget entity to Firestore document
  Map<String, dynamic> _toFirestore(Budget budget) {
    return {
      'id': budget.id,
      'userId': budget.userId,
      'categoryId': budget.categoryId,
      'monthlyLimit': budget.monthlyLimit.toString(),
      'currency': {
        'code': budget.currency.code,
        'symbol': budget.currency.symbol,
        'name': budget.currency.name,
        'decimalPlaces': budget.currency.decimalPlaces,
      },
      'currentSpending': budget.currentSpending.toString(),
      'month': budget.month,
      'year': budget.year,
      'createdAt': Timestamp.fromDate(budget.createdAt),
      'updatedAt': Timestamp.fromDate(budget.updatedAt),
      'syncStatus': budget.syncStatus.name,
    };
  }

  /// Convert Firestore document to Budget entity
  Budget _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currencyData = data['currency'] as Map<String, dynamic>;

    return Budget(
      id: data['id'] as String,
      userId: data['userId'] as String,
      categoryId: data['categoryId'] as String,
      monthlyLimit: Decimal.parse(data['monthlyLimit'] as String),
      currency: Currency(
        code: currencyData['code'] as String,
        symbol: currencyData['symbol'] as String,
        name: currencyData['name'] as String,
        decimalPlaces: currencyData['decimalPlaces'] as int,
      ),
      currentSpending: Decimal.parse(data['currentSpending'] as String),
      month: data['month'] as int,
      year: data['year'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      syncStatus: domain.SyncStatus.values.firstWhere(
        (e) => e.name == data['syncStatus'],
        orElse: () => domain.SyncStatus.synced,
      ),
    );
  }
}
