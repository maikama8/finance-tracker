import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:decimal/decimal.dart';
import '../../domain/services/report_generator.dart';
import '../../domain/value_objects/date_range.dart';
import '../../domain/value_objects/currency.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/dashboard_provider.dart';

/// Pie chart showing spending distribution by category
class SpendingByCategoryChart extends ConsumerWidget {
  final String userId;
  final DateRange dateRange;

  const SpendingByCategoryChart({
    super.key,
    required this.userId,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportGenerator = ref.watch(reportGeneratorProvider);
    final user = ref.watch(currentUserProvider);

    return FutureBuilder<ChartData>(
      future: reportGenerator.getSpendingByCategory(dateRange, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final chartData = snapshot.data;
        if (chartData == null || chartData.data.isEmpty) {
          return Card(
            child: SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No spending data for this period',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Calculate total spending
        final totalSpending = chartData.data.values.fold(
          Decimal.zero,
          (sum, amount) => sum + amount,
        );

        // Prepare pie chart sections
        final sections = <PieChartSectionData>[];
        int colorIndex = 0;

        chartData.data.forEach((categoryName, amount) {
          final ratio = amount / totalSpending;
          final percentage = (ratio.toDouble() * 100);

          sections.add(
            PieChartSectionData(
              value: amount.toDouble(),
              title: '${percentage.toStringAsFixed(1)}%',
              color: _getColor(colorIndex),
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
                  children: chartData.data.entries.map((entry) {
                    final categoryName = entry.key;
                    final amount = entry.value;
                    final index = chartData.data.keys.toList().indexOf(categoryName);

                    final currencyService = ref.watch(currencyServiceProvider);
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
                            color: _getColor(index),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$categoryName: $formattedAmount',
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
      },
    );
  }

  Color _getColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }
}
