import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/application/state/auth_provider.dart';
import 'package:personal_finance_tracker/application/state/budget_provider.dart';
import 'package:personal_finance_tracker/application/state/dashboard_provider.dart';
import 'package:personal_finance_tracker/application/state/locale_provider.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import 'package:personal_finance_tracker/domain/entities/budget.dart';
import 'package:personal_finance_tracker/domain/entities/category.dart';
import 'package:personal_finance_tracker/domain/entities/user.dart';
import 'package:personal_finance_tracker/domain/services/auth_service.dart';
import 'package:personal_finance_tracker/domain/services/budget_tracker.dart';
import 'package:personal_finance_tracker/domain/services/category_service.dart';
import 'package:personal_finance_tracker/domain/services/locale_service.dart';
import 'package:personal_finance_tracker/domain/services/sync_manager.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/presentation/screens/add_edit_transaction_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/budgets_list_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/dashboard_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/login_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _testUser = User(
  id: 'user-1',
  email: 'test@example.com',
  displayName: 'Test User',
  locale: const Locale('en'),
  baseCurrency: Currency.USD,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

class _FakeAuthService implements AuthService {
  const _FakeAuthService();

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResult> sendOTP(String emailOrPhone) async {
    return AuthResult.failure('Not implemented in test');
  }

  @override
  Future<AuthResult> signInWithFirebase(AuthProvider provider) async {
    return AuthResult.failure('Not implemented in test');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResult> verifyOTP(String emailOrPhone, String otp) async {
    return AuthResult.failure('Not implemented in test');
  }
}

class _FakeLocaleService implements LocaleService {
  Locale _locale = const Locale('en');

  @override
  Locale getCurrentLocale() => _locale;

  @override
  TextDirection getTextDirection(Locale locale) => TextDirection.ltr;

  @override
  bool isRTL(Locale locale) => false;

  @override
  List<Locale> getSupportedLocales() => const [
        Locale('en'),
        Locale('fr'),
        Locale('es'),
        Locale('de'),
        Locale('pt'),
        Locale('ar'),
        Locale('hi'),
        Locale('zh'),
      ];

  @override
  String localeToString(Locale locale) => locale.languageCode;

  @override
  Locale parseLocaleString(String localeString) => Locale(localeString);

  @override
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
  }
}

class _FakeBudgetTracker implements BudgetTracker {
  @override
  Future<Budget> create(String userId, BudgetInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Budget>> getAll(String userId) async => [];

  @override
  Future<BudgetStatus> getStatus(String budgetId) {
    throw UnimplementedError();
  }

  @override
  Future<void> resetMonthlyBudgets(String userId) async {}

  @override
  Future<Budget> update(String id, BudgetInput input) {
    throw UnimplementedError();
  }

  @override
  Stream<BudgetAlert> watchAlerts(String userId) => const Stream.empty();
}

class _FakeCategoryService implements CategoryService {
  @override
  Future<Category> createCustomCategory(String userId, CategoryInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCategory(String id, String reassignToCategoryId) async {}

  @override
  Future<List<Category>> getAllCategories(String userId) async => [];

  @override
  Future<List<Category>> getChildCategories(String parentCategoryId, String userId) async => [];

  @override
  Future<Category?> getCategoryById(String id) async => null;

  @override
  Future<CategoryHierarchy> getCategoryTree(String userId) async => const CategoryHierarchy({});

  @override
  Future<List<Category>> getDefaultCategories(Locale locale) async => [];

  @override
  Future<bool> hasTransactions(String categoryId) async => false;

  @override
  Future<Category> updateCategory(String id, CategoryInput input) {
    throw UnimplementedError();
  }
}

class _FakeSyncManager implements SyncManager {
  @override
  Stream<SyncStatus> get syncStatusStream => Stream.value(
        const SyncStatus(
          state: SyncState.idle,
          message: 'Idle',
        ),
      );

  @override
  Future<DateTime?> getLastSyncTime() async => null;

  @override
  Future<void> resolveConflict(Conflict conflict, ResolutionStrategy strategy) async {}

  @override
  Future<SyncResult> syncAll() async => SyncResult(
        success: true,
        itemsSynced: 0,
        conflicts: 0,
        failures: 0,
        timestamp: DateTime(2025, 1, 1),
      );

  @override
  Future<SyncResult> syncBudgets() => syncAll();

  @override
  Future<SyncResult> syncGoals() => syncAll();

  @override
  Future<SyncResult> syncTransactions() => syncAll();
}

ProviderScope _testScope({
  required Widget child,
  User? user,
  DashboardData? dashboardData,
}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWith((ref) => const _FakeAuthService()),
      localeServiceProvider.overrideWith((ref) => _FakeLocaleService()),
      currentUserProvider.overrideWith((ref) => user),
      budgetTrackerProvider.overrideWith((ref) => _FakeBudgetTracker()),
      categoryServiceProvider.overrideWith((ref) => _FakeCategoryService()),
      syncManagerProvider.overrideWith((ref) => _FakeSyncManager()),
      if (dashboardData != null)
        dashboardDataProvider.overrideWith((ref) async => dashboardData),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  final emptyDashboard = DashboardData(
    balance: Decimal.zero,
    spendingBreakdown: const {},
    activeGoals: const [],
    categories: const {},
    hasTransactions: false,
  );

  group('Cross-Platform UI Consistency Tests', () {
    testWidgets('Dashboard screen renders current empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _testScope(
          child: const DashboardScreen(),
          user: _testUser,
          dashboardData: emptyDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('No Transactions Yet'), findsOneWidget);
      expect(find.text('Add First Transaction'), findsOneWidget);
    });

    testWidgets('Login screen renders current auth layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _testScope(
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Finance Tracker'), findsOneWidget);
      expect(find.text('Manage your finances securely'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Transaction form renders for authenticated user',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _testScope(
          child: const AddEditTransactionScreen(),
          user: _testUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsWidgets);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Select Category'), findsOneWidget);
    });

    testWidgets('Budget list screen renders current empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _testScope(
          child: const BudgetsListScreen(),
          user: _testUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('No Budgets Yet'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('Settings screen renders current sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _testScope(
          child: const SettingsScreen(),
          user: _testUser,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('USD (\$)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Base Currency'), findsWidgets);
    });

    testWidgets('Responsive dashboard renders on phone and tablet sizes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _testScope(
          child: const DashboardScreen(),
          user: _testUser,
          dashboardData: emptyDashboard,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      tester.view.physicalSize = const Size(1536, 2048);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        _testScope(
          child: const DashboardScreen(),
          user: _testUser,
          dashboardData: emptyDashboard,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  group('Platform-Specific Navigation Tests', () {
    testWidgets('AppBar back button works in a Material navigation stack',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Home')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Detail')),
                          body: const Text('Detail Screen'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Detail'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Screen'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Modal bottom sheets work consistently across platforms',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Bottom Sheet')),
                    ),
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Bottom Sheet'), findsOneWidget);
    });

    testWidgets('Dialogs and snackbars render consistently',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
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
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test Snackbar')),
                      );
                    },
                    child: const Text('Show Snackbar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Test Dialog'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Snackbar'));
      await tester.pump();
      expect(find.text('Test Snackbar'), findsOneWidget);
    });
  });
}
