import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance_tracker/application/state/locale_provider.dart';
import 'package:personal_finance_tracker/infrastructure/services/locale_service_impl.dart';

void main() {
  group('Dynamic Locale Switching Integration Tests', () {
    late SharedPreferences prefs;
    late LocaleServiceImpl localeService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localeService = LocaleServiceImpl(prefs: prefs);
    });

    test('locale changes persist across app restarts', () async {
      // Set locale to French
      await localeService.setLocale(const Locale('fr'));
      expect(localeService.getCurrentLocale().languageCode, 'fr');

      // Simulate app restart by creating new service instance
      final newService = LocaleServiceImpl(prefs: prefs);
      expect(newService.getCurrentLocale().languageCode, 'fr');
    });

    test('locale changes update text direction', () async {
      // Start with English (LTR)
      await localeService.setLocale(const Locale('en'));
      expect(localeService.getTextDirection(localeService.getCurrentLocale()), 
             TextDirection.ltr);

      // Switch to Arabic (RTL)
      await localeService.setLocale(const Locale('ar'));
      expect(localeService.getTextDirection(localeService.getCurrentLocale()), 
             TextDirection.rtl);

      // Switch back to English (LTR)
      await localeService.setLocale(const Locale('en'));
      expect(localeService.getTextDirection(localeService.getCurrentLocale()), 
             TextDirection.ltr);
    });

    test('supports all required locales', () async {
      final supportedLocales = localeService.getSupportedLocales();
      final requiredLanguages = ['en', 'fr', 'es', 'de', 'pt', 'ar', 'hi', 'zh'];

      for (final lang in requiredLanguages) {
        expect(
          supportedLocales.any((locale) => locale.languageCode == lang),
          true,
          reason: 'Locale $lang should be supported',
        );
      }
    });

    test('locale switching works without app restart', () async {
      // Test multiple locale switches
      final locales = [
        const Locale('en'),
        const Locale('fr'),
        const Locale('ar'),
        const Locale('zh'),
        const Locale('es'),
      ];

      for (final locale in locales) {
        await localeService.setLocale(locale);
        final current = localeService.getCurrentLocale();
        expect(current.languageCode, locale.languageCode);
      }
    });

    test('RTL locales are correctly identified', () async {
      final rtlLocales = [
        const Locale('ar'), // Arabic
        const Locale('he'), // Hebrew
        const Locale('fa'), // Persian
      ];

      for (final locale in rtlLocales) {
        await localeService.setLocale(locale);
        expect(
          localeService.isRTL(locale),
          true,
          reason: '${locale.languageCode} should be RTL',
        );
      }
    });

    test('LTR locales are correctly identified', () async {
      final ltrLocales = [
        const Locale('en'),
        const Locale('fr'),
        const Locale('es'),
        const Locale('de'),
        const Locale('pt'),
        const Locale('hi'),
        const Locale('zh'),
      ];

      for (final locale in ltrLocales) {
        await localeService.setLocale(locale);
        expect(
          localeService.isRTL(locale),
          false,
          reason: '${locale.languageCode} should be LTR',
        );
      }
    });

    test('LocaleNotifier updates state when locale changes', () async {
      final notifier = LocaleNotifier(localeService);

      // Initial locale should be English
      expect(notifier.state.languageCode, 'en');

      // Change to French
      await notifier.setLocale(const Locale('fr'));
      expect(notifier.state.languageCode, 'fr');

      // Change to Arabic
      await notifier.setLocale(const Locale('ar'));
      expect(notifier.state.languageCode, 'ar');
      expect(notifier.isRTL(), true);

      // Change back to English
      await notifier.setLocale(const Locale('en'));
      expect(notifier.state.languageCode, 'en');
      expect(notifier.isRTL(), false);
    });

    test('text direction updates when locale changes', () async {
      final notifier = LocaleNotifier(localeService);

      // Initial direction should be LTR (English)
      expect(notifier.getTextDirection(), TextDirection.ltr);

      // Change to Arabic (RTL)
      await notifier.setLocale(const Locale('ar'));
      expect(notifier.getTextDirection(), TextDirection.rtl);

      // Change to French (LTR)
      await notifier.setLocale(const Locale('fr'));
      expect(notifier.getTextDirection(), TextDirection.ltr);
    });

    test('locale changes are immediate', () async {
      final startTime = DateTime.now();
      
      await localeService.setLocale(const Locale('fr'));
      final locale = localeService.getCurrentLocale();
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(locale.languageCode, 'fr');
      expect(duration.inMilliseconds < 100, true, 
             reason: 'Locale change should be immediate (< 100ms)');
    });

    test('multiple rapid locale changes work correctly', () async {
      // Simulate rapid locale switching
      for (int i = 0; i < 10; i++) {
        await localeService.setLocale(const Locale('en'));
        await localeService.setLocale(const Locale('fr'));
        await localeService.setLocale(const Locale('ar'));
      }

      // Final locale should be Arabic
      expect(localeService.getCurrentLocale().languageCode, 'ar');
    });
  });
}
