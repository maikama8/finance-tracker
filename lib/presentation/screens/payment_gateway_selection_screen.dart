import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../domain/value_objects/payment_provider.dart';
import '../../domain/value_objects/payment_request.dart';
import '../../domain/value_objects/payment_session.dart';
import '../../domain/services/payment_gateway_service.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/savings_goal_provider.dart';
import 'payment_processing_screen.dart';

/// Provider for PaymentGatewayService
final paymentGatewayServiceProvider = Provider<PaymentGatewayService>((ref) {
  // Import the implementation
  return ref.watch(paymentGatewayServiceImplProvider);
});

/// Screen for selecting a payment gateway provider
class PaymentGatewaySelectionScreen extends ConsumerWidget {
  final String goalId;
  final Decimal amount;
  final String goalName;

  const PaymentGatewaySelectionScreen({
    super.key,
    required this.goalId,
    required this.amount,
    required this.goalName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final paymentGatewayService = ref.watch(paymentGatewayServiceProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to make a contribution')),
      );
    }

    final availableProviders = paymentGatewayService.getAvailableProviders(user.locale);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: Column(
        children: [
          // Amount Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.blue[50],
            child: Column(
              children: [
                Text(
                  'Contributing to',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goalName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: ${user.baseCurrency.symbol}${amount.toString()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // Payment Providers List
          Expanded(
            child: availableProviders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No payment providers available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'for your region',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availableProviders.length,
                    itemBuilder: (context, index) {
                      final provider = availableProviders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            _getProviderIcon(provider.type),
                            size: 32,
                            color: Colors.blue,
                          ),
                          title: Text(
                            provider.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(provider.description),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _initiatePayment(
                            context,
                            ref,
                            provider,
                            user.id,
                            user.email,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getProviderIcon(PaymentProviderType type) {
    switch (type) {
      case PaymentProviderType.paystack:
      case PaymentProviderType.flutterwave:
        return Icons.account_balance;
      case PaymentProviderType.stripe:
        return Icons.credit_card;
      case PaymentProviderType.paypal:
        return Icons.payment;
      case PaymentProviderType.razorpay:
        return Icons.account_balance_wallet;
    }
  }

  Future<void> _initiatePayment(
    BuildContext context,
    WidgetRef ref,
    PaymentProvider provider,
    String userId,
    String userEmail,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final paymentGatewayService = ref.read(paymentGatewayServiceProvider);
      final user = ref.read(currentUserProvider);

      // Create payment request
      final request = PaymentRequest(
        userId: userId,
        savingsGoalId: goalId,
        amount: amount,
        currency: user!.baseCurrency,
        provider: provider,
        userEmail: userEmail,
      );

      // Initiate payment session
      final session = await paymentGatewayService.initiatePayment(request);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to payment processing screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentProcessingScreen(
            session: session,
            goalId: goalId,
            amount: amount,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog if open
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initiating payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
