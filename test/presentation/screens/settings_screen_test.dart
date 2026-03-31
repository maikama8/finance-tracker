import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/application/state/auth_provider.dart';
import 'package:personal_finance_tracker/presentation/screens/settings_screen.dart';
import 'package:personal_finance_tracker/domain/entities/user.dart';
import 'package:personal_finance_tracker/domain/services/auth_service.dart';
import 'package:personal_finance_tracker/domain/services/locale_service.dart';
import 'package:personal_finance_tracker/domain/services/sync_manager.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance_tracker/application/state/locale_provider.dart';

final _testUser = User(
  id: 'user-1',
  email: 'test@example.com',
  displayName: 'Test User',
  locale: Locale('en'),
  baseCurrency: Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    decimalPlaces: 2,
  ),
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

class _FakeAuthService implements AuthService {
  const _FakeAuthService();

  @override
  Stream<User?> get authStateChanges => Stream.value(_testUser);

  @override
  Future<AuthResult> sendOTP(String emailOrPhone) async {
    return AuthResult.failure('Not implemented in widget tests');
  }

  @override
  Future<AuthResult> signInWithFirebase(AuthProvider provider) async {
    return AuthResult.success(_testUser);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResult> verifyOTP(String emailOrPhone, String otp) async {
    return AuthResult.success(_testUser);
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
  Future<void> resolveConflict(
    Conflict conflict,
    ResolutionStrategy strategy,
  ) async {}

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

class _FakeLocaleService implements LocaleService {
  Locale _locale = const Locale('en');

  @override
  Locale getCurrentLocale() => _locale;

  @override
  TextDirection getTextDirection(Locale locale) {
    return isRTL(locale) ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  bool isRTL(Locale locale) => const {'ar', 'fa', 'he', 'ur'}.contains(locale.languageCode);

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
  String localeToString(Locale locale) {
    return locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
  }

  @override
  Locale parseLocaleString(String localeString) {
    final parts = localeString.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  @override
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
  }
}

void main() {
  setUp(() async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSettingsScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => const _FakeAuthService()),
          localeServiceProvider.overrideWith((ref) => _FakeLocaleService()),
          syncManagerProvider.overrideWith((ref) => _FakeSyncManager()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('SettingsScreen has correct app bar title',
      (WidgetTester tester) async {
    await pumpSettingsScreen(tester);

    // Verify app bar title
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays language section',
      (WidgetTester tester) async {
    await pumpSettingsScreen(tester);

    // Verify language section exists
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays base currency section',
      (WidgetTester tester) async {
    await pumpSettingsScreen(tester);

    await tester.scrollUntilVisible(
      find.text('USD (\$)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // Verify base currency section exists
    expect(find.text('Base Currency'), findsWidgets);
  });

  testWidgets('SettingsScreen displays notification preferences section',
      (WidgetTester tester) async {
    await pumpSettingsScreen(tester);

    await tester.scrollUntilVisible(
      find.text('Notifications'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // Verify notification section exists
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays sync status section',
      (WidgetTester tester) async {
    await pumpSettingsScreen(tester);

    await tester.scrollUntilVisible(
      find.text('Synchronization'),
      300,
      scrollable: find.byType(Scrollable),
    );

    // Verify sync section exists
    expect(find.text('Synchronization'), findsOneWidget);
    expect(find.text('Sync Status'), findsWidgets);
  });

  testWidgets('SettingsScreen displays account section',
      (WidgetTester tester) async {
    await pumpSettingsScreen(tester);

    await tester.scrollUntilVisible(
      find.text('Logout'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    // Verify account section exists
    expect(find.text('Account'), findsWidgets);
  });

  testWidgets('SettingsScreen displays category template section',
      (WidgetTester tester) async {
    await pumpSettingsScreen(tester);

    await tester.scrollUntilVisible(
      find.text('Category Template'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    // Verify category template section exists
    expect(find.text('Category Template'), findsWidgets);
  });
}
