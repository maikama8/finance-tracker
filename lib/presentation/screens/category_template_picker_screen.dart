import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_template.dart';
import '../../domain/entities/regional_category_templates.dart';
import '../../domain/services/category_service.dart';
import '../../application/state/auth_provider.dart';
import '../../gen_l10n/app_localizations.dart';

/// Screen for selecting and applying regional category templates
class CategoryTemplatePickerScreen extends ConsumerStatefulWidget {
  final bool isFirstLaunch;

  const CategoryTemplatePickerScreen({
    Key? key,
    this.isFirstLaunch = false,
  }) : super(key: key);

  @override
  ConsumerState<CategoryTemplatePickerScreen> createState() =>
      _CategoryTemplatePickerScreenState();
}

class _CategoryTemplatePickerScreenState
    extends ConsumerState<CategoryTemplatePickerScreen> {
  CategoryTemplate? _selectedTemplate;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    // Pre-select template based on device locale
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    _selectedTemplate = RegionalCategoryTemplates.getTemplateOrFallback(deviceLocale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryTemplates),
        automaticallyImplyLeading: !widget.isFirstLaunch,
      ),
      body: Column(
        children: [
          if (widget.isFirstLaunch)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.selectTemplateForYourRegion,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _buildTemplateList(),
            ),
          ),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  List<Widget> _buildTemplateList() {
    final templates = RegionalCategoryTemplates.allTemplates;

    return templates.map((template) {
      final isSelected = _selectedTemplate?.localeString == template.localeString;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTemplate = template;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      template.flag,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            template.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.categories,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: template.categories.take(8).map((category) {
                    return Chip(
                      avatar: Text(category.icon),
                      label: Text(
                        category.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: category.color.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                if (template.categories.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      AppLocalizations.of(context)!.andMoreCategories(
                        template.categories.length - 8,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!widget.isFirstLaunch)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isApplying ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
            if (!widget.isFirstLaunch) const SizedBox(width: 12),
            Expanded(
              flex: widget.isFirstLaunch ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isApplying || _selectedTemplate == null
                    ? null
                    : _handleApplyTemplate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isApplying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l10n.applyTemplate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApplyTemplate() async {
    if (_selectedTemplate == null) return;

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
      _isApplying = true;
    });

    try {
      final categoryService = ref.read(categoryServiceProvider);
      
      // Get the locale from the selected template
      final localeParts = _selectedTemplate!.localeString.split('_');
      final locale = Locale(localeParts[0], localeParts.length > 1 ? localeParts[1] : null);
      
      // Load default categories for the selected locale
      await categoryService.getDefaultCategories(locale);

      // Refresh category lists
      ref.invalidate(categoryListProvider(user.id));
      ref.invalidate(categoryHierarchyProvider(user.id));

      if (mounted) {
        if (widget.isFirstLaunch) {
          // Navigate to main app
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          Navigator.pop(context);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.templateApplied,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorApplyingTemplate,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Import providers from other screens
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
