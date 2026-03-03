import 'dart:io';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/category_service.dart';
import '../../domain/services/report_generator.dart';
import '../../domain/value_objects/date_range.dart';

/// Implementation of ReportGenerator service
/// 
/// Generates PDF and CSV reports with charts and insights
class ReportGeneratorImpl implements ReportGenerator {
  final TransactionRepository _transactionRepository;
  final CategoryService _categoryService;

  ReportGeneratorImpl({
    required TransactionRepository transactionRepository,
    required CategoryService categoryService,
  })  : _transactionRepository = transactionRepository,
        _categoryService = categoryService;

  @override
  Future<ChartData> getSpendingByCategory(
    DateRange range,
    String userId,
  ) async {
    // Get spending breakdown from repository
    final breakdown = await _transactionRepository.getSpendingBreakdown(
      userId: userId,
      range: range,
    );

    // Get all categories to map IDs to names
    final categories = await _categoryService.getAllCategories(userId);
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    // Convert category IDs to names
    final namedData = <String, Decimal>{};
    for (final entry in breakdown.entries) {
      final categoryName = categoryMap[entry.key] ?? 'Unknown';
      namedData[categoryName] = entry.value;
    }

    return ChartData(
      data: namedData,
      title: 'Spending by Category',
      type: ChartType.pie,
    );
  }

