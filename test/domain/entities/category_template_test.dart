import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/domain/entities/category_template.dart';
import 'package:personal_finance_tracker/domain/entities/regional_category_templates.dart';

void main() {
  group('CategoryDefinition', () {
    test('should create a category definition with name, icon, and color', () {
      const definition = CategoryDefinition('Transport', '🚗', Colors.blue);

      expect(definition.name, 'Transport');
      expect(definition.icon, '🚗');
      expect(definition.color, Colors.blue);
    });

    test('should support equality comparison', () {
      const definition1 = CategoryDefinition('Transport', '🚗', Colors.blue);
      const definition2 = CategoryDefinition('Transport', '🚗', Colors.blue);
      const definition3 = CategoryDefinition('Food', '🍔', Colors.red);

      expect(definition1, equals(definition2));
      expect(definition1, isNot(equals(definition3)));
    });
  });

  group('CategoryTemplate', () {
    test('should create a template with locale and categories', () {
      const template = CategoryTemplate(
        locale: Locale('en', 'US'),
        categories: [
          CategoryDefinition('Transport', '🚗', Colors.blue),
          CategoryDefinition('Food', '🍔', Colors.red),
        ],
      );

      expect(template.locale, const Locale('en', 'US'));
      expect(template.categories.length, 2);
      expect(template.localeString, 'en_US');
    });

    test('should generate correct locale string', () {
      const template = CategoryTemplate(
        locale: Locale('en', 'NG'),
        categories: [],
      );

      expect(template.localeString, 'en_NG');
    });
  });

  group('RegionalCategoryTemplates', () {
    test('should provide template for Nigeria (en_NG)', () {
      final template = RegionalCategoryTemplates.getTemplate(
        const Locale('en', 'NG'),
      );

      expect(template, isNotNull);
      expect(template!.locale, const Locale('en', 'NG'));
      expect(template.categories, isNotEmpty);
      
      // Check for specific Nigerian categories
      final categoryNames = template.categories.map((c) => c.name).toList();
      expect(categoryNames, contains('Okada'));
      expect(categoryNames, contains('Data Bundle'));
      expect(categoryNames, contains('Suya'));
      expect(categoryNames, contains('Generator Fuel'));
    });

    test('should provide template for US (en_US)', () {
      final template = RegionalCategoryTemplates.getTemplate(
        const Locale('en', 'US'),
      );

      expect(template, isNotNull);
      expect(template!.locale, const Locale('en', 'US'));
      
      final categoryNames = template.categories.map((c) => c.name).toList();
      expect(categoryNames, contains('Subway'));
      expect(categoryNames, contains('Coffee Shops'));
      expect(categoryNames, contains('Streaming'));
    });

    test('should provide template for UK/Europe (en_GB)', () {
      final template = RegionalCategoryTemplates.getTemplate(
        const Locale('en', 'GB'),
      );

      expect(template, isNotNull);
      expect(template!.locale, const Locale('en', 'GB'));
      
      final categoryNames = template.categories.map((c) => c.name).toList();
      expect(categoryNames, contains('Public Transport'));
      expect(categoryNames, contains('Bakery'));
    });

    test('should provide template for India (en_IN)', () {
      final template = RegionalCategoryTemplates.getTemplate(
        const Locale('en', 'IN'),
      );

      expect(template, isNotNull);
      expect(template!.locale, const Locale('en', 'IN'));
      
      final categoryNames = template.categories.map((c) => c.name).toList();
      expect(categoryNames, contains('Auto Rickshaw'));
      expect(categoryNames, contains('Mobile Recharge'));
    });

    test('should return null for unsupported locale', () {
      final template = RegionalCategoryTemplates.getTemplate(
        const Locale('es', 'ES'),
      );

      expect(template, isNull);
    });

    test('should get template by locale string', () {
      final template = RegionalCategoryTemplates.getTemplateByString('en_NG');

      expect(template, isNotNull);
      expect(template!.localeString, 'en_NG');
    });

    test('should list all available locales', () {
      final locales = RegionalCategoryTemplates.getAvailableLocales();

      expect(locales, isNotEmpty);
      expect(locales, contains('en_NG'));
      expect(locales, contains('en_US'));
      expect(locales, contains('en_GB'));
      expect(locales, contains('en_IN'));
    });

    test('should check if template exists for locale', () {
      expect(
        RegionalCategoryTemplates.hasTemplate(const Locale('en', 'NG')),
        isTrue,
      );
      expect(
        RegionalCategoryTemplates.hasTemplate(const Locale('es', 'ES')),
        isFalse,
      );
    });

    test('should provide fallback template', () {
      final fallback = RegionalCategoryTemplates.getFallbackTemplate();

      expect(fallback, isNotNull);
      expect(fallback.localeString, 'en_US');
    });

    test('should get template with fallback for unsupported locale', () {
      final template = RegionalCategoryTemplates.getTemplateOrFallback(
        const Locale('es', 'ES'),
      );

      expect(template, isNotNull);
      expect(template.localeString, 'en_US'); // Should return fallback
    });

    test('should get correct template when supported', () {
      final template = RegionalCategoryTemplates.getTemplateOrFallback(
        const Locale('en', 'NG'),
      );

      expect(template, isNotNull);
      expect(template.localeString, 'en_NG'); // Should return Nigerian template
    });

    test('all templates should have non-empty categories', () {
      final allLocales = RegionalCategoryTemplates.getAvailableLocales();

      for (final localeString in allLocales) {
        final template = RegionalCategoryTemplates.getTemplateByString(localeString);
        expect(template, isNotNull, reason: 'Template for $localeString should exist');
        expect(template!.categories, isNotEmpty, 
          reason: 'Template for $localeString should have categories');
      }
    });

    test('all category definitions should have valid properties', () {
      final allLocales = RegionalCategoryTemplates.getAvailableLocales();

      for (final localeString in allLocales) {
        final template = RegionalCategoryTemplates.getTemplateByString(localeString)!;
        
        for (final category in template.categories) {
          expect(category.name, isNotEmpty, 
            reason: 'Category in $localeString should have a name');
          expect(category.icon, isNotEmpty, 
            reason: 'Category in $localeString should have an icon');
          // Color is always valid as it's a Color object
        }
      }
    });
  });
}
