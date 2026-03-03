import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'currency.dart';
import 'payment_provider.dart';

/// Enum representing payment status
enum PaymentStatus {
  success,
  failed,
  pending,
  cancelled,
}

/// Value object representing the result of a payment verification
class PaymentResult extends Equatable {
  final String reference;
  final PaymentStatus status;
  final Decimal amount;
  final Currency currency;
  final PaymentProvider provider;
  final DateTime timestamp;
  final String? transactionId;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const PaymentResult({
    required this.reference,
    required this.status,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.timestamp,
    this.transactionId,
    this.errorMessage,
    this.metadata,
  });

  /// Check if payment was successful
  bool get isSuccessful => status == PaymentStatus.success;

  @override
  List<Object?> get props => [
        reference,
        status,
        amount,
        currency,
        provider,
        timestamp,
        transactionId,
        errorMessage,
        metadata,
      ];

  @override
  String toString() {
    return 'PaymentResult(reference: $reference, status: $status, amount: $amount ${currency.code})';
  }
}