  @override
  Future<ChartData> getSpendingTrends({
    required DateRange range,
    required String userId,
    required Granularity granularity,
  }) async {
    // Get all transactions in the range
    final transactions = await _transactionRepository.getAll(
      userId: userId,
      range: range,
    );

    // Filter only expenses
    final expenses = transactions.where((t) => t.type == TransactionType.expense);

    // Group by time period based on granularity
    final Map<String, Decimal> trendData = {};

    for (final transaction in expenses) {
      final periodKey = _getPeriodKey(transaction.date, granularity);
      trendData[periodKey] = (trendData[periodKey] ?? Decimal.zero) + transaction.amount;
    }

    // Sort by period key
    final sortedData = Map.fromEntries(
      trendData.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return ChartData(
      data: sortedData,
      title: 'Spending Trends',
      type: ChartType.bar,
    );
  }

  @override
  Future<List<Insight>> generateInsights(String userId) async {
    final insights = <Insight>[];

    // Get last 30 days of transactions
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final range = DateRange(start: thirtyDaysAgo, end: now);

    // Get spending breakdown
    final breakdown = await _transactionRepository.getSpendingBreakdown(
      userId: userId,
      range: range,
    );

    if (breakdown.isEmpty) {
      return insights;
    }

    // Get all categories
    final categories = await _categoryService.getAllCategories(userId);
    final categoryMap = {for (var cat in categories) cat.id: cat};

    // Find highest spending categories
    final sortedCategories = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Top 3 spending categories
    final topCategories = sortedCategories.take(3);
    for (final entry in topCategories) {
      final category = categoryMap[entry.key];
      if (category != null) {
        insights.add(Insight(
          title: 'High Spending: ${category.name}',
          description: 'You spent ${entry.value} on ${category.name} in the last 30 days',
          type: InsightType.highSpending,
          amount: entry.value,
          categoryId: entry.key,
        ));
      }
    }

    // Calculate total spending
    final totalSpending = breakdown.values.fold(
      Decimal.zero,
      (sum, amount) => sum + amount,
    );

    // Suggest savings opportunities (categories with >20% of total spending)
    for (final entry in sortedCategories) {
      final percentage = (entry.value / totalSpending).toDecimal() * Decimal.fromInt(100);
      if (percentage > Decimal.fromInt(20)) {
        final category = categoryMap[entry.key];
        if (category != null) {
          final savingsAmount = entry.value * Decimal.parse('0.2'); // 20% reduction
          insights.add(Insight(
            title: 'Savings Opportunity: ${category.name}',
            description: 'Reducing ${category.name} spending by 20% could save you $savingsAmount',
            type: InsightType.savingsOpportunity,
            amount: savingsAmount,
            categoryId: entry.key,
          ));
        }
      }
    }

    return insights;
  }

  @override
  Future<File> generatePDF(ReportConfig config) async {
    final pdf = pw.Document();

    // Get data for the report
    final transactions = await _transactionRepository.getAll(
      userId: config.userId,
      range: config.dateRange,
    );

    final spendingByCategory = await getSpendingByCategory(
      config.dateRange,
      config.userId,
    );

    final insights = await generateInsights(config.userId);

    // Calculate summary statistics
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(Decimal.zero, (sum, t) => sum + t.amount);

    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(Decimal.zero, (sum, t) => sum + t.amount);

    final netBalance = totalIncome - totalExpenses;

    // Build PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              'Financial Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),

          // Metadata
          pw.Text('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
          pw.Text('Period: ${DateFormat('yyyy-MM-dd').format(config.dateRange.start)} to ${DateFormat('yyyy-MM-dd').format(config.dateRange.end)}'),
          pw.Text('User ID: ${config.userId}'),
          pw.SizedBox(height: 20),

          // Summary Statistics
          pw.Header(level: 1, child: pw.Text('Summary')),
          pw.TableHelper.fromTextArray(
            data: [
              ['Metric', 'Amount'],
              ['Total Income', totalIncome.toString()],
              ['Total Expenses', totalExpenses.toString()],
              ['Net Balance', netBalance.toString()],
              ['Transactions', transactions.length.toString()],
            ],
          ),
          pw.SizedBox(height: 20),

          // Spending by Category
          pw.Header(level: 1, child: pw.Text('Spending by Category')),
          pw.TableHelper.fromTextArray(
            data: [
              ['Category', 'Amount'],
              ...spendingByCategory.data.entries.map(
                (e) => [e.key, e.value.toString()],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Insights
          if (insights.isNotEmpty) ...[
            pw.Header(level: 1, child: pw.Text('Insights')),
            ...insights.map(
              (insight) => pw.Bullet(
                text: '${insight.title}: ${insight.description}',
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Transaction Table
          pw.Header(level: 1, child: pw.Text('Transactions')),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Date', 'Type', 'Amount', 'Currency', 'Category'],
              ...transactions.map((t) => [
                    DateFormat('yyyy-MM-dd').format(t.date),
                    t.type.name,
                    t.amount.toString(),
                    t.currency.code,
                    t.categoryId,
                  ]),
            ],
          ),
        ],
      ),
    );

    // Save PDF to file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/financial_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  @override
  Future<File> generateCSV(ReportConfig config) async {
    // Get all transactions in the range
    final transactions = await _transactionRepository.getAll(
      userId: config.userId,
      range: config.dateRange,
    );

    // Get all categories for name lookup
    final categories = await _categoryService.getAllCategories(config.userId);
    final categoryMap = {for (var cat in categories) cat.id: cat.name};

    // Build CSV content
    final buffer = StringBuffer();

    // Metadata header
    buffer.writeln('# Financial Data Export');
    buffer.writeln('# Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('# Period: ${DateFormat('yyyy-MM-dd').format(config.dateRange.start)} to ${DateFormat('yyyy-MM-dd').format(config.dateRange.end)}');
    buffer.writeln('# User ID: ${config.userId}');
    buffer.writeln();

    // CSV header
    buffer.writeln('date,category,amount,currency,type,notes');

    // CSV rows
    for (final transaction in transactions) {
      final categoryName = categoryMap[transaction.categoryId] ?? 'Unknown';
      final notes = transaction.notes?.replaceAll(',', ';') ?? ''; // Escape commas
      
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(transaction.date)},'
        '$categoryName,'
        '${transaction.amount},'
        '${transaction.currency.code},'
        '${transaction.type.name},'
        '"$notes"',
      );
    }

    // Save CSV to file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/financial_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    return file;
  }

  /// Get period key based on granularity
  String _getPeriodKey(DateTime date, Granularity granularity) {
    switch (granularity) {
      case Granularity.daily:
        return DateFormat('yyyy-MM-dd').format(date);
      case Granularity.weekly:
        // ISO week number
        final weekNumber = _getWeekNumber(date);
        return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
      case Granularity.monthly:
        return DateFormat('yyyy-MM').format(date);
      case Granularity.yearly:
        return DateFormat('yyyy').format(date);
    }
  }

  /// Get ISO week number
  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Future<void> shareReport(File reportFile) async {
    final fileName = path.basename(reportFile.path);
    
    // Use share_plus to share the file via system share dialog
    // This allows users to share via email, messaging, or save to device
    await Share.shareXFiles(
      [XFile(reportFile.path)],
      subject: 'Financial Report - $fileName',
      text: 'Here is your financial report',
    );
  }
}
