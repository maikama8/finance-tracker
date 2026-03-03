import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../domain/services/currency_service.dart';
import '../../domain/value_objects/currency.dart';
import '../../domain/value_objects/exchange_rate.dart';
import '../data_sources/local/exchange_rate_local_data_source.dart';

/// Implementation of CurrencyService using exchangerate-api.com
/// 
/// This service fetches exchange rates from the API and caches them locally.
/// It falls back to cached rates when offline and provides locale-aware formatting.
class CurrencyServiceImpl implements CurrencyService {
  final ExchangeRateLocalDataSource _localDataSource;
  final http.Client _httpClient;
  final String _apiKey;
  final String _baseUrl;

  // Default to USD as the base currency for API calls
  static const Currency _apiBaseCurrency = Currency.USD;

  CurrencyServiceImpl({
    required ExchangeRateLocalDataSource localDataSource,
    http.Client? httpClient,
    String? apiKey,
    String? baseUrl,
  })  : _localDataSource = localDataSource,
        _httpClient = httpClient ?? http.Client(),
        _apiKey = apiKey ?? 'YOUR_API_KEY_HERE', // Replace with actual API key
        _baseUrl = baseUrl ?? 'https://v6.exchangerate-api.com/v6';

  @override
  Future<void> fetchExchangeRates() async {
    try {
      // Fetch rates from exchangerate-api.com
      final url = '$_baseUrl/$_apiKey/latest/${_apiBaseCurrency.code}';
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch exchange rates: ${response.statusCode}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Check if the API call was successful
      if (data['result'] != 'success') {
        throw Exception('API returned error: ${data['error-type']}');
      }

      // Extract rates and timestamp
      final rates = data['conversion_rates'] as Map<String, dynamic>;
      final timestamp = DateTime.now();
      
      // Rates expire after 24 hours
      final expiresAt = timestamp.add(const Duration(hours: 24));

      // Convert API rates to ExchangeRate objects
      final List<ExchangeRate> exchangeRates = [];

      for (final entry in rates.entries) {
        final targetCurrencyCode = entry.key;
        final rateValue = entry.value;

        // Find the target currency
        final targetCurrency = Currency.fromCode(targetCurrencyCode);
        if (targetCurrency == null) {
          // Skip unsupported currencies
          continue;
        }

        // Create exchange rate from base currency to target
        final exchangeRate = ExchangeRate(
          baseCurrency: _apiBaseCurrency,
          targetCurrency: targetCurrency,
          rate: Decimal.parse(rateValue.toString()),
          timestamp: timestamp,
          expiresAt: expiresAt,
        );

        exchangeRates.add(exchangeRate);
      }

      // Store all rates in local cache
      await _localDataSource.batchStore(exchangeRates);
    } catch (e) {
      throw Exception('Failed to fetch exchange rates: $e');
    }
  }

  @override
  Future<Decimal> convert({
    required Decimal amount,
    required Currency from,
    required Currency to,
  }) async {
    // If same currency, no conversion needed
    if (from.code == to.code) {
      return amount;
    }

    // Get the exchange rate
    final rate = await _getExchangeRate(from: from, to: to);

    if (rate == null) {
      throw Exception(
        'Exchange rate not available for ${from.code} to ${to.code}. '
        'Please fetch rates first.',
      );
    }

    // Perform conversion with proper decimal precision
    final convertedAmount = amount * rate.rate;

    // Round to the target currency's decimal places
    return _roundToDecimalPlaces(convertedAmount, to.decimalPlaces);
  }

  @override
  Future<ExchangeRate?> getRate({
    required Currency from,
    required Currency to,
  }) async {
    return _getExchangeRate(from: from, to: to);
  }

  @override
  Future<DateTime?> getLastUpdateTime() async {
    return await _localDataSource.getLatestUpdateTime();
  }

  @override
  List<Currency> getSupportedCurrencies() {
    return Currency.majorCurrencies;
  }

