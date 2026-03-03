import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/category.dart';

/// Cloud data source for Category entities using Firebase Firestore
class CategoryCloudDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'categories';

  CategoryCloudDataSource(this._firestore);

  /// Get the categories collection reference
  CollectionReference get _collection => _firestore.collection(_collectionName);

  /// Create a new category
  Future<Category> create(Category category) async {
    final data = _toFirestore(category);
    await _collection.doc(category.id).set(data);
    return category;
  }

  /// Update an existing category
  Future<Category> update(Category category) async {
    final data = _toFirestore(category);
    await _collection.doc(category.id).update(data);
    return category;
  }

  /// Delete a category by ID
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  /// Get a category by ID
  Future<Category?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) {
      return null;
    }
    return _fromFirestore(doc);
  }

  /// Get all categories for a user (including default categories)
  Future<List<Category>> getAll({String? userId}) async {
    Query query = _collection;

    if (userId != null) {
      // Get user's custom categories and default categories
      query = _collection.where(
        Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('isDefault', isEqualTo: true),
        ),
      );
    } else {
      // Get only default categories
      query = _collection.where('isDefault', isEqualTo: true);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get default categories for a specific locale
  Future<List<Category>> getDefaultCategories({String? locale}) async {
    Query query = _collection.where('isDefault', isEqualTo: true);

    if (locale != null) {
      query = query.where('locale', isEqualTo: locale);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get custom categories for a user
  Future<List<Category>> getCustomCategories(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get child categories for a parent category
  Future<List<Category>> getChildCategories(String parentCategoryId) async {
    final snapshot = await _collection
        .where('parentCategoryId', isEqualTo: parentCategoryId)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get root categories (categories without a parent)
  Future<List<Category>> getRootCategories({String? userId}) async {
    Query query = _collection.where('parentCategoryId', isNull: true);

    if (userId != null) {
      query = _collection.where(
        Filter.and(
          Filter('parentCategoryId', isNull: true),
          Filter.or(
            Filter('userId', isEqualTo: userId),
            Filter('isDefault', isEqualTo: true),
          ),
        ),
      );
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Batch create multiple categories
  Future<void> batchCreate(List<Category> categories) async {
    final batch = _firestore.batch();
    for (final category in categories) {
      final docRef = _collection.doc(category.id);
      batch.set(docRef, _toFirestore(category));
    }
    await batch.commit();
  }

  /// Batch update multiple categories
  Future<void> batchUpdate(List<Category> categories) async {
    final batch = _firestore.batch();
    for (final category in categories) {
      final docRef = _collection.doc(category.id);
      batch.update(docRef, _toFirestore(category));
    }
    await batch.commit();
  }

  /// Batch delete multiple categories
  Future<void> batchDelete(List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      final docRef = _collection.doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  /// Convert Category entity to Firestore document
  Map<String, dynamic> _toFirestore(Category category) {
    return {
      'id': category.id,
      'userId': category.userId,
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
      'parentCategoryId': category.parentCategoryId,
      'isDefault': category.isDefault,
      'locale': category.locale,
      'createdAt': Timestamp.fromDate(category.createdAt),
      'updatedAt': Timestamp.fromDate(category.updatedAt),
    };
  }

  /// Convert Firestore document to Category entity
  Category _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Category(
      id: data['id'] as String,
      userId: data['userId'] as String?,
      name: data['name'] as String,
      icon: data['icon'] as String,
      color: data['color'] as String,
      parentCategoryId: data['parentCategoryId'] as String?,
      isDefault: data['isDefault'] as bool? ?? false,
      locale: data['locale'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
