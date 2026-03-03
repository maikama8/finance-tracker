import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import '../../domain/entities/category.dart';
import '../../domain/services/category_service.dart';
import '../../application/state/dashboard_provider.dart';
import '../../application/state/transaction_list_provider.dart';
import '../../application/state/auth_provider.dart';
import 'create_category_screen.dart';

/// Screen for picking a category with hierarchy support
class CategoryPickerScreen extends ConsumerWidget {
  const CategoryPickerScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.selectCategory ?? 'Select Category'),
        ),
        body: const Center(child: Text('User not authenticated')),
      );
    }
    
    final categoryTreeAsync = ref.watch(categoryTreeProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.selectCategory ?? 'Select Category'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: categoryTreeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (categoryTree) {
          final rootCategories = categoryTree.rootCategories;

          if (rootCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.noCategories ?? 'No categories yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.createFirstCategory ?? 'Create your first category',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: rootCategories.length,
            itemBuilder: (context, index) {
              final category = rootCategories[index];
              final children = categoryTree.getChildren(category);

              return CategoryTile(
                category: category,
                children: children,
                onSelect: (selectedCategory) {
                  Navigator.pop(context, selectedCategory);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateCategory(context),
        icon: const Icon(Icons.add),
        label: Text(l10n?.createCategory ?? 'Create Category'),
      ),
    );
  }

  Future<void> _navigateToCreateCategory(BuildContext context) async {
    final category = await Navigator.push<Category>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCategoryScreen(),
      ),
    );
    
    if (category != null && context.mounted) {
      Navigator.pop(context, category);
    }
  }
}

/// Category tile with expandable children
class CategoryTile extends StatefulWidget {
  final Category category;
  final List<Category> children;
  final Function(Category) onSelect;

  const CategoryTile({
    super.key,
    required this.category,
    required this.children,
    required this.onSelect,
  });

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.children.isNotEmpty;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.category.colorValue,
              child: Text(
                widget.category.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              widget.category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: hasChildren
                ? IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  )
                : null,
            onTap: () => widget.onSelect(widget.category),
          ),
        ),
        if (hasChildren && _isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Column(
              children: widget.children.map((child) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: child.colorValue,
                      radius: 16,
                      child: Text(
                        child.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    title: Text(child.name),
                    onTap: () => widget.onSelect(child),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
