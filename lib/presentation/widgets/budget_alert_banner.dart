import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/budget_provider.dart';
import '../../application/state/dashboard_provider.dart';

/// Widget that displays budget alert banners at the top of screens
class BudgetAlertBanner extends ConsumerWidget {
  const BudgetAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final budgetTracker = ref.watch(budgetTrackerProvider);
    final categoryService = ref.watch(categoryServiceProvider);

    return FutureBuilder<List<Budget>>(
      future: budgetTracker.getAll(user.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final budgets = snapshot.data!;
        final alertBudgets = budgets.where((b) => b.isNearLimit || b.isOverLimit).toList();

        if (alertBudgets.isEmpty) return const SizedBox.shrink();

        return Column(
          children: alertBudgets.map((budget) {
            return FutureBuilder<Category?>(
              future: categoryService.getCategoryById(budget.categoryId),
              builder: (context, categorySnapshot) {
                final category = categorySnapshot.data;
                return _AlertBannerItem(
                  budget: budget,
                  category: category,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

/// Individual alert banner item
class _AlertBannerItem extends StatelessWidget {
  final Budget budget;
  final Category? category;

  const _AlertBannerItem({
    required this.budget,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isOverLimit = budget.isOverLimit;
    final color = isOverLimit ? Colors.red : Colors.orange;
    final icon = isOverLimit ? Icons.error : Icons.warning_amber;
    final percentage = budget.percentageUsed.toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverLimit ? 'Budget Exceeded!' : 'Budget Alert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${category?.name ?? 'Unknown'}: $percentage% used',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '${budget.currency.symbol}${budget.currentSpending.toStringAsFixed(budget.currency.decimalPlaces)} of ${budget.currency.symbol}${budget.monthlyLimit.toStringAsFixed(budget.currency.decimalPlaces)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
