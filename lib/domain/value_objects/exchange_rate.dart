import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'currency.dart';

/// Value object representing an exchange rate between two currencies
class ExchangeRate extends Equatable {
  final Currency baseCurrency;
  final Currency targetCurrency;
  final Decimal rate;
  final DateTime timestamp;
  final DateTime expiresAt;

  const ExchangeRate({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.rate,
    required this.timestamp,
    required this.expiresAt,
  });

  /// Check if this exchange rate has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if this exchange rate is still valid
  bool get isValid => !isExpired;

  /// Convert an amount using this exchange rate
  Decimal convert(Decimal amount) {
    return Decimal.parse((amount * rate).toString());
  }

  /// Get the inverse exchange rate (swap base and target currencies)
  ExchangeRate get inverse {
    final inverseRate = Decimal.one / rate;
    return ExchangeRate(
      baseCurrency: targetCurrency,
      targetCurrency: baseCurrency,
      rate: Decimal.parse(inverseRate.toString()),
      timestamp: timestamp,
      expiresAt: expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        baseCurrency,
        targetCurrency,
        rate,
        timestamp,
        expiresAt,
      ];

  @override
  String toString() {
    return 'ExchangeRate(${baseCurrency.code} -> ${targetCurrency.code}: $rate, expires: $expiresAt)';
  }
}
