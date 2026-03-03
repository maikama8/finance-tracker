import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../../domain/services/category_service.dart';
import '../../domain/value_objects/date_range.dart';
import 'dashboard_provider.dart';

/// Provider for transaction list with optional filters
final transactionListProvider = FutureProvider.family<List<Transaction>, TransactionListParams>(
  (ref, params) async {
    final transactionRepo = ref.watch(transactionRepositoryProvider);
    
    return await transactionRepo.getAll(
      userId: params.userId,
      range: params.dateRange,
      categoryId: params.categoryId,
    );
  },
);

/// Parameters for transaction list provider
class TransactionListParams {
  final String userId;
  final DateRange? dateRange;
  final String? categoryId;

  const TransactionListParams({
    required this.userId,
    this.dateRange,
    this.categoryId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionListParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          dateRange == other.dateRange &&
          categoryId == other.categoryId;

  @override
  int get hashCode => Object.hash(userId, dateRange, categoryId);
}

/// Provider for getting a category by ID
final categoryByIdProvider = FutureProvider.family<Category?, String>(
  (ref, categoryId) async {
    final categoryService = ref.watch(categoryServiceProvider);
    return await categoryService.getCategoryById(categoryId);
  },
);

/// Provider for all categories for a user
final allCategoriesProvider = FutureProvider.family<List<Category>, String>(
  (ref, userId) async {
    final categoryService = ref.watch(categoryServiceProvider);
    return await categoryService.getAllCategories(userId);
  },
);

/// Provider for category tree
final categoryTreeProvider = FutureProvider.family<CategoryHierarchy, String>(
  (ref, userId) async {
    final categoryService = ref.watch(categoryServiceProvider);
    return await categoryService.getCategoryTree(userId);
  },
);
