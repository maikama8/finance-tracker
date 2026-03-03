import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:personal_finance_tracker/domain/entities/category.dart';
import 'package:personal_finance_tracker/domain/entities/transaction.dart';
import 'package:personal_finance_tracker/domain/services/category_service.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/category_local_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/transaction_local_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/services/category_service_impl.dart';

import 'category_service_test.mocks.dart';

@GenerateMocks([CategoryLocalDataSource, TransactionLocalDataSource])
void main() {
  late CategoryServiceImpl categoryService;
  late MockCategoryLocalDataSource mockCategoryDataSource;
  late MockTransactionLocalDataSource mockTransactionDataSource;

  setUp(() {
    mockCategoryDataSource = MockCategoryLocalDataSource();
    mockTransactionDataSource = MockTransactionLocalDataSource();
    categoryService = CategoryServiceImpl(
      mockCategoryDataSource,
      mockTransactionDataSource,
    );
  });

  group('CategoryService', () {
    group('getDefaultCategories', () {
      test('should return existing default categories if already stored',
          () async {
        // Arrange
        final locale = const Locale('en', 'US');
        final existingCategories = [
          Category(
            id: '1',
            userId: null,
            name: 'Subway',
            icon: '🚇',
            color: '#2196F3',
            isDefault: true,
            locale: 'en_US',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockCategoryDataSource.getDefaultCategories(locale: 'en_US'))
            .thenAnswer((_) async => existingCategories);

        // Act
        final result = await categoryService.getDefaultCategories(locale);

        // Assert
        expect(result, equals(existingCategories));
        verify(mockCategoryDataSource.getDefaultCategories(locale: 'en_US'))
            .called(1);
        verifyNever(mockCategoryDataSource.batchCreate(any));
      });

      test('should create and store default categories from template', () async {
        // Arrange
        final locale = const Locale('en', 'US');

        when(mockCategoryDataSource.getDefaultCategories(locale: 'en_US'))
            .thenAnswer((_) async => []);
        when(mockCategoryDataSource.batchCreate(any)).thenAnswer((_) async {});

        // Act
        final result = await categoryService.getDefaultCategories(locale);

        // Assert
        expect(result, isNotEmpty);
        expect(result.every((c) => c.isDefault), isTrue);
        expect(result.every((c) => c.locale == 'en_US'), isTrue);
        verify(mockCategoryDataSource.batchCreate(any)).called(1);
      });

      test('should use fallback template for unsupported locale', () async {
        // Arrange
        final locale = const Locale('xx', 'XX'); // Unsupported locale

        when(mockCategoryDataSource.getDefaultCategories(locale: 'xx_XX'))
            .thenAnswer((_) async => []);
        when(mockCategoryDataSource.batchCreate(any)).thenAnswer((_) async {});

        // Act
        final result = await categoryService.getDefaultCategories(locale);

        // Assert - Should use US template as fallback
        expect(result, isNotEmpty);
        expect(result.every((c) => c.isDefault), isTrue);
        expect(result.every((c) => c.locale == 'en_US'), isTrue);
      });
    });

    group('createCustomCategory', () {
      test('should create a custom category successfully', () async {
        // Arrange
        const userId = 'user123';
        final input = CategoryInput(
          name: 'Custom Category',
          icon: '🎯',
          color: '#FF5722',
          parentCategoryId: null,
        );

        when(mockCategoryDataSource.create(any))
            .thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Category;
        });

        // Act
        final result = await categoryService.createCustomCategory(userId, input);

        // Assert
        expect(result.name, equals('Custom Category'));
        expect(result.icon, equals('🎯'));
        expect(result.color, equals('#FF5722'));
        expect(result.userId, equals(userId));
        expect(result.isDefault, isFalse);
        verify(mockCategoryDataSource.create(any)).called(1);
      });

      test('should throw exception when parent category does not exist',
          () async {
        // Arrange
        const userId = 'user123';
        final input = CategoryInput(
          name: 'Child Category',
          icon: '🎯',
          color: '#FF5722',
          parentCategoryId: 'nonexistent',
        );

        when(mockCategoryDataSource.getById('nonexistent'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => categoryService.createCustomCategory(userId, input),
          throwsException,
        );
      });
    });

    group('updateCategory', () {
      test('should update category successfully', () async {
        // Arrange
        final existingCategory = Category(
          id: 'cat1',
          userId: 'user123',
          name: 'Old Name',
          icon: '🎯',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final input = CategoryInput(
          name: 'New Name',
          icon: '🎨',
          color: '#4CAF50',
          parentCategoryId: null,
        );

        when(mockCategoryDataSource.getById('cat1'))
            .thenAnswer((_) async => existingCategory);
        when(mockCategoryDataSource.update(any))
            .thenAnswer((invocation) async {
          return invocation.positionalArguments[0] as Category;
        });

        // Act
        final result = await categoryService.updateCategory('cat1', input);

        // Assert
        expect(result.name, equals('New Name'));
        expect(result.icon, equals('🎨'));
        expect(result.color, equals('#4CAF50'));
        verify(mockCategoryDataSource.update(any)).called(1);
      });

      test('should throw exception when category not found', () async {
        // Arrange
        final input = CategoryInput(
          name: 'New Name',
          icon: '🎨',
          color: '#4CAF50',
        );

        when(mockCategoryDataSource.getById('nonexistent'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => categoryService.updateCategory('nonexistent', input),
          throwsException,
        );
      });

      test('should throw exception when circular reference detected', () async {
        // Arrange
        final existingCategory = Category(
          id: 'cat1',
          userId: 'user123',
          name: 'Category 1',
          icon: '🎯',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final input = CategoryInput(
          name: 'Category 1',
          icon: '🎯',
          color: '#FF5722',
          parentCategoryId: 'cat2',
        );

        when(mockCategoryDataSource.getById('cat1'))
            .thenAnswer((_) async => existingCategory);
        when(mockCategoryDataSource.hasCircularReference('cat1', 'cat2'))
            .thenAnswer((_) async => true);

        // Act & Assert
        expect(
          () => categoryService.updateCategory('cat1', input),
          throwsException,
        );
      });
    });

    group('deleteCategory', () {
      test('should delete category and reassign transactions', () async {
        // Arrange
        final category = Category(
          id: 'cat1',
          userId: 'user123',
          name: 'Old Category',
          icon: '🎯',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final reassignCategory = Category(
          id: 'cat2',
          userId: 'user123',
          name: 'New Category',
          icon: '🎨',
          color: '#4CAF50',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final transactions = <Transaction>[
          Transaction(
            id: 'tx1',
            userId: 'user123',
            amount: Decimal.parse('100'),
            currency: Currency.USD,
            type: TransactionType.expense,
            categoryId: 'cat1',
            date: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.synced,
          ),
        ];

        when(mockCategoryDataSource.getById('cat1'))
            .thenAnswer((_) async => category);
        when(mockCategoryDataSource.getById('cat2'))
            .thenAnswer((_) async => reassignCategory);
        when(mockTransactionDataSource.getByCategory(
          userId: 'user123',
          categoryId: 'cat1',
        )).thenAnswer((_) async => transactions);
        when(mockTransactionDataSource.batchUpdate(any))
            .thenAnswer((_) async {});
        when(mockCategoryDataSource.getChildCategories(
          parentCategoryId: 'cat1',
          userId: 'user123',
        )).thenAnswer((_) async => []);
        when(mockCategoryDataSource.delete('cat1')).thenAnswer((_) async {});

        // Act
        await categoryService.deleteCategory('cat1', 'cat2');

        // Assert
        verify(mockTransactionDataSource.batchUpdate(any)).called(1);
        verify(mockCategoryDataSource.delete('cat1')).called(1);
      });

      test('should throw exception when category not found', () async {
        // Arrange
        when(mockCategoryDataSource.getById('nonexistent'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => categoryService.deleteCategory('nonexistent', 'cat2'),
          throwsException,
        );
      });

      test('should throw exception when reassignment category not found',
          () async {
        // Arrange
        final category = Category(
          id: 'cat1',
          userId: 'user123',
          name: 'Category',
          icon: '🎯',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCategoryDataSource.getById('cat1'))
            .thenAnswer((_) async => category);
        when(mockCategoryDataSource.getById('nonexistent'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => categoryService.deleteCategory('cat1', 'nonexistent'),
          throwsException,
        );
      });

      test('should throw exception when reassigning to same category',
          () async {
        // Arrange
        final category = Category(
          id: 'cat1',
          userId: 'user123',
          name: 'Category',
          icon: '🎯',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCategoryDataSource.getById('cat1'))
            .thenAnswer((_) async => category);

        // Act & Assert
        expect(
          () => categoryService.deleteCategory('cat1', 'cat1'),
          throwsException,
        );
      });
    });

    group('getAllCategories', () {
      test('should return all categories for a user', () async {
        // Arrange
        const userId = 'user123';
        final categories = [
          Category(
            id: 'cat1',
            userId: userId,
            name: 'Category 1',
            icon: '🎯',
            color: '#FF5722',
            isDefault: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockCategoryDataSource.getAll(userId: userId))
            .thenAnswer((_) async => categories);

        // Act
        final result = await categoryService.getAllCategories(userId);

        // Assert
        expect(result, equals(categories));
        verify(mockCategoryDataSource.getAll(userId: userId)).called(1);
      });
    });

    group('getCategoryTree', () {
      test('should return category hierarchy', () async {
        // Arrange
        const userId = 'user123';
        final parent = Category(
          id: 'parent',
          userId: userId,
          name: 'Parent',
          icon: '🎯',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final child = Category(
          id: 'child',
          userId: userId,
          name: 'Child',
          icon: '🎨',
          color: '#4CAF50',
          parentCategoryId: 'parent',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCategoryDataSource.getCategoryHierarchy(userId: userId))
            .thenAnswer((_) async => {
                  parent: [child]
                });

        // Act
        final result = await categoryService.getCategoryTree(userId);

        // Assert
        expect(result.rootCategories, contains(parent));
        expect(result.getChildren(parent), contains(child));
      });
    });

    group('hasTransactions', () {
      test('should return true when category has transactions', () async {
        // Arrange
        final category = Category(
          id: 'cat1',
          userId: 'user123',
          name: 'Category',
          icon: '🎯',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final transactions = <Transaction>[
          Transaction(
            id: 'tx1',
            userId: 'user123',
            amount: Decimal.parse('100'),
            currency: Currency.USD,
            type: TransactionType.expense,
            categoryId: 'cat1',
            date: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.synced,
          ),
        ];

        when(mockCategoryDataSource.getById('cat1'))
            .thenAnswer((_) async => category);
        when(mockTransactionDataSource.getByCategory(
          userId: 'user123',
          categoryId: 'cat1',
        )).thenAnswer((_) async => transactions);

        // Act
        final result = await categoryService.hasTransactions('cat1');

        // Assert
        expect(result, isTrue);
      });

      test('should return false when category has no transactions', () async {
        // Arrange
        final category = Category(
          id: 'cat1',
          userId: 'user123',
          name: 'Category',
          icon: '🎯',
          color: '#FF5722',
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockCategoryDataSource.getById('cat1'))
            .thenAnswer((_) async => category);
        when(mockTransactionDataSource.getByCategory(
          userId: 'user123',
          categoryId: 'cat1',
        )).thenAnswer((_) async => []);

        // Act
        final result = await categoryService.hasTransactions('cat1');

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
