import 'package:equatable/equatable.dart';
import 'payment_provider.dart';

/// Value object representing a payment session
class PaymentSession extends Equatable {
  final String sessionId;
  final String paymentUrl;
  final PaymentProvider provider;
  final String reference;
  final DateTime expiresAt;
  final Map<String, dynamic>? additionalData;

  const PaymentSession({
    required this.sessionId,
    required this.paymentUrl,
    required this.provider,
    required this.reference,
    required this.expiresAt,
    this.additionalData,
  });

  /// Check if the session has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        sessionId,
        paymentUrl,
        provider,
        reference,
        expiresAt,
        additionalData,
      ];

  @override
  String toString() {
    return 'PaymentSession(id: $sessionId, provider: ${provider.name}, reference: $reference)';
  }
}
