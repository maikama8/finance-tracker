import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/application/state/auth_provider.dart';
import 'package:personal_finance_tracker/domain/entities/user.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/presentation/screens/add_edit_transaction_screen.dart';
import 'package:personal_finance_tracker/presentation/widgets/dashboard_empty_state.dart';

void main() {
  testWidgets('Add First Transaction navigates to the add transaction screen', (
    WidgetTester tester,
  ) async {
    final user = User(
      id: 'user-1',
      email: 'user@example.com',
      displayName: 'Test User',
      locale: Locale('en', 'US'),
      baseCurrency: Currency.USD,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUserProvider.overrideWith((ref) => user)],
        child: const MaterialApp(home: DashboardEmptyState()),
      ),
    );

    await tester.tap(find.text('Add First Transaction'));
    await tester.pumpAndSettle();

    expect(find.byType(AddEditTransactionScreen), findsOneWidget);
  });
}
