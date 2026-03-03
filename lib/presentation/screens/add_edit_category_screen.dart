import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../domain/services/category_service.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../application/state/auth_provider.dart';
import '../widgets/color_picker_grid.dart';
import '../widgets/icon_picker_grid.dart';

/// Screen for adding or editing a category
class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final Category? category; // null for add, non-null for edit

  const AddEditCategoryScreen({
    Key? key,
    this.category,
  }) : super(key: key);

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  String _selectedIcon = '📁';
  String _selectedColor = '#2196F3'; // Default blue
  String? _selectedParentCategoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.category?.name ?? '',
    );
    
    if (widget.category != null) {
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
      _selectedParentCategoryId = widget.category!.parentCategoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.category != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editCategory : l10n.addCategory),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Category name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.categoryName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.categoryNameRequired;
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Icon selection
            Text(
              l10n.selectIcon,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildIconSelector(),
            const SizedBox(height: 24),

            // Color selection
            Text(
              l10n.selectColor,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildColorSelector(),
            const SizedBox(height: 24),

            // Parent category selection
            Text(
              l10n.parentCategory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildParentCategorySelector(),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? l10n.saveChanges : l10n.addCategory),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSelector() {
    return GestureDetector(
      onTap: _showIconPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getColorFromHex(_selectedColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _selectedIcon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.tapToSelectIcon,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    return GestureDetector(
      onTap: _showColorPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getColorFromHex(_selectedColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.tapToSelectColor,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildParentCategorySelector() {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    
    final categoriesAsync = ref.watch(categoryListProvider(user.id));

    return categoriesAsync.when(
      data: (categories) {
        // Filter out the current category (when editing) and its children
        final availableCategories = categories.where((c) {
          if (_isEditing && c.id == widget.category!.id) {
            return false; // Can't be parent of itself
          }
          // TODO: Also filter out children to prevent circular references
          return true;
        }).toList();

        return DropdownButtonFormField<String?>(
          value: _selectedParentCategoryId,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: AppLocalizations.of(context)!.noneRootCategory,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(AppLocalizations.of(context)!.noneRootCategory),
            ),
            ...availableCategories.map((category) {
              return DropdownMenuItem<String?>(
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
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedParentCategoryId = value;
            });
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text(
        AppLocalizations.of(context)!.errorLoadingCategories,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IconPickerGrid(
        selectedIcon: _selectedIcon,
        onIconSelected: (icon) {
          setState(() {
            _selectedIcon = icon;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ColorPickerGrid(
        selectedColor: _selectedColor,
        onColorSelected: (color) {
          setState(() {
            _selectedColor = color;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final categoryService = ref.read(categoryServiceProvider);
      final input = CategoryInput(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        parentCategoryId: _selectedParentCategoryId,
      );

      if (_isEditing) {
        await categoryService.updateCategory(widget.category!.id, input);
      } else {
        await categoryService.createCustomCategory(user.id, input);
      }

      // Refresh category lists
      ref.invalidate(categoryListProvider(user.id));
      ref.invalidate(categoryHierarchyProvider(user.id));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? AppLocalizations.of(context)!.categorySaved
                  : AppLocalizations.of(context)!.categoryAdded,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorSavingCategory,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}

// Import providers from category_list_screen
final categoryListProvider = FutureProvider.family<List<Category>, String>(
  (ref, userId) async {
    final categoryService = ref.watch(categoryServiceProvider);
    return await categoryService.getAllCategories(userId);
  },
);

final categoryHierarchyProvider = FutureProvider.family<CategoryHierarchy, String>(
  (ref, userId) async {
    final categoryService = ref.watch(categoryServiceProvider);
    return await categoryService.getCategoryTree(userId);
  },
);

final categoryServiceProvider = Provider<CategoryService>((ref) {
  throw UnimplementedError('CategoryService provider not configured');
});
