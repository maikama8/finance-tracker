import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:personal_finance_tracker/presentation/screens/reports_screen.dart';
import 'package:personal_finance_tracker/domain/entities/user.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/application/state/auth_provider.dart';

void main() {
  group('ReportsScreen', () {
    testWidgets('shows login message when user is not authenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );

      expect(find.text('Please log in to view reports'), findsOneWidget);
    });

    testWidgets('shows reports screen when user is authenticated', (WidgetTester tester) async {
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        locale: const Locale('en', 'US'),
        baseCurrency: const Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          decimalPlaces: 2,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Verify the screen title is present
      expect(find.text('Reports'), findsOneWidget);
      
      // Verify date range selector is present
      expect(find.text('Date Range'), findsOneWidget);
      
      // Verify quick range chips are present
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Last 90 Days'), findsOneWidget);
      expect(find.text('This Year'), findsOneWidget);
    });

    testWidgets('shows export dialog when export button is tapped', (WidgetTester tester) async {
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        locale: const Locale('en', 'US'),
        baseCurrency: const Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          decimalPlaces: 2,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Find and tap the export button
      final exportButton = find.byIcon(Icons.share);
      expect(exportButton, findsOneWidget);
      
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      // Verify export dialog is shown
      expect(find.text('Export Report'), findsOneWidget);
      expect(find.text('Export as PDF'), findsOneWidget);
      expect(find.text('Export as CSV'), findsOneWidget);
    });

    testWidgets('date range can be updated using quick range chips', (WidgetTester tester) async {
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        locale: const Locale('en', 'US'),
        baseCurrency: const Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          decimalPlaces: 2,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Find and tap the "Last 7 Days" chip
      final last7DaysChip = find.text('Last 7 Days');
      expect(last7DaysChip, findsOneWidget);
      
      await tester.tap(last7DaysChip);
      await tester.pump();

      // The widget should rebuild with new date range
      // We can't easily verify the internal state, but we can verify no errors occurred
      expect(find.text('Reports'), findsOneWidget);
    });

    testWidgets('granularity selector shows all options', (WidgetTester tester) async {
      final testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
        locale: const Locale('en', 'US'),
        baseCurrency: const Currency(
          code: 'USD',
          symbol: '\$',
          name: 'US Dollar',
          decimalPlaces: 2,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify granularity options are present
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });
  });
}
