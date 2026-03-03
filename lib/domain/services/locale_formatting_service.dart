import 'package:decimal/decimal.dart';
import '../value_objects/currency.dart';

/// Service for locale-aware formatting of dates, numbers, and currency
/// 
/// This service provides methods to format data according to the user's locale settings,
/// ensuring proper display of dates (DD/MM/YYYY, MM/DD/YYYY, YYYY-MM-DD),
/// numbers (with locale-specific separators), and currency (with proper symbol placement).
abstract class LocaleFormattingService {
  /// Format a date according to the locale
  /// 
  /// Returns date in the appropriate format for the locale:
  /// - en_US: MM/DD/YYYY
  /// - en_GB, fr, es, de, pt: DD/MM/YYYY
  /// - zh, ja, ko: YYYY-MM-DD
  String formatDate(DateTime date, String locale);

  /// Format a date with time according to the locale
  String formatDateTime(DateTime dateTime, String locale);

  /// Format a number with locale-specific separators
  /// 
  /// Examples:
  /// - en_US: 1,234.56
  /// - fr_FR: 1 234,56
  /// - de_DE: 1.234,56
  String formatNumber(Decimal number, String locale, {int? decimalPlaces});

  /// Format currency amount with proper symbol placement
  /// 
  /// Examples:
  /// - en_US: $1,234.56
  /// - fr_FR: 1 234,56 €
  /// - de_DE: 1.234,56 €
  String formatCurrency({
    required Decimal amount,
    required Currency currency,
    required String locale,
  });

  /// Format a percentage according to locale
  String formatPercentage(Decimal percentage, String locale);

  /// Get the date format pattern for a locale
  /// 
  /// Returns patterns like "MM/dd/yyyy", "dd/MM/yyyy", "yyyy-MM-dd"
  String getDatePattern(String locale);

  /// Get the decimal separator for a locale
  /// 
  /// Returns "." for en_US, "," for fr_FR, de_DE, etc.
  String getDecimalSeparator(String locale);

  /// Get the thousands separator for a locale
  /// 
  /// Returns "," for en_US, " " for fr_FR, "." for de_DE, etc.
  String getThousandsSeparator(String locale);
}
