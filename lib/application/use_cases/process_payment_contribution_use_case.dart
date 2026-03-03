import 'package:decimal/decimal.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/services/savings_goal_manager.dart';
import '../../domain/services/payment_gateway_service.dart';
import '../../domain/value_objects/payment_result.dart';
import '../../domain/value_objects/currency.dart';

/// Result of processing a payment contribution
class PaymentContributionResult {
  final SavingsGoal updatedGoal;
  final Transaction transaction;
  final PaymentResult paymentResult;

  const PaymentContributionResult({
    required this.updatedGoal,
    required this.transaction,
    required this.paymentResult,
  });
}

/// Use case for processing payment contributions to savings goals
/// Handles the complete flow: verify payment -> update goal -> create transaction
class ProcessPaymentContributionUseCase {
  final PaymentGatewayService _paymentGatewayService;
  final SavingsGoalManager _savingsGoalManager;
  final TransactionRepository _transactionRepository;

  ProcessPaymentContributionUseCase({
    required PaymentGatewayService paymentGatewayService,
    required SavingsGoalManager savingsGoalManager,
    required TransactionRepository transactionRepository,
  })  : _paymentGatewayService = paymentGatewayService,
        _savingsGoalManager = savingsGoalManager,
        _transactionRepository = transactionRepository;

  /// Process a payment contribution after payment completion
  /// 1. Verify payment with payment gateway
  /// 2. Update savings goal balance
  /// 3. Create transaction record
  /// Returns PaymentContributionResult with updated goal and transaction
  /// Throws Exception if payment verification fails or goal not found
  Future<PaymentContributionResult> execute({
    required String sessionId,
    required String userId,
    required String savingsGoalId,
    required String categoryId,
  }) async {
    // Step 1: Verify payment
    final paymentResult = await _paymentGatewayService.verifyPayment(sessionId);

    // Check if payment was successful
    if (!paymentResult.isSuccessful) {
      throw Exception(
        'Payment verification failed: ${paymentResult.errorMessage ?? "Unknown error"}',
      );
    }

    // Step 2: Update savings goal balance
    final updatedGoal = await _savingsGoalManager.contribute(
      savingsGoalId,
      paymentResult.amount,
    );

    // Step 3: Create transaction record
    final transaction = await _transactionRepository.create(
      userId,
      TransactionInput(
        amount: paymentResult.amount,
        currencyCode: paymentResult.currency.code,
        type: TransactionType.expense, // Contribution is an expense
        categoryId: categoryId,
        date: paymentResult.timestamp,
        notes: 'Payment contribution to ${updatedGoal.name} via ${paymentResult.provider.displayName}',
        receiptImageId: null,
      ),
    );

    return PaymentContributionResult(
      updatedGoal: updatedGoal,
      transaction: transaction,
      paymentResult: paymentResult,
    );
  }

  /// Process payment callback from webhook
  /// Similar to execute but uses callback data instead of session verification
  Future<PaymentContributionResult> executeFromCallback({
    required Map<String, dynamic> callbackData,
    required String userId,
    required String savingsGoalId,
    required String categoryId,
  }) async {
    // Step 1: Handle callback and get payment result
    final paymentResult = await _paymentGatewayService.handleCallback(callbackData);

    // Check if payment was successful
    if (!paymentResult.isSuccessful) {
      throw Exception(
        'Payment callback indicates failure: ${paymentResult.errorMessage ?? "Unknown error"}',
      );
    }

    // Step 2: Update savings goal balance
    final updatedGoal = await _savingsGoalManager.contribute(
      savingsGoalId,
      paymentResult.amount,
    );

    // Step 3: Create transaction record
    final transaction = await _transactionRepository.create(
      userId,
      TransactionInput(
        amount: paymentResult.amount,
        currencyCode: paymentResult.currency.code,
        type: TransactionType.expense,
        categoryId: categoryId,
        date: paymentResult.timestamp,
        notes: 'Payment contribution to ${updatedGoal.name} via ${paymentResult.provider.displayName}',
        receiptImageId: null,
      ),
    );

    return PaymentContributionResult(
      updatedGoal: updatedGoal,
      transaction: transaction,
      paymentResult: paymentResult,
    );
  }
}
