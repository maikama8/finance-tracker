import 'package:decimal/decimal.dart';
import '../value_objects/currency.dart';
import '../value_objects/exchange_rate.dart';

/// Service for managing currency exchange rates and conversions
abstract class CurrencyService {
  /// Fetch current exchange rates from the API
  /// This should be called at least once per day when online
  Future<void> fetchExchangeRates();

  /// Convert an amount from one currency to another
  /// Uses cached rates if available, throws exception if rates not available
  Future<Decimal> convert({
    required Decimal amount,
    required Currency from,
    required Currency to,
  });

  /// Get the exchange rate between two currencies
  /// Returns null if rate is not available
  Future<ExchangeRate?> getRate({
    required Currency from,
    required Currency to,
  });

  /// Get the timestamp of the last exchange rate update
  /// Returns null if no rates have been fetched yet
  Future<DateTime?> getLastUpdateTime();

  /// Get list of all supported currencies
  List<Currency> getSupportedCurrencies();

  /// Format an amount according to locale settings
  /// Includes proper decimal separators, thousands separators, and currency symbol placement
  String formatAmount({
    required Decimal amount,
    required Currency currency,
    required String locale,
  });

  /// Check if exchange rates need to be refreshed
  /// Returns true if rates are expired or not available
  Future<bool> needsRefresh();
}
