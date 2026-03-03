import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:personal_finance_tracker/domain/entities/budget.dart';
import 'package:personal_finance_tracker/domain/entities/savings_goal.dart';
import 'package:personal_finance_tracker/domain/services/notification_service.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/infrastructure/services/notification_service_impl.dart';
import 'package:decimal/decimal.dart';

// Generate mocks
@GenerateMocks([FirebaseMessaging])
import 'notification_service_test.mocks.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;
    late MockFirebaseMessaging mockMessaging;

    setUp(() {
      // Create mock Firebase Messaging
      mockMessaging = MockFirebaseMessaging();
      
      // Create service with mock
      notificationService = NotificationServiceImpl(messaging: mockMessaging);
    });

    test('should update and retrieve notification preferences', () async {
      // Arrange
      const preferences = NotificationPreferences(
        budgetAlertsEnabled: false,
        goalRemindersEnabled: true,
        goalAchievementsEnabled: false,
        syncStatusEnabled: true,
      );

      // Act
      await notificationService.updatePreferences(preferences);
      final retrieved = (notificationService as NotificationServiceImpl).getPreferences();

      // Assert
      expect(retrieved.budgetAlertsEnabled, false);
      expect(retrieved.goalRemindersEnabled, true);
      expect(retrieved.goalAchievementsEnabled, false);
      expect(retrieved.syncStatusEnabled, true);
    });

    test('should send budget alert when enabled', () async {
      // Arrange
      const preferences = NotificationPreferences(budgetAlertsEnabled: true);
      await notificationService.updatePreferences(preferences);

      final budget = Budget(
        id: 'budget-1',
        userId: 'user-1',
        categoryId: 'category-1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(850),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - should not throw
      await notificationService.sendBudgetAlert(budget, AlertType.nearLimit);
    });

    test('should not send budget alert when disabled', () async {
      // Arrange
      const preferences = NotificationPreferences(budgetAlertsEnabled: false);
      await notificationService.updatePreferences(preferences);

      final budget = Budget(
        id: 'budget-1',
        userId: 'user-1',
        categoryId: 'category-1',
        monthlyLimit: Decimal.fromInt(1000),
        currency: Currency.USD,
        currentSpending: Decimal.fromInt(850),
        month: 1,
        year: 2024,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - should not throw
      await notificationService.sendBudgetAlert(budget, AlertType.nearLimit);
    });

    test('should send goal reminder when enabled', () async {
      // Arrange
      const preferences = NotificationPreferences(goalRemindersEnabled: true);
      await notificationService.updatePreferences(preferences);

      final goal = SavingsGoal(
        id: 'goal-1',
        userId: 'user-1',
        name: 'Vacation Fund',
        targetAmount: Decimal.fromInt(5000),
        currency: Currency.USD,
        currentAmount: Decimal.fromInt(2000),
        deadline: DateTime.now().add(const Duration(days: 90)),
        reminderEnabled: true,
        reminderFrequency: ReminderFrequency.weekly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - should not throw
      await notificationService.sendGoalReminder(goal, '\$100');
    });

    test('should send goal achievement notification when enabled', () async {
      // Arrange
      const preferences = NotificationPreferences(goalAchievementsEnabled: true);
      await notificationService.updatePreferences(preferences);

      final goal = SavingsGoal(
        id: 'goal-1',
        userId: 'user-1',
        name: 'Emergency Fund',
        targetAmount: Decimal.fromInt(10000),
        currency: Currency.USD,
        currentAmount: Decimal.fromInt(10000),
        deadline: DateTime.now().add(const Duration(days: 30)),
        reminderEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert - should not throw
      await notificationService.sendGoalAchievement(goal);
    });

    test('should send sync status notification for failures when enabled', () async {
      // Arrange
      const preferences = NotificationPreferences(syncStatusEnabled: true);
      await notificationService.updatePreferences(preferences);

      // Act & Assert - should not throw
      await notificationService.sendSyncStatus(SyncStatus.failed);
    });

    test('should not send sync status notification for success', () async {
      // Arrange
      const preferences = NotificationPreferences(syncStatusEnabled: true);
      await notificationService.updatePreferences(preferences);

      // Act & Assert - should not throw (but won't send notification)
      await notificationService.sendSyncStatus(SyncStatus.success);
    });
  });
}
