import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gen_l10n/app_localizations.dart';
import 'package:decimal/decimal.dart';
import '../../domain/services/report_generator.dart';
import '../../domain/value_objects/date_range.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/dashboard_provider.dart';
import '../widgets/spending_by_category_chart.dart';
import '../widgets/spending_trends_chart.dart';
import '../widgets/insights_list.dart';

/// Reports and insights screen showing spending analysis and export options
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateRange _selectedRange = DateRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  Granularity _selectedGranularity = Granularity.daily;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.reports ?? 'Reports'),
        ),
        body: const Center(
          child: Text('Please log in to view reports'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.reports ?? 'Reports'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showExportDialog(context, user.id),
            tooltip: l10n?.export ?? 'Export',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range selector
            _buildDateRangeSelector(context, l10n),
            const SizedBox(height: 24),

            // Spending by category pie chart
            Text(
              l10n?.spendingByCategory ?? 'Spending by Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SpendingByCategoryChart(
              userId: user.id,
              dateRange: _selectedRange,
            ),
            const SizedBox(height: 32),

            // Spending trends bar chart
            Text(
              l10n?.spendingTrends ?? 'Spending Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildGranularitySelector(context, l10n),
            const SizedBox(height: 16),
            SpendingTrendsChart(
              userId: user.id,
              dateRange: _selectedRange,
              granularity: _selectedGranularity,
            ),
            const SizedBox(height: 32),

            // Insights section
            Text(
              l10n?.insights ?? 'Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            InsightsList(userId: user.id),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, AppLocalizations? l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.dateRange ?? 'Date Range',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context,
                    l10n?.startDate ?? 'Start',
                    _selectedRange.start,
                    (date) {
                      setState(() {
                        _selectedRange = DateRange(
                          start: date,
                          end: _selectedRange.end,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateButton(
                    context,
                    l10n?.endDate ?? 'End',
                    _selectedRange.end,
                    (date) {
                      setState(() {
                        _selectedRange = DateRange(
                          start: _selectedRange.start,
                          end: date,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickRangeChip(
                  context,
                  l10n?.last7Days ?? 'Last 7 Days',
                  7,
                ),
                _buildQuickRangeChip(
                  context,
                  l10n?.last30Days ?? 'Last 30 Days',
                  30,
                ),
                _buildQuickRangeChip(
                  context,
                  l10n?.last90Days ?? 'Last 90 Days',
                  90,
                ),
                _buildQuickRangeChip(
                  context,
                  l10n?.thisYear ?? 'This Year',
                  null,
                  isYearToDate: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onDateSelected,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRangeChip(
    BuildContext context,
    String label,
    int? days, {
    bool isYearToDate = false,
  }) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          final now = DateTime.now();
          if (isYearToDate) {
            _selectedRange = DateRange(
              start: DateTime(now.year, 1, 1),
              end: now,
            );
          } else if (days != null) {
            _selectedRange = DateRange(
              start: now.subtract(Duration(days: days)),
              end: now,
            );
          }
        });
      },
    );
  }

  Widget _buildGranularitySelector(BuildContext context, AppLocalizations? l10n) {
    return SegmentedButton<Granularity>(
      segments: [
        ButtonSegment(
          value: Granularity.daily,
          label: Text(l10n?.daily ?? 'Daily'),
          icon: const Icon(Icons.calendar_today, size: 16),
        ),
        ButtonSegment(
          value: Granularity.weekly,
          label: Text(l10n?.weekly ?? 'Weekly'),
          icon: const Icon(Icons.calendar_view_week, size: 16),
        ),
        ButtonSegment(
          value: Granularity.monthly,
          label: Text(l10n?.monthly ?? 'Monthly'),
          icon: const Icon(Icons.calendar_month, size: 16),
        ),
      ],
      selected: {_selectedGranularity},
      onSelectionChanged: (Set<Granularity> newSelection) {
        setState(() {
          _selectedGranularity = newSelection.first;
        });
      },
    );
  }

  void _showExportDialog(BuildContext context, String userId) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.exportReport ?? 'Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(l10n?.exportPdf ?? 'Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportReport(context, userId, isPdf: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(l10n?.exportCsv ?? 'Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportReport(context, userId, isPdf: false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(
    BuildContext context,
    String userId, {
    required bool isPdf,
  }) async {
    final l10n = AppLocalizations.of(context);
    final reportGenerator = ref.read(reportGeneratorProvider);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n?.generatingReport ?? 'Generating report...'),
          ],
        ),
      ),
    );

    try {
      final config = ReportConfig(
        userId: userId,
        dateRange: _selectedRange,
      );

      final file = isPdf
          ? await reportGenerator.generatePDF(config)
          : await reportGenerator.generateCSV(config);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show share dialog
      await reportGenerator.shareReport(file);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.reportGenerated ?? 'Report generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.error ?? 'Error'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
