import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:personal_finance_tracker/domain/entities/category.dart';
import 'package:personal_finance_tracker/domain/entities/transaction.dart';
import 'package:personal_finance_tracker/domain/repositories/transaction_repository.dart';
import 'package:personal_finance_tracker/domain/services/category_service.dart';
import 'package:personal_finance_tracker/domain/services/report_generator.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/domain/value_objects/date_range.dart';
import 'package:personal_finance_tracker/infrastructure/services/report_generator_impl.dart';

@GenerateMocks([TransactionRepository, CategoryService])
import 'report_generator_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ReportGenerator reportGenerator;
  late MockTransactionRepository mockTransactionRepository;
  late MockCategoryService mockCategoryService;

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    mockCategoryService = MockCategoryService();

    reportGenerator = ReportGeneratorImpl(
      transactionRepository: mockTransactionRepository,
      categoryService: mockCategoryService,
    );
  });

  group('ReportGenerator', () {
    test('getSpendingByCategory returns chart data with category names', () async {
      // Arrange
      final userId = 'user123';
      final range = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      final category1 = Category(
        id: 'cat1',
        name: 'Food',
        icon: '🍔',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final category2 = Category(
        id: 'cat2',
        name: 'Transport',
        icon: '🚗',
        color: '#00FF00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockTransactionRepository.getSpendingBreakdown(
        userId: userId,
        range: range,
      )).thenAnswer((_) async => {
            'cat1': Decimal.parse('100.50'),
            'cat2': Decimal.parse('50.25'),
          });

      when(mockCategoryService.getAllCategories(userId))
          .thenAnswer((_) async => [category1, category2]);

      // Act
      final result = await reportGenerator.getSpendingByCategory(range, userId);

      // Assert
      expect(result.type, ChartType.pie);
      expect(result.title, 'Spending by Category');
      expect(result.data['Food'], Decimal.parse('100.50'));
      expect(result.data['Transport'], Decimal.parse('50.25'));
    });

    test('getSpendingTrends groups transactions by granularity', () async {
      // Arrange
      final userId = 'user123';
      final range = DateRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 1, 31),
      );

      final transactions = [
        Transaction(
          id: 't1',
          userId: userId,
          amount: Decimal.parse('50'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat1',
          date: DateTime(2024, 1, 5),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: 't2',
          userId: userId,
          amount: Decimal.parse('75'),
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: 'cat1',
          date: DateTime(2024, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockTransactionRepository.getAll(
        userId: userId,
        range: range,
      )).thenAnswer((_) async => transactions);

      // Act
      final result = await reportGenerator.getSpendingTrends(
        range: range,
        userId: userId,
        granularity: Granularity.daily,
      );

      // Assert
      expect(result.type, ChartType.bar);
      expect(result.title, 'Spending Trends');
      expect(result.data.length, 2);
      expect(result.data['2024-01-05'], Decimal.parse('50'));
      expect(result.data['2024-01-15'], Decimal.parse('75'));
    });

    test('generateInsights identifies high spending categories', () async {
      // Arrange
      final userId = 'user123';

      final category1 = Category(
        id: 'cat1',
        name: 'Food',
        icon: '🍔',
        color: '#FF0000',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock with any matcher for range since it's calculated internally
      when(mockTransactionRepository.getSpendingBreakdown(
        userId: anyNamed('userId'),
        range: anyNamed('range'),
      )).thenAnswer((_) async => {
            'cat1': Decimal.parse('500'),
          });

      when(mockCategoryService.getAllCategories(userId))
          .thenAnswer((_) async => [category1]);

      // Act
      final insights = await reportGenerator.generateInsights(userId);

      // Assert
      expect(insights.isNotEmpty, true);
      expect(insights.any((i) => i.type == InsightType.highSpending), true);
      expect(insights.any((i) => i.categoryId == 'cat1'), true);
    });

    // Note: PDF and CSV generation tests are skipped as they require
    // platform-specific setup (path_provider) which is not available in unit tests
  });
}
