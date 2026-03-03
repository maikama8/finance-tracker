import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../domain/services/category_service.dart';
import '../../application/state/auth_provider.dart';
import '../../gen_l10n/app_localizations.dart';
import '../widgets/category_hierarchy_item.dart';
import 'add_edit_category_screen.dart';
import 'category_template_picker_screen.dart';

/// Provider for category list state
final categoryListProvider = FutureProvider.family<List<Category>, String>(
  (ref, userId) async {
    final categoryService = ref.watch(categoryServiceProvider);
    return await categoryService.getAllCategories(userId);
  },
);

/// Provider for category hierarchy
final categoryHierarchyProvider = FutureProvider.family<CategoryHierarchy, String>(
  (ref, userId) async {
    final categoryService = ref.watch(categoryServiceProvider);
    return await categoryService.getCategoryTree(userId);
  },
);

/// Screen displaying all categories with hierarchy
class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final userId = user.id;
    final hierarchyAsync = ref.watch(categoryHierarchyProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: l10n.categoryTemplates,
            onPressed: () => _showTemplateSelector(context),
          ),
        ],
      ),
      body: hierarchyAsync.when(
        data: (hierarchy) => _buildCategoryList(context, hierarchy, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(l10n.errorLoadingCategories),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddCategory(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, CategoryHierarchy hierarchy, WidgetRef ref) {
    final rootCategories = hierarchy.rootCategories;

    if (rootCategories.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: rootCategories.length,
      itemBuilder: (context, index) {
        final category = rootCategories[index];
        final children = hierarchy.getChildren(category);
        
        return CategoryHierarchyItem(
          category: category,
          children: children,
          onEdit: () => _navigateToEditCategory(context, category),
          onDelete: () => _showDeleteDialog(context, category, ref),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noCategoriesYet,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addCategoryToGetStarted,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddCategory(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addCategory),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddCategory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditCategoryScreen(),
      ),
    );
  }

  void _navigateToEditCategory(BuildContext context, Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(
          category: category,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Category category, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    showDialog(
      context: context,
      builder: (context) => DeleteCategoryDialog(
        category: category,
        userId: user.id,
      ),
    );
  }

  void _showTemplateSelector(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryTemplatePickerScreen(),
      ),
    );
  }
}

/// Dialog for deleting a category with reassignment
class DeleteCategoryDialog extends ConsumerStatefulWidget {
  final Category category;
  final String userId;

  const DeleteCategoryDialog({
    Key? key,
    required this.category,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends ConsumerState<DeleteCategoryDialog> {
  String? _selectedReassignCategoryId;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoryListProvider(widget.userId));

    return AlertDialog(
      title: Text(l10n.deleteCategory),
      content: categoriesAsync.when(
        data: (categories) => _buildDialogContent(context, categories),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Text(l10n.errorLoadingCategories),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _isDeleting || _selectedReassignCategoryId == null
              ? null
              : _handleDelete,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.red),
                ),
        ),
      ],
    );
  }

  Widget _buildDialogContent(BuildContext context, List<Category> categories) {
    final l10n = AppLocalizations.of(context)!;
    
    // Filter out the category being deleted
    final availableCategories = categories
        .where((c) => c.id != widget.category.id)
        .toList();

    if (availableCategories.isEmpty) {
      return Text(l10n.cannotDeleteLastCategory);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.deleteCategoryWarning(widget.category.name)),
        const SizedBox(height: 16),
        Text(
          l10n.selectReassignCategory,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedReassignCategoryId,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n.selectCategory,
          ),
          items: availableCategories.map((category) {
            return DropdownMenuItem(
              value: category.id,
              child: Row(
                children: [
                  Text(
                    category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(category.name)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedReassignCategoryId = value;
            });
          },
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    if (_selectedReassignCategoryId == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final categoryService = ref.read(categoryServiceProvider);
      await categoryService.deleteCategory(
        widget.category.id,
        _selectedReassignCategoryId!,
      );

      // Refresh the category list
      ref.invalidate(categoryListProvider(widget.userId));
      ref.invalidate(categoryHierarchyProvider(widget.userId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.categoryDeleted,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorDeletingCategory,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Provider for CategoryService (to be defined in services.dart)
final categoryServiceProvider = Provider<CategoryService>((ref) {
  throw UnimplementedError('CategoryService provider not configured');
});
