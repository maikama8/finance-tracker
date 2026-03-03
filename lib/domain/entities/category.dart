import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Entity representing a transaction category
class Category extends Equatable {
  final String id;
  final String? userId; // null for default categories
  final String name;
  final String icon; // Icon name or emoji
  final String color; // Hex color code
  final String? parentCategoryId; // For category hierarchies
  final bool isDefault; // Whether this is a system-provided category
  final String? locale; // Locale code for regional defaults (e.g., "en_NG")
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.color,
    this.parentCategoryId,
    this.isDefault = false,
    this.locale,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this category with updated fields
  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    String? parentCategoryId,
    bool? isDefault,
    String? locale,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      isDefault: isDefault ?? this.isDefault,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the color as a Flutter Color object
  Color get colorValue {
    try {
      // Remove '#' if present and parse hex color
      final hexColor = color.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      // Default to grey if color parsing fails
      return Colors.grey;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        icon,
        color,
        parentCategoryId,
        isDefault,
        locale,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, isDefault: $isDefault)';
  }
}
