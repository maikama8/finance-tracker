import 'package:hive/hive.dart';
import '../../../domain/entities/category.dart';
import 'hive_database.dart';

/// Local data source for Category entities using Hive
class CategoryLocalDataSource {
  final HiveDatabase _database;

  CategoryLocalDataSource(this._database);

  /// Get the categories box
  Box _getBox() => _database.getBox(HiveBoxNames.categories);

  /// Create a new category
  Future<Category> create(Category category) async {
    final box = _getBox();
    await box.put(category.id, category);
    return category;
  }

  /// Update an existing category
  Future<Category> update(Category category) async {
    final box = _getBox();
    if (!box.containsKey(category.id)) {
      throw Exception('Category not found: ${category.id}');
    }
    await box.put(category.id, category);
    return category;
  }

  /// Delete a category by ID
  Future<void> delete(String id) async {
    final box = _getBox();
    await box.delete(id);
  }

  /// Get a category by ID
  Future<Category?> getById(String id) async {
    final box = _getBox();
    return box.get(id) as Category?;
  }

  /// Get all categories for a user (includes default categories)
  Future<List<Category>> getAll({String? userId}) async {
    final box = _getBox();
    final allCategories = box.values.cast<Category>();

    if (userId == null) {
      // Return only default categories
      return allCategories.where((c) => c.isDefault).toList();
    }

    // Return user's custom categories and default categories
    return allCategories
        .where((c) => c.isDefault || c.userId == userId)
        .toList();
  }

  /// Get only default categories
  Future<List<Category>> getDefaultCategories({String? locale}) async {
    final box = _getBox();
    final allCategories = box.values.cast<Category>();

    var defaults = allCategories.where((c) => c.isDefault);

    // Filter by locale if provided
    if (locale != null) {
      defaults = defaults.where((c) => c.locale == locale || c.locale == null);
    }

    return defaults.toList();
  }

  /// Get only custom categories for a user
  Future<List<Category>> getCustomCategories(String userId) async {
    final box = _getBox();
    final allCategories = box.values.cast<Category>();

    return allCategories
        .where((c) => !c.isDefault && c.userId == userId)
        .toList();
  }

  /// Get root categories (categories without parent)
  Future<List<Category>> getRootCategories({String? userId}) async {
    final allCategories = await getAll(userId: userId);
    return allCategories.where((c) => c.parentCategoryId == null).toList();
  }

  /// Get child categories of a parent category
  Future<List<Category>> getChildCategories({
    required String parentCategoryId,
    String? userId,
  }) async {
    final allCategories = await getAll(userId: userId);
    return allCategories
        .where((c) => c.parentCategoryId == parentCategoryId)
        .toList();
  }

  /// Get category hierarchy (parent with all its children)
  Future<Map<Category, List<Category>>> getCategoryHierarchy({
    String? userId,
  }) async {
    final allCategories = await getAll(userId: userId);
    final Map<Category, List<Category>> hierarchy = {};

    // Get all root categories
    final rootCategories =
        allCategories.where((c) => c.parentCategoryId == null);

    for (final root in rootCategories) {
      final children =
          allCategories.where((c) => c.parentCategoryId == root.id).toList();
      hierarchy[root] = children;
    }

    return hierarchy;
  }

  /// Check if a category has children
  Future<bool> hasChildren(String categoryId, {String? userId}) async {
    final children = await getChildCategories(
      parentCategoryId: categoryId,
      userId: userId,
    );
    return children.isNotEmpty;
  }

  /// Get all ancestor categories (parent, grandparent, etc.)
  Future<List<Category>> getAncestors(String categoryId) async {
    final List<Category> ancestors = [];
    Category? current = await getById(categoryId);

    while (current != null && current.parentCategoryId != null) {
      final parent = await getById(current.parentCategoryId!);
      if (parent != null) {
        ancestors.add(parent);
        current = parent;
      } else {
        break;
      }
    }

    return ancestors;
  }

  /// Check if there's a circular reference in category hierarchy
  Future<bool> hasCircularReference(String categoryId, String? parentId) async {
    if (parentId == null) return false;
    if (categoryId == parentId) return true;

    final ancestors = await getAncestors(parentId);
    return ancestors.any((ancestor) => ancestor.id == categoryId);
  }

  /// Watch all categories for a user (returns a stream)
  Stream<List<Category>> watchAll({String? userId}) {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getAll(userId: userId);
    });
  }

  /// Get count of categories for a user
  Future<int> getCount({String? userId}) async {
    final categories = await getAll(userId: userId);
    return categories.length;
  }

  /// Clear all custom categories for a user (keeps default categories)
  Future<void> clearCustomCategories(String userId) async {
    final box = _getBox();
    final allCategories = box.values.cast<Category>();
    final customCategoryIds = allCategories
        .where((c) => !c.isDefault && c.userId == userId)
        .map((c) => c.id)
        .toList();

    for (final id in customCategoryIds) {
      await box.delete(id);
    }
  }

  /// Batch create multiple categories
  Future<void> batchCreate(List<Category> categories) async {
    final box = _getBox();
    final Map<String, Category> entries = {
      for (var c in categories) c.id: c
    };
    await box.putAll(entries);
  }

  /// Batch update multiple categories
  Future<void> batchUpdate(List<Category> categories) async {
    await batchCreate(categories); // Same implementation as create
  }

  /// Batch delete multiple categories
  Future<void> batchDelete(List<String> ids) async {
    final box = _getBox();
    await box.deleteAll(ids);
  }
}
