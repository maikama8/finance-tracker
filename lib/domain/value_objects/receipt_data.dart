import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'currency.dart';

/// Value object representing data extracted from a receipt via OCR
class ReceiptData extends Equatable {
  final Decimal? amount;
  final DateTime? date;
  final String? merchantName;
  final Currency? currency;
  final double confidence; // OCR confidence score (0.0 - 1.0)

  const ReceiptData({
    this.amount,
    this.date,
    this.merchantName,
    this.currency,
    required this.confidence,
  });

  /// Check if the OCR extraction was successful (has at least amount)
  bool get isValid => amount != null;

  /// Check if the confidence is high enough to trust the data
  bool get isHighConfidence => confidence >= 0.7;

  /// Check if the extraction has all key fields
  bool get isComplete => amount != null && date != null && merchantName != null;

  @override
  List<Object?> get props => [
        amount,
        date,
        merchantName,
        currency,
        confidence,
      ];

  @override
  String toString() {
    return 'ReceiptData(amount: $amount, date: $date, merchant: $merchantName, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}
