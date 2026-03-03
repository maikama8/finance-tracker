import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:personal_finance_tracker/application/use_cases/process_payment_contribution_use_case.dart';
import 'package:personal_finance_tracker/domain/entities/savings_goal.dart';
import 'package:personal_finance_tracker/domain/entities/transaction.dart';
import 'package:personal_finance_tracker/domain/repositories/transaction_repository.dart';
import 'package:personal_finance_tracker/domain/services/savings_goal_manager.dart';
import 'package:personal_finance_tracker/domain/services/payment_gateway_service.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/domain/value_objects/payment_provider.dart';
import 'package:personal_finance_tracker/domain/value_objects/payment_result.dart';

@GenerateMocks([
  PaymentGatewayService,
  SavingsGoalManager,
  TransactionRepository,
])
import 'process_payment_contribution_use_case_test.mocks.dart';

void main() {
  group('ProcessPaymentContributionUseCase', () {
    late ProcessPaymentContributionUseCase useCase;
    late MockPaymentGatewayService mockPaymentGateway;
    late MockSavingsGoalManager mockGoalManager;
    late MockTransactionRepository mockTransactionRepo;

    setUp(() {
      mockPaymentGateway = MockPaymentGatewayService();
      mockGoalManager = MockSavingsGoalManager();
      mockTransactionRepo = MockTransactionRepository();

      useCase = ProcessPaymentContributionUseCase(
        paymentGatewayService: mockPaymentGateway,
        savingsGoalManager: mockGoalManager,
        transactionRepository: mockTransactionRepo,
      );
    });

    group('execute', () {
      test('successfully processes payment contribution', () async {
        // Arrange
        const sessionId = 'session-123';
        const userId = 'user-123';
        const goalId = 'goal-123';
        const categoryId = 'category-123';
        final amount = Decimal.parse('100.00');

        final paymentResult = PaymentResult(
          reference: 'ref-123',
          status: PaymentStatus.success,
          amount: amount,
          currency: Currency.USD,
          provider: PaymentProvider.stripe,
          timestamp: DateTime.now(),
          transactionId: 'txn-123',
        );

        final updatedGoal = SavingsGoal(
          id: goalId,
          userId: userId,
          name: 'Vacation Fund',
          targetAmount: Decimal.parse('1000.00'),
          currency: Currency.USD,
          currentAmount: Decimal.parse('100.00'),
          deadline: DateTime.now().add(const Duration(days: 365)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final transaction = Transaction(
          id: 'txn-456',
          userId: userId,
          amount: amount,
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: categoryId,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockPaymentGateway.verifyPayment(sessionId))
            .thenAnswer((_) async => paymentResult);
        when(mockGoalManager.contribute(goalId, amount))
            .thenAnswer((_) async => updatedGoal);
        when(mockTransactionRepo.create(userId, any))
            .thenAnswer((_) async => transaction);

        // Act
        final result = await useCase.execute(
          sessionId: sessionId,
          userId: userId,
          savingsGoalId: goalId,
          categoryId: categoryId,
        );

        // Assert
        expect(result.updatedGoal, equals(updatedGoal));
        expect(result.transaction, equals(transaction));
        expect(result.paymentResult, equals(paymentResult));

        verify(mockPaymentGateway.verifyPayment(sessionId)).called(1);
        verify(mockGoalManager.contribute(goalId, amount)).called(1);
        verify(mockTransactionRepo.create(userId, any)).called(1);
      });

      test('throws exception when payment verification fails', () async {
        // Arrange
        const sessionId = 'session-123';
        const userId = 'user-123';
        const goalId = 'goal-123';
        const categoryId = 'category-123';

        final paymentResult = PaymentResult(
          reference: 'ref-123',
          status: PaymentStatus.failed,
          amount: Decimal.parse('100.00'),
          currency: Currency.USD,
          provider: PaymentProvider.stripe,
          timestamp: DateTime.now(),
          errorMessage: 'Payment declined',
        );

        when(mockPaymentGateway.verifyPayment(sessionId))
            .thenAnswer((_) async => paymentResult);

        // Act & Assert
        expect(
          () => useCase.execute(
            sessionId: sessionId,
            userId: userId,
            savingsGoalId: goalId,
            categoryId: categoryId,
          ),
          throwsException,
        );

        verify(mockPaymentGateway.verifyPayment(sessionId)).called(1);
        verifyNever(mockGoalManager.contribute(any, any));
        verifyNever(mockTransactionRepo.create(any, any));
      });

      test('creates transaction with correct details (Req 12.4)', () async {
        // Arrange
        const sessionId = 'session-123';
        const userId = 'user-123';
        const goalId = 'goal-123';
        const categoryId = 'category-123';
        final amount = Decimal.parse('250.50');

        final paymentResult = PaymentResult(
          reference: 'ref-123',
          status: PaymentStatus.success,
          amount: amount,
          currency: Currency.NGN,
          provider: PaymentProvider.paystack,
          timestamp: DateTime.now(),
          transactionId: 'txn-123',
        );

        final updatedGoal = SavingsGoal(
          id: goalId,
          userId: userId,
          name: 'Emergency Fund',
          targetAmount: Decimal.parse('500000.00'),
          currency: Currency.NGN,
          currentAmount: amount,
          deadline: DateTime.now().add(const Duration(days: 180)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockPaymentGateway.verifyPayment(sessionId))
            .thenAnswer((_) async => paymentResult);
        when(mockGoalManager.contribute(goalId, amount))
            .thenAnswer((_) async => updatedGoal);
        when(mockTransactionRepo.create(userId, any))
            .thenAnswer((_) async => Transaction(
                  id: 'txn-456',
                  userId: userId,
                  amount: amount,
                  currency: Currency.NGN,
                  type: TransactionType.expense,
                  categoryId: categoryId,
                  date: paymentResult.timestamp,
                  notes: 'Payment contribution to Emergency Fund via Paystack',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));

        // Act
        await useCase.execute(
          sessionId: sessionId,
          userId: userId,
          savingsGoalId: goalId,
          categoryId: categoryId,
        );

        // Assert
        final captured = verify(mockTransactionRepo.create(userId, captureAny))
            .captured
            .single as TransactionInput;

        expect(captured.amount, equals(amount));
        expect(captured.currencyCode, equals('NGN'));
        expect(captured.type, equals(TransactionType.expense));
        expect(captured.categoryId, equals(categoryId));
        expect(captured.notes, contains('Emergency Fund'));
        expect(captured.notes, contains('Paystack'));
      });
    });

    group('executeFromCallback', () {
      test('successfully processes payment from callback', () async {
        // Arrange
        const userId = 'user-123';
        const goalId = 'goal-123';
        const categoryId = 'category-123';
        final amount = Decimal.parse('150.00');

        final callbackData = {
          'reference': 'ref-123',
          'status': 'success',
          'transaction_id': 'txn-123',
        };

        final paymentResult = PaymentResult(
          reference: 'ref-123',
          status: PaymentStatus.success,
          amount: amount,
          currency: Currency.USD,
          provider: PaymentProvider.flutterwave,
          timestamp: DateTime.now(),
          transactionId: 'txn-123',
        );

        final updatedGoal = SavingsGoal(
          id: goalId,
          userId: userId,
          name: 'House Fund',
          targetAmount: Decimal.parse('5000.00'),
          currency: Currency.USD,
          currentAmount: amount,
          deadline: DateTime.now().add(const Duration(days: 730)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final transaction = Transaction(
          id: 'txn-456',
          userId: userId,
          amount: amount,
          currency: Currency.USD,
          type: TransactionType.expense,
          categoryId: categoryId,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockPaymentGateway.handleCallback(callbackData))
            .thenAnswer((_) async => paymentResult);
        when(mockGoalManager.contribute(goalId, amount))
            .thenAnswer((_) async => updatedGoal);
        when(mockTransactionRepo.create(userId, any))
            .thenAnswer((_) async => transaction);

        // Act
        final result = await useCase.executeFromCallback(
          callbackData: callbackData,
          userId: userId,
          savingsGoalId: goalId,
          categoryId: categoryId,
        );

        // Assert
        expect(result.updatedGoal, equals(updatedGoal));
        expect(result.transaction, equals(transaction));
        expect(result.paymentResult, equals(paymentResult));

        verify(mockPaymentGateway.handleCallback(callbackData)).called(1);
        verify(mockGoalManager.contribute(goalId, amount)).called(1);
        verify(mockTransactionRepo.create(userId, any)).called(1);
      });

      test('throws exception when callback indicates failure', () async {
        // Arrange
        const userId = 'user-123';
        const goalId = 'goal-123';
        const categoryId = 'category-123';

        final callbackData = {
          'reference': 'ref-123',
          'status': 'failed',
        };

        final paymentResult = PaymentResult(
          reference: 'ref-123',
          status: PaymentStatus.failed,
          amount: Decimal.parse('100.00'),
          currency: Currency.USD,
          provider: PaymentProvider.paypal,
          timestamp: DateTime.now(),
          errorMessage: 'Insufficient funds',
        );

        when(mockPaymentGateway.handleCallback(callbackData))
            .thenAnswer((_) async => paymentResult);

        // Act & Assert
        expect(
          () => useCase.executeFromCallback(
            callbackData: callbackData,
            userId: userId,
            savingsGoalId: goalId,
            categoryId: categoryId,
          ),
          throwsException,
        );

        verify(mockPaymentGateway.handleCallback(callbackData)).called(1);
        verifyNever(mockGoalManager.contribute(any, any));
        verifyNever(mockTransactionRepo.create(any, any));
      });
    });

    group('Requirements validation', () {
      test('updates goal balance on successful payment (Req 12.4)', () async {
        // Arrange
        const sessionId = 'session-123';
        const userId = 'user-123';
        const goalId = 'goal-123';
        const categoryId = 'category-123';
        final contributionAmount = Decimal.parse('100.00');

        final paymentResult = PaymentResult(
          reference: 'ref-123',
          status: PaymentStatus.success,
          amount: contributionAmount,
          currency: Currency.USD,
          provider: PaymentProvider.stripe,
          timestamp: DateTime.now(),
          transactionId: 'txn-123',
        );

        final updatedGoal = SavingsGoal(
          id: goalId,
          userId: userId,
          name: 'Test Goal',
          targetAmount: Decimal.parse('1000.00'),
          currency: Currency.USD,
          currentAmount: contributionAmount,
          deadline: DateTime.now().add(const Duration(days: 365)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockPaymentGateway.verifyPayment(sessionId))
            .thenAnswer((_) async => paymentResult);
        when(mockGoalManager.contribute(goalId, contributionAmount))
            .thenAnswer((_) async => updatedGoal);
        when(mockTransactionRepo.create(userId, any))
            .thenAnswer((_) async => Transaction(
                  id: 'txn-456',
                  userId: userId,
                  amount: contributionAmount,
                  currency: Currency.USD,
                  type: TransactionType.expense,
                  categoryId: categoryId,
                  date: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));

        // Act
        final result = await useCase.execute(
          sessionId: sessionId,
          userId: userId,
          savingsGoalId: goalId,
          categoryId: categoryId,
        );

        // Assert - Verify goal was updated with contribution
        verify(mockGoalManager.contribute(goalId, contributionAmount)).called(1);
        expect(result.updatedGoal.currentAmount, equals(contributionAmount));
      });

      test('creates transaction record for contribution (Req 12.4)', () async {
        // Arrange
        const sessionId = 'session-123';
        const userId = 'user-123';
        const goalId = 'goal-123';
        const categoryId = 'category-123';

        final paymentResult = PaymentResult(
          reference: 'ref-123',
          status: PaymentStatus.success,
          amount: Decimal.parse('100.00'),
          currency: Currency.USD,
          provider: PaymentProvider.stripe,
          timestamp: DateTime.now(),
          transactionId: 'txn-123',
        );

        when(mockPaymentGateway.verifyPayment(sessionId))
            .thenAnswer((_) async => paymentResult);
        when(mockGoalManager.contribute(goalId, any))
            .thenAnswer((_) async => SavingsGoal(
                  id: goalId,
                  userId: userId,
                  name: 'Test Goal',
                  targetAmount: Decimal.parse('1000.00'),
                  currency: Currency.USD,
                  currentAmount: Decimal.parse('100.00'),
                  deadline: DateTime.now().add(const Duration(days: 365)),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));
        when(mockTransactionRepo.create(userId, any))
            .thenAnswer((_) async => Transaction(
                  id: 'txn-456',
                  userId: userId,
                  amount: Decimal.parse('100.00'),
                  currency: Currency.USD,
                  type: TransactionType.expense,
                  categoryId: categoryId,
                  date: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ));

        // Act
        await useCase.execute(
          sessionId: sessionId,
          userId: userId,
          savingsGoalId: goalId,
          categoryId: categoryId,
        );

        // Assert - Verify transaction was created
        verify(mockTransactionRepo.create(userId, any)).called(1);
      });
    });
  });
}
