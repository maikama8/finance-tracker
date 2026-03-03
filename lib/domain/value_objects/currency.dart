import 'package:equatable/equatable.dart';

/// Value object representing a currency with ISO 4217 code
class Currency extends Equatable {
  final String code; // ISO 4217 code (e.g., "USD", "EUR", "NGN")
  final String symbol; // Currency symbol (e.g., "$", "€", "₦")
  final String name; // Full currency name (e.g., "US Dollar")
  final int decimalPlaces; // Number of decimal places (e.g., 2 for USD, 0 for JPY)

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalPlaces,
  });

  // Major currency constants
  static const Currency USD = Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    decimalPlaces: 2,
  );

  static const Currency EUR = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    decimalPlaces: 2,
  );

  static const Currency NGN = Currency(
    code: 'NGN',
    symbol: '₦',
    name: 'Nigerian Naira',
    decimalPlaces: 2,
  );

  static const Currency GBP = Currency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    decimalPlaces: 2,
  );

  static const Currency JPY = Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    decimalPlaces: 0,
  );

  static const Currency INR = Currency(
    code: 'INR',
    symbol: '₹',
    name: 'Indian Rupee',
    decimalPlaces: 2,
  );

  static const Currency CAD = Currency(
    code: 'CAD',
    symbol: 'C\$',
    name: 'Canadian Dollar',
    decimalPlaces: 2,
  );

  static const Currency AUD = Currency(
    code: 'AUD',
    symbol: 'A\$',
    name: 'Australian Dollar',
    decimalPlaces: 2,
  );

  static const Currency CHF = Currency(
    code: 'CHF',
    symbol: 'CHF',
    name: 'Swiss Franc',
    decimalPlaces: 2,
  );

  static const Currency CNY = Currency(
    code: 'CNY',
    symbol: '¥',
    name: 'Chinese Yuan',
    decimalPlaces: 2,
  );

  static const Currency BRL = Currency(
    code: 'BRL',
    symbol: 'R\$',
    name: 'Brazilian Real',
    decimalPlaces: 2,
  );

  static const Currency ZAR = Currency(
    code: 'ZAR',
    symbol: 'R',
    name: 'South African Rand',
    decimalPlaces: 2,
  );

  static const Currency KES = Currency(
    code: 'KES',
    symbol: 'KSh',
    name: 'Kenyan Shilling',
    decimalPlaces: 2,
  );

  static const Currency GHS = Currency(
    code: 'GHS',
    symbol: 'GH₵',
    name: 'Ghanaian Cedi',
    decimalPlaces: 2,
  );

  static const Currency EGP = Currency(
    code: 'EGP',
    symbol: 'E£',
    name: 'Egyptian Pound',
    decimalPlaces: 2,
  );

  /// List of all supported major currencies
  static const List<Currency> majorCurrencies = [
    USD,
    EUR,
    NGN,
    GBP,
    JPY,
    INR,
    CAD,
    AUD,
    CHF,
    CNY,
    BRL,
    ZAR,
    KES,
    GHS,
    EGP,
  ];

  /// Commonly used currencies (alias for majorCurrencies)
  static List<Currency> get commonCurrencies => majorCurrencies;

  /// Find a currency by its ISO 4217 code
  static Currency? fromCode(String code) {
    try {
      return majorCurrencies.firstWhere(
        (currency) => currency.code == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [code, symbol, name, decimalPlaces];

  @override
  String toString() => '$code ($symbol)';
}
