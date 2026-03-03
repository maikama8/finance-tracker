import 'package:hive/hive.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../domain/value_objects/exchange_rate.dart';
import 'hive_database.dart';

/// Local data source for ExchangeRate entities using Hive
class ExchangeRateLocalDataSource {
  final HiveDatabase _database;

  ExchangeRateLocalDataSource(this._database);

  /// Get the exchange rates box
  Box _getBox() => _database.getBox(HiveBoxNames.exchangeRates);

  /// Generate a unique key for an exchange rate
  String _generateKey(Currency baseCurrency, Currency targetCurrency) {
    return '${baseCurrency.code}_${targetCurrency.code}';
  }

  /// Store an exchange rate
  Future<ExchangeRate> store(ExchangeRate rate) async {
    final box = _getBox();
    final key = _generateKey(rate.baseCurrency, rate.targetCurrency);
    await box.put(key, rate);
    return rate;
  }

  /// Get an exchange rate between two currencies
  Future<ExchangeRate?> getRate({
    required Currency baseCurrency,
    required Currency targetCurrency,
  }) async {
    final box = _getBox();
    final key = _generateKey(baseCurrency, targetCurrency);
    return box.get(key) as ExchangeRate?;
  }

  /// Get a valid (non-expired) exchange rate
  Future<ExchangeRate?> getValidRate({
    required Currency baseCurrency,
    required Currency targetCurrency,
  }) async {
    final rate = await getRate(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
    );

    if (rate == null || rate.isExpired) {
      return null;
    }

    return rate;
  }

  /// Get all exchange rates for a base currency
  Future<List<ExchangeRate>> getRatesForBase(Currency baseCurrency) async {
    final box = _getBox();
    final allRates = box.values.cast<ExchangeRate>();

    return allRates
        .where((r) => r.baseCurrency.code == baseCurrency.code)
        .toList();
  }

  /// Get all valid (non-expired) rates for a base currency
  Future<List<ExchangeRate>> getValidRatesForBase(Currency baseCurrency) async {
    final rates = await getRatesForBase(baseCurrency);
    return rates.where((r) => r.isValid).toList();
  }

  /// Get all exchange rates
  Future<List<ExchangeRate>> getAll() async {
    final box = _getBox();
    return box.values.cast<ExchangeRate>().toList();
  }

  /// Get all valid (non-expired) exchange rates
  Future<List<ExchangeRate>> getAllValid() async {
    final allRates = await getAll();
    return allRates.where((r) => r.isValid).toList();
  }

  /// Get all expired exchange rates
  Future<List<ExchangeRate>> getAllExpired() async {
    final allRates = await getAll();
    return allRates.where((r) => r.isExpired).toList();
  }

  /// Check if a rate exists and is valid
  Future<bool> hasValidRate({
    required Currency baseCurrency,
    required Currency targetCurrency,
  }) async {
    final rate = await getValidRate(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
    );
    return rate != null;
  }

  /// Get the timestamp of the last update for a currency pair
  Future<DateTime?> getLastUpdateTime({
    required Currency baseCurrency,
    required Currency targetCurrency,
  }) async {
    final rate = await getRate(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
    );
    return rate?.timestamp;
  }

  /// Get the most recent update timestamp across all rates
  Future<DateTime?> getLatestUpdateTime() async {
    final allRates = await getAll();
    if (allRates.isEmpty) return null;

    return allRates
        .map((r) => r.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Delete an exchange rate
  Future<void> delete({
    required Currency baseCurrency,
    required Currency targetCurrency,
  }) async {
    final box = _getBox();
    final key = _generateKey(baseCurrency, targetCurrency);
    await box.delete(key);
  }

  /// Delete all expired exchange rates
  Future<int> deleteExpired() async {
    final expiredRates = await getAllExpired();
    int count = 0;

    for (final rate in expiredRates) {
      await delete(
        baseCurrency: rate.baseCurrency,
        targetCurrency: rate.targetCurrency,
      );
      count++;
    }

    return count;
  }

  /// Clear all exchange rates
  Future<void> clearAll() async {
    final box = _getBox();
    await box.clear();
  }

  /// Batch store multiple exchange rates
  Future<void> batchStore(List<ExchangeRate> rates) async {
    final box = _getBox();
    final Map<String, ExchangeRate> entries = {
      for (var r in rates)
        _generateKey(r.baseCurrency, r.targetCurrency): r
    };
    await box.putAll(entries);
  }

  /// Store rates for multiple target currencies from a single base
  Future<void> storeRatesForBase({
    required Currency baseCurrency,
    required Map<Currency, ExchangeRate> rates,
  }) async {
    await batchStore(rates.values.toList());
  }

  /// Get count of all exchange rates
  Future<int> getCount() async {
    final box = _getBox();
    return box.length;
  }

  /// Get count of valid exchange rates
  Future<int> getValidCount() async {
    final validRates = await getAllValid();
    return validRates.length;
  }

  /// Get count of expired exchange rates
  Future<int> getExpiredCount() async {
    final expiredRates = await getAllExpired();
    return expiredRates.length;
  }

  /// Watch all exchange rates (returns a stream)
  Stream<List<ExchangeRate>> watchAll() {
    final box = _getBox();

    return box.watch().asyncMap((_) async {
      return getAll();
    });
  }

  /// Watch a specific exchange rate (returns a stream)
  Stream<ExchangeRate?> watchRate({
    required Currency baseCurrency,
    required Currency targetCurrency,
  }) {
    final box = _getBox();
    final key = _generateKey(baseCurrency, targetCurrency);

    return box.watch(key: key).asyncMap((_) async {
      return getRate(
        baseCurrency: baseCurrency,
        targetCurrency: targetCurrency,
      );
    });
  }

  /// Check if cache needs refresh (all rates expired or no rates exist)
  Future<bool> needsRefresh() async {
    final validCount = await getValidCount();
    return validCount == 0;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final totalCount = await getCount();
    final validCount = await getValidCount();
    final expiredCount = await getExpiredCount();
    final lastUpdate = await getLatestUpdateTime();

    return {
      'total': totalCount,
      'valid': validCount,
      'expired': expiredCount,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'needsRefresh': validCount == 0,
    };
  }
}
