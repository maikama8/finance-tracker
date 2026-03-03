import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_template.dart';
import '../../domain/entities/regional_category_templates.dart';
import '../../domain/services/category_service.dart';
import '../data_sources/local/category_local_data_source.dart';
import '../data_sources/local/transaction_local_data_source.dart';

/// Implementation of CategoryService using local data sources
class CategoryServiceImpl implements CategoryService {
  final CategoryLocalDataSource _categoryDataSource;
  final TransactionLocalDataSource _transactionDataSource;
  final Uuid _uuid = const Uuid();

  CategoryServiceImpl(
    this._categoryDataSource,
    this._transactionDataSource,
  );

  @override
  Future<List<Category>> getDefaultCategories(Locale locale) async {
    // Check if default categories for this locale already exist in storage
    final existingDefaults = await _categoryDataSource.getDefaultCategories(
      locale: '${locale.languageCode}_${locale.countryCode}',
    );

    if (existingDefaults.isNotEmpty) {
      return existingDefaults;
    }

    // Get template for the locale (with fallback)
    final template = RegionalCategoryTemplates.getTemplateOrFallback(locale);
    final localeString = template.localeString;

    // Convert template definitions to Category entities
    final now = DateTime.now();
    final categories = template.categories.map((def) {
      return Category(
        id: _uuid.v4(),
        userId: null, // null for default categories
        name: def.name,
        icon: def.icon,
        color: _colorToHex(def.color),
        parentCategoryId: null,
        isDefault: true,
        locale: localeString,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    // Store the default categories
    await _categoryDataSource.batchCreate(categories);

    return categories;
  }

  @override
  Future<Category> createCustomCategory(
    String userId,
    CategoryInput input,
  ) async {
    // Validate parent category if provided
    if (input.parentCategoryId != null) {
      final parent = await _categoryDataSource.getById(input.parentCategoryId!);
      if (parent == null) {
        throw Exception('Parent category not found: ${input.parentCategoryId}');
      }
    }

    final now = DateTime.now();
    final category = Category(
      id: _uuid.v4(),
      userId: userId,
      name: input.name,
      icon: input.icon,
      color: input.color,
      parentCategoryId: input.parentCategoryId,
      isDefault: false,
      locale: null,
      createdAt: now,
      updatedAt: now,
    );

    return await _categoryDataSource.create(category);
  }

  @override
  Future<Category> updateCategory(String id, CategoryInput input) async {
    final existing = await _categoryDataSource.getById(id);
    if (existing == null) {
      throw Exception('Category not found: $id');
    }

    // Validate parent category if provided
    if (input.parentCategoryId != null) {
      // Check for circular reference
      final hasCircular = await _categoryDataSource.hasCircularReference(
        id,
        input.parentCategoryId,
      );
      if (hasCircular) {
        throw Exception(
          'Cannot set parent category: would create circular reference',
        );
      }

      // Verify parent exists
      final parent = await _categoryDataSource.getById(input.parentCategoryId!);
      if (parent == null) {
        throw Exception('Parent category not found: ${input.parentCategoryId}');
      }
    }

    final updated = existing.copyWith(
      name: input.name,
      icon: input.icon,
      color: input.color,
      parentCategoryId: input.parentCategoryId,
      updatedAt: DateTime.now(),
    );

    return await _categoryDataSource.update(updated);
  }

  @override
  Future<void> deleteCategory(String id, String reassignToCategoryId) async {
    // Verify the category exists
    final category = await _categoryDataSource.getById(id);
    if (category == null) {
      throw Exception('Category not found: $id');
    }

    // Verify the reassignment category exists
    final reassignCategory = await _categoryDataSource.getById(
      reassignToCategoryId,
    );
    if (reassignCategory == null) {
      throw Exception('Reassignment category not found: $reassignToCategoryId');
    }

    // Cannot reassign to the same category being deleted
    if (id == reassignToCategoryId) {
      throw Exception('Cannot reassign to the category being deleted');
    }

    // Get all transactions with this category
    final transactions = await _transactionDataSource.getByCategory(
      userId: category.userId ?? '',
      categoryId: id,
    );

    // Reassign all transactions to the new category
    if (transactions.isNotEmpty) {
      final updatedTransactions = transactions.map((t) {
        return t.copyWith(
          categoryId: reassignToCategoryId,
          updatedAt: DateTime.now(),
        );
      }).toList();

      await _transactionDataSource.batchUpdate(updatedTransactions);
    }

    // Handle child categories - reassign them to the parent of the deleted category
    // or make them root categories if the deleted category was a root
    final children = await _categoryDataSource.getChildCategories(
      parentCategoryId: id,
      userId: category.userId,
    );

    if (children.isNotEmpty) {
      final updatedChildren = children.map((child) {
        return child.copyWith(
          parentCategoryId: category.parentCategoryId, // Inherit parent's parent
          updatedAt: DateTime.now(),
        );
      }).toList();

      await _categoryDataSource.batchUpdate(updatedChildren);
    }

    // Delete the category
    await _categoryDataSource.delete(id);
  }

  @override
  Future<List<Category>> getAllCategories(String userId) async {
    return await _categoryDataSource.getAll(userId: userId);
  }

  @override
  Future<CategoryHierarchy> getCategoryTree(String userId) async {
    final hierarchy = await _categoryDataSource.getCategoryHierarchy(
      userId: userId,
    );
    return CategoryHierarchy(hierarchy);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    return await _categoryDataSource.getById(id);
  }

  @override
  Future<bool> hasTransactions(String categoryId) async {
    // Get the category to find the userId
    final category = await _categoryDataSource.getById(categoryId);
    if (category == null) {
      return false;
    }

    final transactions = await _transactionDataSource.getByCategory(
      userId: category.userId ?? '',
      categoryId: categoryId,
    );

    return transactions.isNotEmpty;
  }

  @override
  Future<List<Category>> getChildCategories(
    String parentCategoryId,
    String userId,
  ) async {
    return await _categoryDataSource.getChildCategories(
      parentCategoryId: parentCategoryId,
      userId: userId,
    );
  }

  /// Convert Flutter Color to hex string
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