  @override
  String formatAmount({
    required Decimal amount,
    required Currency currency,
    required String locale,
  }) {
    // Parse locale string (e.g., "en_US" -> Locale)
    final localeParts = locale.split('_');
    final languageCode = localeParts[0];
    final countryCode = localeParts.length > 1 ? localeParts[1] : null;

    // Create NumberFormat for the locale
    final NumberFormat formatter;
    
    if (countryCode != null) {
      formatter = NumberFormat.currency(
        locale: '${languageCode}_$countryCode',
        symbol: currency.symbol,
        decimalDigits: currency.decimalPlaces,
      );
    } else {
      formatter = NumberFormat.currency(
        locale: languageCode,
        symbol: currency.symbol,
        decimalDigits: currency.decimalPlaces,
      );
    }

    // Convert Decimal to double for formatting
    final doubleAmount = amount.toDouble();

    return formatter.format(doubleAmount);
  }

  @override
  Future<bool> needsRefresh() async {
    return await _localDataSource.needsRefresh();
  }

  /// Internal method to get exchange rate with fallback logic
  /// 
  /// This method tries to find a direct rate, or calculates via USD as intermediary
  Future<ExchangeRate?> _getExchangeRate({
    required Currency from,
    required Currency to,
  }) async {
    // Try to get direct rate from cache
    var rate = await _localDataSource.getValidRate(
      baseCurrency: from,
      targetCurrency: to,
    );

    if (rate != null) {
      return rate;
    }

    // Try inverse rate
    final inverseRate = await _localDataSource.getValidRate(
      baseCurrency: to,
      targetCurrency: from,
    );

    if (inverseRate != null) {
      return inverseRate.inverse;
    }

    // If no direct rate, try to calculate via USD as intermediary
    // This works because our API fetches all rates with USD as base
    if (from.code != _apiBaseCurrency.code && to.code != _apiBaseCurrency.code) {
      // Get from -> USD rate
      final fromToUsd = await _localDataSource.getValidRate(
        baseCurrency: _apiBaseCurrency,
        targetCurrency: from,
      );

      // Get USD -> to rate
      final usdToTarget = await _localDataSource.getValidRate(
        baseCurrency: _apiBaseCurrency,
        targetCurrency: to,
      );

      if (fromToUsd != null && usdToTarget != null) {
        // Calculate cross rate: from -> USD -> to
        // Rate = (1 / fromToUsd.rate) * usdToTarget.rate
        final crossRate = usdToTarget.rate / fromToUsd.rate;

        // Use the older timestamp and earlier expiry
        final timestamp = fromToUsd.timestamp.isBefore(usdToTarget.timestamp)
            ? fromToUsd.timestamp
            : usdToTarget.timestamp;

        final expiresAt = fromToUsd.expiresAt.isBefore(usdToTarget.expiresAt)
            ? fromToUsd.expiresAt
            : usdToTarget.expiresAt;

        return ExchangeRate(
          baseCurrency: from,
          targetCurrency: to,
          rate: Decimal.parse(crossRate.toString()),
          timestamp: timestamp,
          expiresAt: expiresAt,
        );
      }
    }

    // If from is USD, try to get USD -> to
    if (from.code == _apiBaseCurrency.code) {
      return await _localDataSource.getValidRate(
        baseCurrency: _apiBaseCurrency,
        targetCurrency: to,
      );
    }

    // If to is USD, try to get USD -> from and invert
    if (to.code == _apiBaseCurrency.code) {
      final usdToFrom = await _localDataSource.getValidRate(
        baseCurrency: _apiBaseCurrency,
        targetCurrency: from,
      );
      return usdToFrom?.inverse;
    }

    return null;
  }

  /// Round a Decimal to a specific number of decimal places
  Decimal _roundToDecimalPlaces(Decimal value, int decimalPlaces) {
    if (decimalPlaces == 0) {
      return Decimal.parse(value.round().toString());
    }

    // Use string manipulation to round to specific decimal places
    final stringValue = value.toString();
    final parts = stringValue.split('.');
    
    if (parts.length == 1) {
      // No decimal part, just return the value
      return value;
    }
    
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    if (decimalPart.length <= decimalPlaces) {
      // Already has fewer or equal decimal places
      return value;
    }
    
    // Round the decimal part
    final truncated = decimalPart.substring(0, decimalPlaces);
    final nextDigit = int.parse(decimalPart[decimalPlaces]);
    
    var roundedDecimal = int.parse(truncated);
    if (nextDigit >= 5) {
      roundedDecimal++;
    }
    
    final roundedString = '$integerPart.${roundedDecimal.toString().padLeft(decimalPlaces, '0')}';
    return Decimal.parse(roundedString);
  }
}
