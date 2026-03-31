import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/application/state/auth_provider.dart';
import 'package:personal_finance_tracker/application/state/locale_provider.dart';
import 'package:personal_finance_tracker/domain/entities/user.dart';
import 'package:personal_finance_tracker/domain/services/auth_service.dart';
import 'package:personal_finance_tracker/domain/services/locale_service.dart';
import 'package:personal_finance_tracker/main.dart';

class _FakeAuthService implements AuthService {
  const _FakeAuthService();

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResult> sendOTP(String emailOrPhone) async {
    return AuthResult.failure('Not implemented in widget test');
  }

  @override
  Future<AuthResult> signInWithFirebase(AuthProvider provider) async {
    return AuthResult.failure('Not implemented in widget test');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResult> verifyOTP(String emailOrPhone, String otp) async {
    return AuthResult.failure('Not implemented in widget test');
  }
}

class _FakeLocaleService implements LocaleService {
  @override
  Locale getCurrentLocale() => const Locale('en');

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
  Future<void> setLocale(Locale locale) async {}
}

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => const _FakeAuthService()),
          localeServiceProvider.overrideWith((ref) => _FakeLocaleService()),
        ],
        child: const PersonalFinanceTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Personal Finance Tracker'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    expect(find.text('Manage your finances securely'), findsOneWidget);
  });
}
