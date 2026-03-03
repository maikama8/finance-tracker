import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/presentation/screens/budgets_list_screen.dart';

void main() {
  testWidgets('BudgetsListScreen shows login prompt when user is null',
      (WidgetTester tester) async {
    // Build the widget wrapped in ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BudgetsListScreen(),
        ),
      ),
    );

    // Wait for the widget to build
    await tester.pump();

    // Verify that the login prompt is shown
    expect(find.text('Please log in to view budgets'), findsOneWidget);
  });

  testWidgets('BudgetsListScreen has correct app bar title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BudgetsListScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify app bar title
    expect(find.text('Budgets'), findsOneWidget);
  });

  testWidgets('BudgetsListScreen has add button in app bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BudgetsListScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify add button exists
    expect(find.byIcon(Icons.add), findsWidgets);
  });
}
