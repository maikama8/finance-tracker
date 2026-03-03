import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:decimal/decimal.dart';
import '../../domain/services/report_generator.dart';
import '../../domain/value_objects/date_range.dart';
import '../../domain/value_objects/currency.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/dashboard_provider.dart';

/// Bar chart showing spending trends over time
class SpendingTrendsChart extends ConsumerWidget {
  final String userId;
  final DateRange dateRange;
  final Granularity granularity;

  const SpendingTrendsChart({
    super.key,
    required this.userId,
    required this.dateRange,
    required this.granularity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportGenerator = ref.watch(reportGeneratorProvider);
    final user = ref.watch(currentUserProvider);

    return FutureBuilder<ChartData>(
      future: reportGenerator.getSpendingTrends(
        range: dateRange,
        userId: userId,
        granularity: granularity,
      ),
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
                      Icons.bar_chart,
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

        // Prepare bar chart data
        final barGroups = <BarChartGroupData>[];
        final periods = chartData.data.keys.toList();
        
        for (int i = 0; i < periods.length; i++) {
          final period = periods[i];
          final amount = chartData.data[period] ?? Decimal.zero;
          
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amount.toDouble(),
                  color: Colors.blue,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }

        // Find max value for Y axis
        final maxY = chartData.data.values.fold(
          Decimal.zero,
          (max, amount) => amount > max ? amount : max,
        ).toDouble();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Bar chart
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY * 1.2, // Add 20% padding
                      barGroups: barGroups,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < periods.length) {
                                final period = periods[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _formatPeriodLabel(period),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              final currencyService = ref.watch(currencyServiceProvider);
                              final formatted = currencyService.formatAmount(
                                amount: Decimal.parse(value.toString()),
                                currency: user?.baseCurrency ?? const Currency(
                                  code: 'USD',
                                  symbol: '\$',
                                  name: 'US Dollar',
                                  decimalPlaces: 2,
                                ),
                                locale: user?.locale.toString() ?? 'en',
                              );
                              return Text(
                                formatted,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPeriodLabel(String period) {
    // Format period labels based on granularity
    switch (granularity) {
      case Granularity.daily:
        // Format: 2024-01-15 -> 01/15
        if (period.length >= 10) {
          final parts = period.split('-');
          if (parts.length == 3) {
            return '${parts[1]}/${parts[2]}';
          }
        }
        return period;
      
      case Granularity.weekly:
        // Format: 2024-W03 -> W03
        if (period.contains('-W')) {
          return period.split('-').last;
        }
        return period;
      
      case Granularity.monthly:
        // Format: 2024-01 -> Jan '24
        if (period.length >= 7) {
          final parts = period.split('-');
          if (parts.length == 2) {
            final monthNames = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];
            final monthIndex = int.tryParse(parts[1]);
            if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
              final year = parts[0].substring(2); // Last 2 digits
              return "${monthNames[monthIndex - 1]} '$year";
            }
          }
        }
        return period;
      
      case Granularity.yearly:
        // Format: 2024 -> 2024
        return period;
    }
  }
}
