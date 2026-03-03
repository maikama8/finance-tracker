import 'package:flutter/material.dart';
import '../entities/category.dart';

/// Input data for creating or updating a category
class CategoryInput {
  final String name;
  final String icon;
  final String color;
  final String? parentCategoryId;

  const CategoryInput({
    required this.name,
    required this.icon,
    required this.color,
    this.parentCategoryId,
  });
}

/// Represents a category hierarchy with parent and children
class CategoryHierarchy {
  final Map<Category, List<Category>> hierarchy;

  const CategoryHierarchy(this.hierarchy);

  /// Get all root categories (categories without parent)
  List<Category> get rootCategories => hierarchy.keys.toList();

  /// Get children of a specific category
  List<Category> getChildren(Category parent) {
    return hierarchy[parent] ?? [];
  }

  /// Get all categories as a flat list
  List<Category> get allCategories {
    final List<Category> all = [];
    for (final entry in hierarchy.entries) {
      all.add(entry.key);
      all.addAll(entry.value);
    }
    return all;
  }
}

/// Service interface for Category operations
abstract class CategoryService {
  /// Get default categories for a specific locale
  /// Returns locale-appropriate category templates
  Future<List<Category>> getDefaultCategories(Locale locale);

  /// Create a custom category for a user
  Future<Category> createCustomCategory(String userId, CategoryInput input);

  /// Update an existing category
  Future<Category> updateCategory(String id, CategoryInput input);

  /// Delete a category and reassign its transactions to another category
  /// Throws an exception if reassignToCategoryId is invalid
  Future<void> deleteCategory(String id, String reassignToCategoryId);

  /// Get all categories for a user (includes default and custom categories)
  Future<List<Category>> getAllCategories(String userId);

  /// Get the category hierarchy (parent-child relationships)
  Future<CategoryHierarchy> getCategoryTree(String userId);

  /// Get a category by ID
  Future<Category?> getCategoryById(String id);

  /// Check if a category has any transactions
  Future<bool> hasTransactions(String categoryId);

  /// Get child categories of a parent
  Future<List<Category>> getChildCategories(String parentCategoryId, String userId);
}
