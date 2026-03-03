import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../domain/services/locale_formatting_service.dart';
import '../../domain/value_objects/currency.dart';

/// Implementation of LocaleFormattingService using the intl package
/// 
/// This service provides comprehensive locale-aware formatting for dates,
/// numbers, and currency amounts according to regional conventions.
class LocaleFormattingServiceImpl implements LocaleFormattingService {
  // Cache of initialized locales to avoid redundant initialization
  final Set<String> _initializedLocales = {};

  /// Ensure locale data is initialized before use
  Future<void> _ensureLocaleInitialized(String locale) async {
    if (!_initializedLocales.contains(locale)) {
      try {
        await initializeDateFormatting(locale, null);
        _initializedLocales.add(locale);
      } catch (e) {
        // If specific locale fails, try just the language code
        final languageCode = locale.split('_')[0];
        if (languageCode != locale && !_initializedLocales.contains(languageCode)) {
          try {
            await initializeDateFormatting(languageCode, null);
            _initializedLocales.add(languageCode);
          } catch (e) {
            // Fall back to default locale if initialization fails
            // This allows the app to continue functioning
          }
        }
      }
    }
  }

  @override
  String formatDate(DateTime date, String locale) {
    // For date formatting with custom patterns, we don't need full locale initialization
    final pattern = getDatePattern(locale);
    try {
      final formatter = DateFormat(pattern, locale);
      return formatter.format(date);
    } catch (e) {
      // Fallback to pattern without locale if it fails
      final formatter = DateFormat(pattern);
      return formatter.format(date);
    }
  }

  @override
  String formatDateTime(DateTime dateTime, String locale) {
    // Use medium date and short time format
    try {
      final formatter = DateFormat.yMd(locale).add_jm();
      return formatter.format(dateTime);
    } catch (e) {
      // Fallback to default locale
      final formatter = DateFormat.yMd().add_jm();
      return formatter.format(dateTime);
    }
  }

  @override
  String formatNumber(
    Decimal number,
    String locale, {
    int? decimalPlaces,
  }) {
    final formatter = NumberFormat.decimalPattern(locale);
    
    if (decimalPlaces != null) {
      formatter.minimumFractionDigits = decimalPlaces;
      formatter.maximumFractionDigits = decimalPlaces;
    }
    
    return formatter.format(number.toDouble());
  }

  @override
  String formatCurrency({
    required Decimal amount,
    required Currency currency,
    required String locale,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currency.symbol,
      decimalDigits: currency.decimalPlaces,
    );
    
    return formatter.format(amount.toDouble());
  }

  @override
  String formatPercentage(Decimal percentage, String locale) {
    final formatter = NumberFormat.percentPattern(locale);
    // Divide by 100 since NumberFormat.percentPattern expects a decimal (0.85 for 85%)
    final decimalValue = percentage / Decimal.fromInt(100);
    return formatter.format(decimalValue.toDouble());
  }

  @override
  String getDatePattern(String locale) {
    // Parse locale string
    final localeParts = locale.split('_');
    final languageCode = localeParts[0];
    final countryCode = localeParts.length > 1 ? localeParts[1] : null;

    // Determine date pattern based on locale
    // Asian locales typically use YYYY-MM-DD
    if (languageCode == 'zh' || 
        languageCode == 'ja' || 
        languageCode == 'ko') {
      return 'yyyy-MM-dd';
    }

    // US uses MM/DD/YYYY
    if (languageCode == 'en' && countryCode == 'US') {
      return 'MM/dd/yyyy';
    }

    // Most other locales use DD/MM/YYYY
    // This includes: en_GB, fr, es, de, pt, ar, hi, etc.
    return 'dd/MM/yyyy';
  }

  @override
  String getDecimalSeparator(String locale) {
    final formatter = NumberFormat.decimalPattern(locale);
    final symbols = formatter.symbols;
    return symbols.DECIMAL_SEP;
  }

  @override
  String getThousandsSeparator(String locale) {
    final formatter = NumberFormat.decimalPattern(locale);
    final symbols = formatter.symbols;
    return symbols.GROUP_SEP;
  }
}
