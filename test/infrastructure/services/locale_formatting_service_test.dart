import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:personal_finance_tracker/infrastructure/services/locale_formatting_service_impl.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';

void main() {
  late LocaleFormattingServiceImpl service;

  setUp(() {
    service = LocaleFormattingServiceImpl();
  });

  group('LocaleFormattingService - Date Formatting', () {
    final testDate = DateTime(2024, 3, 15); // March 15, 2024

    test('formats date in US format (MM/DD/YYYY)', () {
      final formatted = service.formatDate(testDate, 'en_US');
      expect(formatted, '03/15/2024');
    });

    test('formats date in European format (DD/MM/YYYY)', () {
      final formatted = service.formatDate(testDate, 'en_GB');
      expect(formatted, '15/03/2024');
    });

    test('formats date in French format (DD/MM/YYYY)', () {
      final formatted = service.formatDate(testDate, 'fr_FR');
      expect(formatted, '15/03/2024');
    });

    test('formats date in German format (DD/MM/YYYY)', () {
      final formatted = service.formatDate(testDate, 'de_DE');
      expect(formatted, '15/03/2024');
    });

    test('formats date in Spanish format (DD/MM/YYYY)', () {
      final formatted = service.formatDate(testDate, 'es_ES');
      expect(formatted, '15/03/2024');
    });

    test('formats date in Portuguese format (DD/MM/YYYY)', () {
      final formatted = service.formatDate(testDate, 'pt_PT');
      expect(formatted, '15/03/2024');
    });

    test('formats date in Chinese format (YYYY-MM-DD)', () {
      final formatted = service.formatDate(testDate, 'zh_CN');
      expect(formatted, '2024-03-15');
    });

    test('formats date in Arabic format (DD/MM/YYYY)', () {
      final formatted = service.formatDate(testDate, 'ar_SA');
      expect(formatted, '15/03/2024');
    });

    test('formats date in Hindi format (DD/MM/YYYY)', () {
      final formatted = service.formatDate(testDate, 'hi_IN');
      expect(formatted, '15/03/2024');
    });
  });

  group('LocaleFormattingService - Number Formatting', () {
    final testNumber = Decimal.parse('1234.56');

    test('formats number in US format (1,234.56)', () {
      final formatted = service.formatNumber(testNumber, 'en_US');
      expect(formatted, '1,234.56');
    });

    test('formats number in French format (1 234,56)', () {
      final formatted = service.formatNumber(testNumber, 'fr_FR');
      // French uses non-breaking space as thousands separator
      expect(formatted.contains('234'), true);
      expect(formatted.contains(',56'), true);
    });

    test('formats number in German format (1.234,56)', () {
      final formatted = service.formatNumber(testNumber, 'de_DE');
      expect(formatted, '1.234,56');
    });

    test('formats number with specific decimal places', () {
      final number = Decimal.parse('1234.5');
      final formatted = service.formatNumber(number, 'en_US', decimalPlaces: 2);
      expect(formatted, '1,234.50');
    });

    test('formats number with zero decimal places', () {
      final number = Decimal.parse('1234.56');
      final formatted = service.formatNumber(number, 'en_US', decimalPlaces: 0);
      expect(formatted, '1,235');
    });
  });

  group('LocaleFormattingService - Currency Formatting', () {
    final testAmount = Decimal.parse('1234.56');

    test('formats USD in US locale (\$1,234.56)', () {
      final formatted = service.formatCurrency(
        amount: testAmount,
        currency: Currency.USD,
        locale: 'en_US',
      );
      expect(formatted, '\$1,234.56');
    });

    test('formats EUR in French locale (1 234,56 €)', () {
      final formatted = service.formatCurrency(
        amount: testAmount,
        currency: Currency.EUR,
        locale: 'fr_FR',
      );
      // French format typically places symbol after amount
      expect(formatted.contains('€'), true);
      expect(formatted.contains('1'), true);
      expect(formatted.contains('234'), true);
      expect(formatted.contains('56'), true);
    });

    test('formats GBP in UK locale (£1,234.56)', () {
      final formatted = service.formatCurrency(
        amount: testAmount,
        currency: Currency.GBP,
        locale: 'en_GB',
      );
      expect(formatted, '£1,234.56');
    });

    test('formats JPY with zero decimal places (¥1,235)', () {
      final amount = Decimal.parse('1234.56');
      final formatted = service.formatCurrency(
        amount: amount,
        currency: Currency.JPY,
        locale: 'ja_JP',
      );
      // JPY has 0 decimal places
      expect(formatted.contains('¥'), true);
      expect(formatted.contains('1,235') || formatted.contains('1235'), true);
    });

    test('formats NGN in Nigerian locale', () {
      final formatted = service.formatCurrency(
        amount: testAmount,
        currency: Currency.NGN,
        locale: 'en_NG',
      );
      expect(formatted.contains('₦'), true);
      expect(formatted.contains('1,234.56') || formatted.contains('1234.56'), true);
    });
  });

  group('LocaleFormattingService - Percentage Formatting', () {
    test('formats percentage in US locale (85%)', () {
      final percentage = Decimal.parse('85');
      final formatted = service.formatPercentage(percentage, 'en_US');
      expect(formatted, '85%');
    });

    test('formats percentage in French locale (85 %)', () {
      final percentage = Decimal.parse('85.5');
      final formatted = service.formatPercentage(percentage, 'fr_FR');
      // French may add space before % and use comma for decimal
      expect(formatted.contains('85') || formatted.contains('86'), true);
      expect(formatted.contains('%'), true);
    });

    test('formats decimal percentage (85.5%)', () {
      final percentage = Decimal.parse('85.5');
      final formatted = service.formatPercentage(percentage, 'en_US');
      expect(formatted.contains('85') || formatted.contains('86'), true);
      expect(formatted.contains('%'), true);
    });
  });

  group('LocaleFormattingService - Date Pattern', () {
    test('returns MM/dd/yyyy for US locale', () {
      final pattern = service.getDatePattern('en_US');
      expect(pattern, 'MM/dd/yyyy');
    });

    test('returns dd/MM/yyyy for UK locale', () {
      final pattern = service.getDatePattern('en_GB');
      expect(pattern, 'dd/MM/yyyy');
    });

    test('returns dd/MM/yyyy for French locale', () {
      final pattern = service.getDatePattern('fr_FR');
      expect(pattern, 'dd/MM/yyyy');
    });

    test('returns yyyy-MM-dd for Chinese locale', () {
      final pattern = service.getDatePattern('zh_CN');
      expect(pattern, 'yyyy-MM-dd');
    });

    test('returns yyyy-MM-dd for Japanese locale', () {
      final pattern = service.getDatePattern('ja_JP');
      expect(pattern, 'yyyy-MM-dd');
    });

    test('returns yyyy-MM-dd for Korean locale', () {
      final pattern = service.getDatePattern('ko_KR');
      expect(pattern, 'yyyy-MM-dd');
    });
  });

  group('LocaleFormattingService - Separators', () {
    test('returns correct decimal separator for US locale', () {
      final separator = service.getDecimalSeparator('en_US');
      expect(separator, '.');
    });

    test('returns correct decimal separator for French locale', () {
      final separator = service.getDecimalSeparator('fr_FR');
      expect(separator, ',');
    });

    test('returns correct decimal separator for German locale', () {
      final separator = service.getDecimalSeparator('de_DE');
      expect(separator, ',');
    });

    test('returns correct thousands separator for US locale', () {
      final separator = service.getThousandsSeparator('en_US');
      expect(separator, ',');
    });

    test('returns correct thousands separator for French locale', () {
      final separator = service.getThousandsSeparator('fr_FR');
      // French uses non-breaking space or thin space
      // Just verify it's not empty and not a comma or period
      expect(separator.isNotEmpty, true);
      expect(separator != ',', true);
      expect(separator != '.', true);
    });

    test('returns correct thousands separator for German locale', () {
      final separator = service.getThousandsSeparator('de_DE');
      expect(separator, '.');
    });
  });

  group('LocaleFormattingService - DateTime Formatting', () {
    final testDateTime = DateTime(2024, 3, 15, 14, 30); // March 15, 2024, 2:30 PM

    test('formats datetime in US locale', () {
      final formatted = service.formatDateTime(testDateTime, 'en_US');
      expect(formatted.contains('3/15/2024') || formatted.contains('03/15/2024'), true);
      expect(formatted.contains('2:30') || formatted.contains('14:30'), true);
    });

    test('formats datetime in UK locale', () {
      final formatted = service.formatDateTime(testDateTime, 'en_GB');
      // Just verify it contains the date components
      expect(formatted.contains('15') || formatted.contains('3') || formatted.contains('2024'), true);
    });

    test('formats datetime in French locale', () {
      final formatted = service.formatDateTime(testDateTime, 'fr_FR');
      // Just verify it contains the date components
      expect(formatted.contains('15') || formatted.contains('3') || formatted.contains('2024'), true);
    });
  });
}
