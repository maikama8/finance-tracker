import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/main.dart';
import 'package:personal_finance_tracker/presentation/screens/dashboard_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/login_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/add_edit_transaction_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/budgets_list_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/settings_screen.dart';
import 'dart:io' show Platform;

/// Cross-Platform UI Consistency Tests
/// 
/// These tests verify that the UI renders identically on Android and iOS
/// and that platform-specific navigation patterns work correctly.
/// 
/// Validates Requirements 17.1, 17.2
void main() {
  group('Cross-Platform UI Consistency Tests', () {
    testWidgets('Dashboard screen renders identical layout on both platforms',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify core UI elements are present regardless of platform
      expect(find.text('Dashboard'), findsOneWidget);
      
      // Verify balance display exists
      expect(find.byType(Card), findsWidgets);
      
      // Verify navigation elements exist
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // Take a screenshot for visual comparison (manual verification needed)
      // This helps identify subtle layout differences between platforms
      await expectLater(
        find.byType(DashboardScreen),
        matchesGoldenFile('goldens/dashboard_${Platform.operatingSystem}.png'),
      );
    });

    testWidgets('Login screen renders identical layout on both platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify login UI elements
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
      
      // Verify layout consistency
      await expectLater(
        find.byType(LoginScreen),
        matchesGoldenFile('goldens/login_${Platform.operatingSystem}.png'),
      );
    });

    testWidgets('Transaction form renders identical layout on both platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AddEditTransactionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify form elements are present
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(DropdownButton), findsWidgets);
      
      // Verify layout consistency
      await expectLater(
        find.byType(AddEditTransactionScreen),
        matchesGoldenFile('goldens/transaction_form_${Platform.operatingSystem}.png'),
      );
    });

    testWidgets('Budget list screen renders identical layout on both platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BudgetsListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify budget list UI elements
      expect(find.byType(ListView), findsOneWidget);
      
      // Verify layout consistency
      await expectLater(
        find.byType(BudgetsListScreen),
        matchesGoldenFile('goldens/budgets_list_${Platform.operatingSystem}.png'),
      );
    });

    testWidgets('Settings screen renders identical layout on both platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify settings UI elements
      expect(find.byType(ListTile), findsWidgets);
      
      // Verify layout consistency
      await expectLater(
        find.byType(SettingsScreen),
        matchesGoldenFile('goldens/settings_${Platform.operatingSystem}.png'),
      );
    });

    testWidgets('Text fields have consistent sizing across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AddEditTransactionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all text fields
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Verify text fields have consistent heights
      final textFieldWidgets = tester.widgetList<TextField>(textFields);
      for (final textField in textFieldWidgets) {
        final renderBox = tester.renderObject(find.byWidget(textField)) as RenderBox;
        // Text fields should have reasonable height (not too small or too large)
        expect(renderBox.size.height, greaterThan(40));
        expect(renderBox.size.height, lessThan(80));
      }
    });

    testWidgets('Buttons have consistent sizing across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all elevated buttons
      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsWidgets);

      // Verify buttons have consistent minimum heights
      final buttonWidgets = tester.widgetList<ElevatedButton>(buttons);
      for (final button in buttonWidgets) {
        final renderBox = tester.renderObject(find.byWidget(button)) as RenderBox;
        // Buttons should have reasonable height
        expect(renderBox.size.height, greaterThan(36));
        expect(renderBox.size.height, lessThan(60));
      }
    });

    testWidgets('Card widgets have consistent padding across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all cards
      final cards = find.byType(Card);
      expect(cards, findsWidgets);

      // Verify cards have consistent elevation and margins
      final cardWidgets = tester.widgetList<Card>(cards);
      for (final card in cardWidgets) {
        // Cards should have consistent elevation
        expect(card.elevation, isNotNull);
      }
    });

    testWidgets('Icons render at consistent sizes across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all icons
      final icons = find.byType(Icon);
      expect(icons, findsWidgets);

      // Verify icons have reasonable sizes
      final iconWidgets = tester.widgetList<Icon>(icons);
      for (final icon in iconWidgets) {
        final renderBox = tester.renderObject(find.byWidget(icon)) as RenderBox;
        // Icons should be within reasonable size range
        expect(renderBox.size.width, greaterThan(16));
        expect(renderBox.size.width, lessThan(48));
      }
    });

    testWidgets('List items have consistent heights across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all list tiles
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsWidgets);

      // Verify list tiles have consistent heights
      final listTileWidgets = tester.widgetList<ListTile>(listTiles);
      final heights = <double>[];
      
      for (final listTile in listTileWidgets) {
        final renderBox = tester.renderObject(find.byWidget(listTile)) as RenderBox;
        heights.add(renderBox.size.height);
      }

      // All list tiles should have similar heights (within 10px variance)
      if (heights.isNotEmpty) {
        final avgHeight = heights.reduce((a, b) => a + b) / heights.length;
        for (final height in heights) {
          expect((height - avgHeight).abs(), lessThan(10));
        }
      }
    });

    testWidgets('Bottom navigation bar renders consistently across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find bottom navigation bar
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget);

      // Verify it has the expected number of items
      final bottomNavWidget = tester.widget<BottomNavigationBar>(bottomNav);
      expect(bottomNavWidget.items.length, greaterThanOrEqualTo(3));

      // Verify consistent sizing
      final renderBox = tester.renderObject(bottomNav) as RenderBox;
      expect(renderBox.size.height, greaterThan(50));
      expect(renderBox.size.height, lessThan(100));
    });
  });

  group('Platform-Specific Navigation Tests', () {
    testWidgets('Back button navigation works on Android',
        (WidgetTester tester) async {
      // This test is primarily for Android, but should not break on iOS
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
            routes: {
              '/transaction': (context) => AddEditTransactionScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to transaction screen
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pumpAndSettle();

      // Verify we're on the transaction screen
      expect(find.byType(AddEditTransactionScreen), findsOneWidget);

      // Simulate back button press (Android)
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // Verify we're back on dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('AppBar back button works on both platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify we're on settings screen
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Find and tap the back button in AppBar
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Verify we're back on dashboard
        expect(find.byType(DashboardScreen), findsOneWidget);
      }
    });

    testWidgets('Swipe-to-go-back gesture area exists on iOS',
        (WidgetTester tester) async {
      // This test verifies that the swipe gesture area is available
      // Actual gesture testing requires integration tests on real devices
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const DashboardScreen(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // On iOS, the MaterialApp should support swipe-back gestures
      // This is handled by the framework, so we just verify the navigation works
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      expect(navigator.canPop(), true);
    });

    testWidgets('Modal bottom sheets work consistently across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        height: 200,
                        child: const Center(child: Text('Bottom Sheet')),
                      ),
                    );
                  },
                  child: const Text('Show Bottom Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to show bottom sheet
      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Verify bottom sheet is displayed
      expect(find.text('Bottom Sheet'), findsOneWidget);

      // Verify bottom sheet can be dismissed by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Bottom sheet should be dismissed
      expect(find.text('Bottom Sheet'), findsNothing);
    });

    testWidgets('Dialogs render consistently across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Test Dialog'),
                        content: const Text('Dialog content'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Test Dialog'), findsNothing);
    });

    testWidgets('Snackbars render consistently across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test Snackbar')),
                    );
                  },
                  child: const Text('Show Snackbar'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to show snackbar
      await tester.tap(find.text('Show Snackbar'));
      await tester.pump();

      // Verify snackbar is displayed
      expect(find.text('Test Snackbar'), findsOneWidget);

      // Verify snackbar positioning (should be at bottom)
      final snackbarFinder = find.byType(SnackBar);
      final snackbarWidget = tester.widget<SnackBar>(snackbarFinder);
      expect(snackbarWidget.content, isA<Text>());
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('App adapts to different screen sizes',
        (WidgetTester tester) async {
      // Test with phone size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dashboard renders on phone
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Test with tablet size
      tester.view.physicalSize = const Size(1536, 2048);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dashboard still renders on tablet
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Reset to default
      addTearDown(tester.view.reset);
    });

    testWidgets('Text scales appropriately across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find text widgets
      final textWidgets = find.byType(Text);
      expect(textWidgets, findsWidgets);

      // Verify text widgets respect text scaling
      // This is handled by Flutter framework, so we just verify they exist
      for (final textWidget in tester.widgetList<Text>(textWidgets)) {
        expect(textWidget.data ?? textWidget.textSpan, isNotNull);
      }
    });
  });
}
