import 'package:flutter/material.dart';
import '../value_objects/payment_provider.dart';
import '../value_objects/payment_request.dart';
import '../value_objects/payment_session.dart';
import '../value_objects/payment_result.dart';

/// Abstract service for payment gateway operations
abstract class PaymentGatewayService {
  /// Get available payment providers based on user's locale
  /// Returns providers that support the user's region
  List<PaymentProvider> getAvailableProviders(Locale locale);

  /// Initiate a payment session for a savings goal contribution
  /// Returns a PaymentSession with payment URL and session details
  Future<PaymentSession> initiatePayment(PaymentRequest request);

  /// Verify payment completion and get the result
  /// Returns PaymentResult with status and transaction details
  Future<PaymentResult> verifyPayment(String sessionId);

  /// Handle payment callback/webhook from payment provider
  /// Processes callback data and returns payment result
  Future<PaymentResult> handleCallback(Map<String, dynamic> callbackData);
}
