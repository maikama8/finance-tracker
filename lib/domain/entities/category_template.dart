import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Definition of a category for use in templates
/// This is a lightweight representation used to create Category instances
class CategoryDefinition extends Equatable {
  final String name;
  final String icon; // Icon name or emoji
  final Color color;

  const CategoryDefinition(
    this.name,
    this.icon,
    this.color,
  );

  @override
  List<Object?> get props => [name, icon, color];

  @override
  String toString() {
    return 'CategoryDefinition(name: $name, icon: $icon)';
  }
}

/// Template containing regional category suggestions
/// Each template is associated with a specific locale and provides
/// culturally relevant default categories
class CategoryTemplate extends Equatable {
  final Locale locale;
  final List<CategoryDefinition> categories;
  final String name;
  final String description;
  final String flag;

  const CategoryTemplate({
    required this.locale,
    required this.categories,
    required this.name,
    required this.description,
    required this.flag,
  });

  /// Get the locale string representation (e.g., "en_NG", "en_US")
  String get localeString => '${locale.languageCode}_${locale.countryCode}';

  @override
  List<Object?> get props => [locale, categories, name, description, flag];

  @override
  String toString() {
    return 'CategoryTemplate(locale: $localeString, name: $name, categories: ${categories.length})';
  }
}
