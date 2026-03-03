import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../domain/value_objects/payment_session.dart';
import '../../domain/value_objects/payment_result.dart';
import '../../application/use_cases/process_payment_contribution_use_case.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/savings_goal_provider.dart';
import 'payment_gateway_selection_screen.dart';

/// Provider for ProcessPaymentContributionUseCase
final processPaymentContributionUseCaseProvider = Provider<ProcessPaymentContributionUseCase>((ref) {
  final paymentGatewayService = ref.watch(paymentGatewayServiceProvider);
  final savingsGoalManager = ref.watch(savingsGoalManagerProvider);
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  
  return ProcessPaymentContributionUseCase(
    paymentGatewayService: paymentGatewayService,
    savingsGoalManager: savingsGoalManager,
    transactionRepository: transactionRepository,
  );
});

/// Screen for processing payment through payment gateway
class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final PaymentSession session;
  final String goalId;
  final Decimal amount;

  const PaymentProcessingScreen({
    super.key,
    required this.session,
    required this.goalId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends ConsumerState<PaymentProcessingScreen> {
  late WebViewController _webViewController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            // Check if payment is complete based on URL
            if (_isPaymentCompleteUrl(url)) {
              _verifyAndProcessPayment();
            }
          },
          onPageFinished: (url) {
            // Additional check on page finish
            if (_isPaymentCompleteUrl(url)) {
              _verifyAndProcessPayment();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.session.paymentUrl));
  }

  bool _isPaymentCompleteUrl(String url) {
    // Check for common payment completion patterns
    return url.contains('success') ||
        url.contains('complete') ||
        url.contains('callback') ||
        url.contains('return');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay with ${widget.session.provider.displayName}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isProcessing ? null : () => _cancelPayment(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Processing payment...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _verifyAndProcessPayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not logged in');
      }

      final useCase = ref.read(processPaymentContributionUseCaseProvider);

      // TODO: Get the appropriate category ID for savings contributions
      // For now, use a placeholder - this should be configured in the app
      const savingsContributionCategoryId = 'savings_contribution';

      // Process the payment contribution
      final result = await useCase.execute(
        sessionId: widget.session.sessionId,
        userId: user.id,
        savingsGoalId: widget.goalId,
        categoryId: savingsContributionCategoryId,
      );

      // Check if goal is achieved and trigger notification
      final monitor = ref.read(goalAchievementMonitorProvider);
      await monitor.checkGoal(widget.goalId);

      if (!mounted) return;

      // Show success and navigate back
      _showSuccessDialog(result.paymentResult);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);

      // Show error
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog(PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your contribution of ${result.currency.symbol}${result.amount} has been processed successfully.'),
            const SizedBox(height: 8),
            if (result.transactionId != null)
              Text(
                'Transaction ID: ${result.transactionId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Pop dialog
              Navigator.pop(context);
              // Pop payment screen
              Navigator.pop(context);
              // Pop gateway selection screen
              Navigator.pop(context);
              // Pop contribute dialog (if any)
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to gateway selection
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to gateway selection
              Navigator.pop(context); // Go back to goal detail
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _cancelPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to gateway selection
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
