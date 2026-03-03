import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:decimal/decimal.dart';
import '../../domain/entities/category.dart';
import '../../domain/value_objects/currency.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/dashboard_provider.dart';

/// Pie chart showing monthly spending breakdown by category
class DashboardSpendingChart extends ConsumerWidget {
  final Map<String, Decimal> spendingBreakdown;
  final Map<String, Category> categories;

  const DashboardSpendingChart({
    super.key,
    required this.spendingBreakdown,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currencyService = ref.watch(currencyServiceProvider);

    // Calculate total spending
    final totalSpending = spendingBreakdown.values.fold(
      Decimal.zero,
      (sum, amount) => sum + amount,
    );

    if (totalSpending == Decimal.zero) {
      return const SizedBox.shrink();
    }

    // Prepare pie chart sections
    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    spendingBreakdown.forEach((categoryId, amount) {
      final category = categories[categoryId];
      final percentage = (amount / totalSpending * Decimal.fromInt(100))
          .toDouble();

      sections.add(
        PieChartSectionData(
          value: amount.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          color: category?.colorValue ?? _getDefaultColor(colorIndex),
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Pie chart
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: spendingBreakdown.entries.map((entry) {
                final categoryId = entry.key;
                final amount = entry.value;
                final category = categories[categoryId];

                final formattedAmount = currencyService.formatAmount(
                  amount: amount,
                  currency: user?.baseCurrency ?? const Currency(
                    code: 'USD',
                    symbol: '\$',
                    name: 'US Dollar',
                    decimalPlaces: 2,
                  ),
                  locale: user?.locale.toString() ?? 'en',
                );

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: category?.colorValue ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${category?.name ?? 'Unknown'}: $formattedAmount',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDefaultColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }
}
