import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/domain/value_objects/exchange_rate.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/exchange_rate_local_data_source.dart';
import 'package:personal_finance_tracker/infrastructure/services/currency_service_impl.dart';

import 'currency_service_test.mocks.dart';

@GenerateMocks([http.Client, ExchangeRateLocalDataSource])
void main() {
  late CurrencyServiceImpl currencyService;
  late MockClient mockHttpClient;
  late MockExchangeRateLocalDataSource mockLocalDataSource;

  setUp(() {
    mockHttpClient = MockClient();
    mockLocalDataSource = MockExchangeRateLocalDataSource();
    currencyService = CurrencyServiceImpl(
      localDataSource: mockLocalDataSource,
      httpClient: mockHttpClient,
      apiKey: 'test_api_key',
    );
  });

  group('CurrencyService', () {
    group('fetchExchangeRates', () {
      test('should fetch and store exchange rates successfully', () async {
        // Arrange
        final mockResponse = {
          'result': 'success',
          'conversion_rates': {
            'USD': 1.0,
            'EUR': 0.92,
            'GBP': 0.79,
            'JPY': 149.50,
            'NGN': 1620.0,
          },
        };

        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(json.encode(mockResponse), 200),
        );

        when(mockLocalDataSource.batchStore(any)).thenAnswer((_) async {});

        // Act
        await currencyService.fetchExchangeRates();

        // Assert
        verify(mockHttpClient.get(any)).called(1);
        verify(mockLocalDataSource.batchStore(any)).called(1);
      });

      test('should throw exception when API returns error', () async {
        // Arrange
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('Not Found', 404),
        );

        // Act & Assert
        expect(
          () => currencyService.fetchExchangeRates(),
          throwsException,
        );
      });
    });

    group('convert', () {
      test('should return same amount when converting same currency', () async {
        // Arrange
        final amount = Decimal.parse('100.00');

        // Act
        final result = await currencyService.convert(
          amount: amount,
          from: Currency.USD,
          to: Currency.USD,
        );

        // Assert
        expect(result, equals(amount));
      });

      test('should convert amount using cached exchange rate', () async {
        // Arrange
        final amount = Decimal.parse('100.00');
        final exchangeRate = ExchangeRate(
          baseCurrency: Currency.USD,
          targetCurrency: Currency.EUR,
          rate: Decimal.parse('0.92'),
          timestamp: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        when(mockLocalDataSource.getValidRate(
          baseCurrency: Currency.USD,
          targetCurrency: Currency.EUR,
        )).thenAnswer((_) async => exchangeRate);

        // Act
        final result = await currencyService.convert(
          amount: amount,
          from: Currency.USD,
          to: Currency.EUR,
        );

        // Assert
        expect(result, equals(Decimal.parse('92.00')));
      });

      test('should round to currency-specific decimal places', () async {
        // Arrange
        final amount = Decimal.parse('100.00');
        final exchangeRate = ExchangeRate(
          baseCurrency: Currency.USD,
          targetCurrency: Currency.JPY,
          rate: Decimal.parse('149.50'),
          timestamp: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        when(mockLocalDataSource.getValidRate(
          baseCurrency: Currency.USD,
          targetCurrency: Currency.JPY,
        )).thenAnswer((_) async => exchangeRate);

        // Act
        final result = await currencyService.convert(
          amount: amount,
          from: Currency.USD,
          to: Currency.JPY,
        );

        // Assert - JPY has 0 decimal places
        expect(result, equals(Decimal.parse('14950')));
      });

      test('should throw exception when rate not available', () async {
        // Arrange
        when(mockLocalDataSource.getValidRate(
          baseCurrency: anyNamed('baseCurrency'),
          targetCurrency: anyNamed('targetCurrency'),
        )).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => currencyService.convert(
            amount: Decimal.parse('100.00'),
            from: Currency.USD,
            to: Currency.EUR,
          ),
          throwsException,
        );
      });
    });

    group('formatAmount', () {
      test('should format amount with currency symbol and locale', () {
        // Arrange
        final amount = Decimal.parse('1234.56');

        // Act
        final result = currencyService.formatAmount(
          amount: amount,
          currency: Currency.USD,
          locale: 'en_US',
        );

        // Assert
        expect(result, contains('\$'));
        expect(result, contains('1,234.56'));
      });

      test('should format amount with zero decimal places for JPY', () {
        // Arrange
        final amount = Decimal.parse('1234');

        // Act
        final result = currencyService.formatAmount(
          amount: amount,
          currency: Currency.JPY,
          locale: 'ja_JP',
        );

        // Assert
        expect(result, contains('¥'));
        expect(result, contains('1,234'));
        expect(result, isNot(contains('.00')));
      });
    });

    group('getSupportedCurrencies', () {
      test('should return list of major currencies', () {
        // Act
        final currencies = currencyService.getSupportedCurrencies();

        // Assert
        expect(currencies, isNotEmpty);
        expect(currencies, contains(Currency.USD));
        expect(currencies, contains(Currency.EUR));
        expect(currencies, contains(Currency.NGN));
        expect(currencies, contains(Currency.JPY));
      });
    });

    group('needsRefresh', () {
      test('should return true when cache needs refresh', () async {
        // Arrange
        when(mockLocalDataSource.needsRefresh()).thenAnswer((_) async => true);

        // Act
        final result = await currencyService.needsRefresh();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when cache is valid', () async {
        // Arrange
        when(mockLocalDataSource.needsRefresh())
            .thenAnswer((_) async => false);

        // Act
        final result = await currencyService.needsRefresh();

        // Assert
        expect(result, isFalse);
      });
    });

    group('getLastUpdateTime', () {
      test('should return last update timestamp', () async {
        // Arrange
        final timestamp = DateTime.now();
        when(mockLocalDataSource.getLatestUpdateTime())
            .thenAnswer((_) async => timestamp);

        // Act
        final result = await currencyService.getLastUpdateTime();

        // Assert
        expect(result, equals(timestamp));
      });

      test('should return null when no rates cached', () async {
        // Arrange
        when(mockLocalDataSource.getLatestUpdateTime())
            .thenAnswer((_) async => null);

        // Act
        final result = await currencyService.getLastUpdateTime();

        // Assert
        expect(result, isNull);
      });
    });
  });
}
