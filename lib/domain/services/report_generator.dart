import 'dart:io';
import 'package:decimal/decimal.dart';
import '../value_objects/date_range.dart';

/// Configuration for generating reports
class ReportConfig {
  final String userId;
  final DateRange dateRange;
  final String? baseCurrencyCode;

  const ReportConfig({
    required this.userId,
    required this.dateRange,
    this.baseCurrencyCode,
  });
}

/// Data structure for chart visualizations
class ChartData {
  final Map<String, Decimal> data;
  final String title;
  final ChartType type;

  const ChartData({
    required this.data,
    required this.title,
    required this.type,
  });
}

/// Types of charts supported
enum ChartType {
  pie,
  bar,
  line,
}

/// Granularity for trend analysis
enum Granularity {
  daily,
  weekly,
  monthly,
  yearly,
}

/// Insight about spending patterns
class Insight {
  final String title;
  final String description;
  final InsightType type;
  final Decimal? amount;
  final String? categoryId;

  const Insight({
    required this.title,
    required this.description,
    required this.type,
    this.amount,
    this.categoryId,
  });
}

/// Types of insights
enum InsightType {
  highSpending,
  savingsOpportunity,
  budgetWarning,
  goalProgress,
}

/// Service for generating financial reports and insights
abstract class ReportGenerator {
  /// Generate a PDF report with charts and statistics
  Future<File> generatePDF(ReportConfig config);

  /// Generate a CSV export of transactions
  Future<File> generateCSV(ReportConfig config);

  /// Get spending distribution by category for pie charts
  Future<ChartData> getSpendingByCategory(DateRange range, String userId);

  /// Get spending trends over time for bar/line charts
  Future<ChartData> getSpendingTrends({
    required DateRange range,
    required String userId,
    required Granularity granularity,
  });

  /// Generate actionable insights based on spending patterns
  Future<List<Insight>> generateInsights(String userId);

  /// Share a generated report file via email, messaging, or save to device
  Future<void> shareReport(File reportFile);
}
