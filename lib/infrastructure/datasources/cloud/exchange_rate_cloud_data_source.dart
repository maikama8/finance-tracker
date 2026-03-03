import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../../../domain/value_objects/currency.dart';
import '../../../domain/value_objects/exchange_rate.dart';

/// Cloud data source for ExchangeRate entities using Firebase Firestore
/// This is primarily a read-only data source as exchange rates are typically
/// fetched from external APIs and cached
class ExchangeRateCloudDataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'exchange_rates';

  ExchangeRateCloudDataSource(this._firestore);

  /// Get the exchange rates collection reference
  CollectionReference get _collection => _firestore.collection(_collectionName);

  /// Get an exchange rate by base and target currency
  Future<ExchangeRate?> getRate({
    required Currency baseCurrency,
    required Currency targetCurrency,
  }) async {
    final docId = _getRateDocId(baseCurrency.code, targetCurrency.code);
    final doc = await _collection.doc(docId).get();
    
    if (!doc.exists) {
      return null;
    }
    
    return _fromFirestore(doc);
  }

  /// Get all exchange rates for a base currency
  Future<List<ExchangeRate>> getRatesForBase({
    required Currency baseCurrency,
  }) async {
    final snapshot = await _collection
        .where('baseCurrencyCode', isEqualTo: baseCurrency.code)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get all valid (non-expired) exchange rates
  Future<List<ExchangeRate>> getValidRates() async {
    final now = Timestamp.fromDate(DateTime.now());
    
    final snapshot = await _collection
        .where('expiresAt', isGreaterThan: now)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Get all exchange rates (including expired ones)
  Future<List<ExchangeRate>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  /// Store or update an exchange rate
  Future<ExchangeRate> upsert(ExchangeRate rate) async {
    final docId = _getRateDocId(rate.baseCurrency.code, rate.targetCurrency.code);
    final data = _toFirestore(rate);
    await _collection.doc(docId).set(data, SetOptions(merge: true));
    return rate;
  }

  /// Batch store multiple exchange rates
  Future<void> batchUpsert(List<ExchangeRate> rates) async {
    final batch = _firestore.batch();
    for (final rate in rates) {
      final docId = _getRateDocId(rate.baseCurrency.code, rate.targetCurrency.code);
      final docRef = _collection.doc(docId);
      batch.set(docRef, _toFirestore(rate), SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Delete an exchange rate
  Future<void> delete({
    required Currency baseCurrency,
    required Currency targetCurrency,
  }) async {
    final docId = _getRateDocId(baseCurrency.code, targetCurrency.code);
    await _collection.doc(docId).delete();
  }

  /// Delete all expired exchange rates
  Future<void> deleteExpired() async {
    final now = Timestamp.fromDate(DateTime.now());
    
    final snapshot = await _collection
        .where('expiresAt', isLessThanOrEqualTo: now)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Get the last update timestamp for exchange rates
  Future<DateTime?> getLastUpdateTime() async {
    final snapshot = await _collection
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    return (data['timestamp'] as Timestamp).toDate();
  }

  /// Generate a document ID from currency codes
  String _getRateDocId(String baseCode, String targetCode) {
    return '${baseCode}_$targetCode';
  }

  /// Convert ExchangeRate to Firestore document
  Map<String, dynamic> _toFirestore(ExchangeRate rate) {
    return {
      'baseCurrencyCode': rate.baseCurrency.code,
      'baseCurrency': {
        'code': rate.baseCurrency.code,
        'symbol': rate.baseCurrency.symbol,
        'name': rate.baseCurrency.name,
        'decimalPlaces': rate.baseCurrency.decimalPlaces,
      },
      'targetCurrencyCode': rate.targetCurrency.code,
      'targetCurrency': {
        'code': rate.targetCurrency.code,
        'symbol': rate.targetCurrency.symbol,
        'name': rate.targetCurrency.name,
        'decimalPlaces': rate.targetCurrency.decimalPlaces,
      },
      'rate': rate.rate.toString(),
      'timestamp': Timestamp.fromDate(rate.timestamp),
      'expiresAt': Timestamp.fromDate(rate.expiresAt),
    };
  }

  /// Convert Firestore document to ExchangeRate
  ExchangeRate _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final baseCurrencyData = data['baseCurrency'] as Map<String, dynamic>;
    final targetCurrencyData = data['targetCurrency'] as Map<String, dynamic>;

    return ExchangeRate(
      baseCurrency: Currency(
        code: baseCurrencyData['code'] as String,
        symbol: baseCurrencyData['symbol'] as String,
        name: baseCurrencyData['name'] as String,
        decimalPlaces: baseCurrencyData['decimalPlaces'] as int,
      ),
      targetCurrency: Currency(
        code: targetCurrencyData['code'] as String,
        symbol: targetCurrencyData['symbol'] as String,
        name: targetCurrencyData['name'] as String,
        decimalPlaces: targetCurrencyData['decimalPlaces'] as int,
      ),
      rate: Decimal.parse(data['rate'] as String),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }
}
