import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';

/// Widget displaying a category with its children in a hierarchical view
class CategoryHierarchyItem extends StatefulWidget {
  final Category category;
  final List<Category> children;
  final String userId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryHierarchyItem({
    Key? key,
    required this.category,
    required this.children,
    required this.userId,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<CategoryHierarchyItem> createState() => _CategoryHierarchyItemState();
}

class _CategoryHierarchyItemState extends State<CategoryHierarchyItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.children.isNotEmpty;

    return Column(
      children: [
        ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasChildren)
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                const SizedBox(width: 24),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.category.colorValue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    widget.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            widget.category.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: widget.category.isDefault
              ? Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: widget.onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: widget.onDelete,
                tooltip: 'Delete',
                color: Colors.red[400],
              ),
            ],
          ),
        ),
        if (_isExpanded && hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 48.0),
            child: Column(
              children: widget.children.map((child) {
                return _buildChildItem(child);
              }).toList(),
            ),
          ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildChildItem(Category child) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: child.colorValue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            child.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(child.name),
      subtitle: child.isDefault
          ? Text(
              'Default',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () {
              // Navigate to edit screen for child category
              // This will be handled by the parent widget
            },
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: () {
              // Show delete dialog for child category
              // This will be handled by the parent widget
            },
            tooltip: 'Delete',
            color: Colors.red[400],
          ),
        ],
      ),
    );
  }
}
