import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'currency.dart';
import 'payment_provider.dart';

/// Value object representing a payment request
class PaymentRequest extends Equatable {
  final String savingsGoalId;
  final Decimal amount;
  final Currency currency;
  final PaymentProvider provider;
  final String userId;
  final String userEmail;
  final Map<String, dynamic>? metadata;

  const PaymentRequest({
    required this.savingsGoalId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.userId,
    required this.userEmail,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        savingsGoalId,
        amount,
        currency,
        provider,
        userId,
        userEmail,
        metadata,
      ];

  @override
  String toString() {
    return 'PaymentRequest(goalId: $savingsGoalId, amount: $amount ${currency.code}, provider: ${provider.name})';
  }
}
