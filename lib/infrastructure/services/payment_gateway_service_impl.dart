import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/payment_gateway_service.dart';
import '../../domain/value_objects/payment_provider.dart';
import '../../domain/value_objects/payment_request.dart';
import '../../domain/value_objects/payment_session.dart';
import '../../domain/value_objects/payment_result.dart';

/// Implementation of PaymentGatewayService
/// Supports multiple regional payment providers with test mode
class PaymentGatewayServiceImpl implements PaymentGatewayService {
  final bool testMode;
  final Map<String, String> _providerCredentials;
  final Uuid _uuid = const Uuid();
  
  // In-memory storage for sessions (in production, use proper storage)
  final Map<String, PaymentSession> _sessions = {};
  final Map<String, PaymentRequest> _sessionRequests = {};

  PaymentGatewayServiceImpl({
    this.testMode = false,
    Map<String, String>? providerCredentials,
  }) : _providerCredentials = providerCredentials ?? {};

  @override
  List<PaymentProvider> getAvailableProviders(Locale locale) {
    // Extract country code from locale (e.g., 'en_NG' -> 'NG')
    final countryCode = locale.countryCode?.toUpperCase() ?? '';
    
    // Filter providers based on regional availability
    final availableProviders = PaymentProvider.allProviders.where((provider) {
      return provider.isAvailableInRegion(countryCode);
    }).toList();

    // If no regional providers found, return global providers
    if (availableProviders.isEmpty) {
      return PaymentProvider.allProviders
          .where((provider) => provider.isGlobal)
          .toList();
    }

    return availableProviders;
  }

  @override
  Future<PaymentSession> initiatePayment(PaymentRequest request) async {
    // Generate unique reference and session ID
    final reference = _generateReference(request.provider);
    final sessionId = _uuid.v4();
    
    // Generate payment URL based on provider and test mode
    final paymentUrl = _generatePaymentUrl(
      provider: request.provider,
      reference: reference,
      amount: request.amount.toString(),
      currency: request.currency.code,
      email: request.userEmail,
    );

    // Create payment session (expires in 1 hour)
    final session = PaymentSession(
      sessionId: sessionId,
      paymentUrl: paymentUrl,
      provider: request.provider,
      reference: reference,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      additionalData: {
        'savingsGoalId': request.savingsGoalId,
        'userId': request.userId,
        'testMode': testMode,
      },
    );

    // Store session for later verification
    _sessions[sessionId] = session;
    _sessionRequests[sessionId] = request;

    return session;
  }

  @override
  Future<PaymentResult> verifyPayment(String sessionId) async {
    // Retrieve session
    final session = _sessions[sessionId];
    if (session == null) {
      throw Exception('Payment session not found: $sessionId');
    }

    // Check if session expired
    if (session.isExpired) {
      return PaymentResult(
        reference: session.reference,
        status: PaymentStatus.failed,
        amount: _sessionRequests[sessionId]!.amount,
        currency: _sessionRequests[sessionId]!.currency,
        provider: session.provider,
        timestamp: DateTime.now(),
        errorMessage: 'Payment session expired',
      );
    }

    // In test mode, simulate successful payment
    if (testMode) {
      return _simulateTestPayment(session, sessionId);
    }

    // In production, verify with actual payment provider API
    return _verifyWithProvider(session, sessionId);
  }

  @override
  Future<PaymentResult> handleCallback(Map<String, dynamic> callbackData) async {
    // Extract reference from callback
    final reference = callbackData['reference'] as String?;
    if (reference == null) {
      throw Exception('Missing reference in callback data');
    }

    // Find session by reference
    final sessionEntry = _sessions.entries.firstWhere(
      (entry) => entry.value.reference == reference,
      orElse: () => throw Exception('Session not found for reference: $reference'),
    );

    final sessionId = sessionEntry.key;
    final session = sessionEntry.value;
    final request = _sessionRequests[sessionId]!;

    // Parse callback status
    final status = _parseCallbackStatus(callbackData);
    
    return PaymentResult(
      reference: reference,
      status: status,
      amount: request.amount,
      currency: request.currency,
      provider: session.provider,
      timestamp: DateTime.now(),
      transactionId: callbackData['transaction_id'] as String?,
      metadata: callbackData,
    );
  }

  /// Generate payment reference based on provider
  String _generateReference(PaymentProvider provider) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = provider.name.substring(0, 3).toUpperCase();
    return '$prefix-$timestamp-${_uuid.v4().substring(0, 8)}';
  }

  /// Generate payment URL based on provider and test mode
  String _generatePaymentUrl({
    required PaymentProvider provider,
    required String reference,
    required String amount,
    required String currency,
    required String email,
  }) {
    final mode = testMode ? 'sandbox' : 'live';
    
    switch (provider.type) {
      case PaymentProviderType.paystack:
        return 'https://$mode.paystack.com/pay/$reference';
      
      case PaymentProviderType.flutterwave:
        return 'https://$mode.flutterwave.com/pay/$reference';
      
      case PaymentProviderType.stripe:
        return 'https://checkout.stripe.com/$mode/$reference';
      
      case PaymentProviderType.paypal:
        return 'https://www.$mode.paypal.com/checkoutnow?token=$reference';
      
      case PaymentProviderType.razorpay:
        return 'https://$mode.razorpay.com/checkout/$reference';
    }
  }

  /// Simulate test payment (always succeeds in test mode)
  PaymentResult _simulateTestPayment(PaymentSession session, String sessionId) {
    final request = _sessionRequests[sessionId]!;
    
    return PaymentResult(
      reference: session.reference,
      status: PaymentStatus.success,
      amount: request.amount,
      currency: request.currency,
      provider: session.provider,
      timestamp: DateTime.now(),
      transactionId: 'TEST-${_uuid.v4().substring(0, 8)}',
      metadata: {'testMode': true},
    );
  }

  /// Verify payment with actual provider (placeholder for production)
  Future<PaymentResult> _verifyWithProvider(
    PaymentSession session,
    String sessionId,
  ) async {
    final request = _sessionRequests[sessionId]!;
    
    // TODO: Implement actual API calls to payment providers
    // For now, return pending status
    return PaymentResult(
      reference: session.reference,
      status: PaymentStatus.pending,
      amount: request.amount,
      currency: request.currency,
      provider: session.provider,
      timestamp: DateTime.now(),
      errorMessage: 'Payment verification not yet implemented for production',
    );
  }

  /// Parse payment status from callback data
  PaymentStatus _parseCallbackStatus(Map<String, dynamic> callbackData) {
    final statusStr = (callbackData['status'] as String?)?.toLowerCase();
    
    switch (statusStr) {
      case 'success':
      case 'successful':
      case 'completed':
        return PaymentStatus.success;
      
      case 'failed':
      case 'error':
        return PaymentStatus.failed;
      
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      
      default:
        return PaymentStatus.pending;
    }
  }
}
