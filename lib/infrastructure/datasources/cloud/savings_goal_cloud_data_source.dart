import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../../../domain/entities/savings_goal.dart';
import '../../../domain/entities/transaction.dart' as domain;
import '../../../domain/value_objects/currency.dart';

/// Cloud data source for SavingsGoal entities using Firebase Firestore
class SavingsGoalCloudDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'savings_goals';

  SavingsGoalCloudDataSource(this._firestore);

  /// Get the savings goals collection reference
  CollectionReference get _collection => _firestore.collection(_collectionName);

  /// Create a new savings goal
  Future<SavingsGoal> create(SavingsGoal goal) async {
    final data = _toFirestore(goal);
    await _collection.doc(goal.id).set(data);
    return goal;
  }

  /// Update an existing savings goal
  Future<SavingsGoal> update(SavingsGoal goal) async {
    final data = _toFirestore(goal);
    await _collection.doc(goal.id).update(data);
    return goal;
  }

  /// Delete a savings goal by ID
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get a savings goal by ID
  Future<SavingsGoal?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return _fromFirestore(doc);
  }

  /// Get all savings goals for a user
  Future<List<SavingsGoal>> getAll({required String userId}) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('deadline', descending: false)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get active savings goals (not completed and not overdue)
  Future<List<SavingsGoal>> getActive({required String userId}) async {
    final now = Timestamp.fromDate(DateTime.now());
    
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('deadline', isGreaterThanOrEqualTo: now)
        .orderBy('deadline', descending: false)
        .get();

    // Filter out completed goals
    return snapshot.docs
        .map((doc) => _fromFirestore(doc))
        .where((goal) => !goal.isCompleted)
        .toList();
  }

  /// Get completed savings goals
  Future<List<SavingsGoal>> getCompleted({required String userId}) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    // Filter completed goals
    return snapshot.docs
        .map((doc) => _fromFirestore(doc))
        .where((goal) => goal.isCompleted)
        .toList();
  }

  /// Get overdue savings goals
  Future<List<SavingsGoal>> getOverdue({required String userId}) async {
    final now = Timestamp.fromDate(DateTime.now());
    
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('deadline', isLessThan: now)
        .orderBy('deadline', descending: true)
        .get();

    // Filter out completed goals
    return snapshot.docs
        .map((doc) => _fromFirestore(doc))
        .where((goal) => !goal.isCompleted)
        .toList();
  }

  /// Get goals with reminders enabled
  Future<List<SavingsGoal>> getWithReminders({required String userId}) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('reminderEnabled', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Watch a specific savings goal (returns a stream)
  Stream<SavingsGoal?> watchGoal(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return _fromFirestore(doc);
    });
  }

  /// Watch all savings goals for a user (returns a stream)
  Stream<List<SavingsGoal>> watchAll({required String userId}) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
    });
  }

  /// Get count of savings goals for a user
  Future<int> getCount(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Batch create multiple savings goals
  Future<void> batchCreate(List<SavingsGoal> goals) async {
    final batch = _firestore.batch();
    for (final goal in goals) {
      final docRef = _collection.doc(goal.id);
      batch.set(docRef, _toFirestore(goal));
    }
    await batch.commit();
  }

  /// Batch update multiple savings goals
  Future<void> batchUpdate(List<SavingsGoal> goals) async {
    final batch = _firestore.batch();
    for (final goal in goals) {
      final docRef = _collection.doc(goal.id);
      batch.update(docRef, _toFirestore(goal));
    }
    await batch.commit();
  }

  /// Batch delete multiple savings goals
  Future<void> batchDelete(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      final docRef = _collection.doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  /// Convert SavingsGoal entity to Firestore document
  Map<String, dynamic> _toFirestore(SavingsGoal goal) {
    return {
      'id': goal.id,
      'userId': goal.userId,
      'name': goal.name,
      'targetAmount': goal.targetAmount.toString(),
      'currency': {
        'code': goal.currency.code,
        'symbol': goal.currency.symbol,
        'name': goal.currency.name,
        'decimalPlaces': goal.currency.decimalPlaces,
      },
      'currentAmount': goal.currentAmount.toString(),
      'deadline': Timestamp.fromDate(goal.deadline),
      'reminderEnabled': goal.reminderEnabled,
      'reminderFrequency': goal.reminderFrequency?.name,
      'lastReminderSent': goal.lastReminderSent != null
          ? Timestamp.fromDate(goal.lastReminderSent!)
          : null,
      'createdAt': Timestamp.fromDate(goal.createdAt),
      'updatedAt': Timestamp.fromDate(goal.updatedAt),
      'syncStatus': goal.syncStatus.name,
    };
  }

  /// Convert Firestore document to SavingsGoal entity
  SavingsGoal _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currencyData = data['currency'] as Map<String, dynamic>;

    return SavingsGoal(
      id: data['id'] as String,
      userId: data['userId'] as String,
      name: data['name'] as String,
      targetAmount: Decimal.parse(data['targetAmount'] as String),
      currency: Currency(
        code: currencyData['code'] as String,
        symbol: currencyData['symbol'] as String,
        name: currencyData['name'] as String,
        decimalPlaces: currencyData['decimalPlaces'] as int,
      ),
      currentAmount: Decimal.parse(data['currentAmount'] as String),
      deadline: (data['deadline'] as Timestamp).toDate(),
      reminderEnabled: data['reminderEnabled'] as bool? ?? false,
      reminderFrequency: data['reminderFrequency'] != null
          ? ReminderFrequency.values.firstWhere(
              (e) => e.name == data['reminderFrequency'],
            )
          : null,
      lastReminderSent: data['lastReminderSent'] != null
          ? (data['lastReminderSent'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      syncStatus: domain.SyncStatus.values.firstWhere(
        (e) => e.name == data['syncStatus'],
        orElse: () => domain.SyncStatus.synced,
      ),
    );
  }
}
