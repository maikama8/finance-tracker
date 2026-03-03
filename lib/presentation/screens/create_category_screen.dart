import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import '../../domain/entities/category.dart';
import '../../domain/services/category_service.dart';
import '../../application/state/dashboard_provider.dart';
import '../../application/state/transaction_list_provider.dart';
import '../../application/state/auth_provider.dart';

/// Screen for creating a custom category
class CreateCategoryScreen extends ConsumerStatefulWidget {
  final Category? parentCategory;

  const CreateCategoryScreen({
    super.key,
    this.parentCategory,
  });

  @override
  ConsumerState<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends ConsumerState<CreateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedIcon = '📁';
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;

  // Common icons for categories
  static const List<String> _commonIcons = [
    '🍔', '🍕', '☕', '🍜', '🛒', // Food & Groceries
    '🚗', '⛽', '🚇', '🚌', '🏍️', // Transport
    '🏠', '💡', '💧', '📱', '💻', // Home & Utilities
    '👕', '👗', '👟', '💄', '💍', // Shopping & Fashion
    '🎬', '🎮', '📚', '🎵', '🎨', // Entertainment
    '💊', '🏥', '💪', '🧘', '⚽', // Health & Fitness
    '✈️', '🏖️', '🏨', '🎡', '🗺️', // Travel
    '🎓', '📖', '✏️', '🎒', '🖊️', // Education
    '💰', '💳', '💵', '🏦', '📊', // Finance
    '📁', '📂', '📋', '📌', '🔖', // General
  ];

  // Common colors for categories
  static const List<Color> _commonColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.createCategory ?? 'Create Category'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _selectedColor,
                        radius: 32,
                        child: Text(
                          _selectedIcon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _nameController.text.isEmpty
                              ? (l10n?.categoryPreview ?? 'Category Preview')
                              : _nameController.text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n?.categoryName ?? 'Category Name',
                  prefixIcon: const Icon(Icons.label),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n?.pleaseEnterCategoryName ?? 'Please enter a category name';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // Update preview
                },
              ),
              const SizedBox(height: 24),

              // Icon Selection
              Text(
                l10n?.selectIcon ?? 'Select Icon',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _commonIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _commonIcons[index];
                    final isSelected = icon == _selectedIcon;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? _selectedColor.withAlpha((0.3 * 255).round()) : null,
                          border: Border.all(
                            color: isSelected ? _selectedColor : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Color Selection
              Text(
                l10n?.selectColor ?? 'Select Color',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonColors.map((color) {
                  final isSelected = color == _selectedColor;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Parent Category Info (if applicable)
              if (widget.parentCategory != null)
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n?.subcategoryOf ?? 'Subcategory of'}: ${widget.parentCategory!.name}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.parentCategory != null) const SizedBox(height: 16),

              // Create Button
              FilledButton(
                onPressed: _isLoading ? null : _createCategory,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n?.createCategory ?? 'Create Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = ref.read(categoryServiceProvider);
      
      // Convert color to hex string
      final colorHex = _selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2);
      
      final input = CategoryInput(
        name: _nameController.text,
        icon: _selectedIcon,
        color: colorHex,
        parentCategoryId: widget.parentCategory?.id,
      );

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final category = await categoryService.createCustomCategory(user.id, input);

      // Invalidate providers to refresh data
      ref.invalidate(allCategoriesProvider);
      ref.invalidate(categoryTreeProvider);

      if (mounted) {
        Navigator.pop(context, category);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.categoryCreated ??
                  'Category created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
