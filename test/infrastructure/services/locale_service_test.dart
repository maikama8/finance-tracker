import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance_tracker/infrastructure/services/locale_service_impl.dart';

void main() {
  late LocaleServiceImpl service;

  setUp(() async {
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = LocaleServiceImpl(prefs: prefs);
  });

  group('LocaleService - Text Direction', () {
    test('returns RTL for Arabic locale', () {
      final direction = service.getTextDirection(const Locale('ar'));
      expect(direction, TextDirection.rtl);
    });

    test('returns RTL for Hebrew locale', () {
      final direction = service.getTextDirection(const Locale('he'));
      expect(direction, TextDirection.rtl);
    });

    test('returns RTL for Persian locale', () {
      final direction = service.getTextDirection(const Locale('fa'));
      expect(direction, TextDirection.rtl);
    });

    test('returns RTL for Urdu locale', () {
      final direction = service.getTextDirection(const Locale('ur'));
      expect(direction, TextDirection.rtl);
    });

    test('returns LTR for English locale', () {
      final direction = service.getTextDirection(const Locale('en'));
      expect(direction, TextDirection.ltr);
    });

    test('returns LTR for French locale', () {
      final direction = service.getTextDirection(const Locale('fr'));
      expect(direction, TextDirection.ltr);
    });

    test('returns LTR for Spanish locale', () {
      final direction = service.getTextDirection(const Locale('es'));
      expect(direction, TextDirection.ltr);
    });

    test('returns LTR for German locale', () {
      final direction = service.getTextDirection(const Locale('de'));
      expect(direction, TextDirection.ltr);
    });

    test('returns LTR for Chinese locale', () {
      final direction = service.getTextDirection(const Locale('zh'));
      expect(direction, TextDirection.ltr);
    });

    test('returns LTR for Hindi locale', () {
      final direction = service.getTextDirection(const Locale('hi'));
      expect(direction, TextDirection.ltr);
    });
  });

  group('LocaleService - RTL Detection', () {
    test('identifies Arabic as RTL', () {
      expect(service.isRTL(const Locale('ar')), true);
    });

    test('identifies Hebrew as RTL', () {
      expect(service.isRTL(const Locale('he')), true);
    });

    test('identifies Persian as RTL', () {
      expect(service.isRTL(const Locale('fa')), true);
    });

    test('identifies English as LTR', () {
      expect(service.isRTL(const Locale('en')), false);
    });

    test('identifies French as LTR', () {
      expect(service.isRTL(const Locale('fr')), false);
    });

    test('identifies Chinese as LTR', () {
      expect(service.isRTL(const Locale('zh')), false);
    });
  });

  group('LocaleService - Locale Management', () {
    test('returns default locale (English) when not set', () {
      final locale = service.getCurrentLocale();
      expect(locale.languageCode, 'en');
    });

    test('saves and retrieves locale', () async {
      await service.setLocale(const Locale('fr'));
      final locale = service.getCurrentLocale();
      expect(locale.languageCode, 'fr');
    });

    test('saves and retrieves locale with country code', () async {
      await service.setLocale(const Locale('en', 'US'));
      final locale = service.getCurrentLocale();
      expect(locale.languageCode, 'en');
      expect(locale.countryCode, 'US');
    });

    test('returns list of supported locales', () {
      final locales = service.getSupportedLocales();
      expect(locales.length, 8);
      expect(locales.any((l) => l.languageCode == 'en'), true);
      expect(locales.any((l) => l.languageCode == 'fr'), true);
      expect(locales.any((l) => l.languageCode == 'es'), true);
      expect(locales.any((l) => l.languageCode == 'de'), true);
      expect(locales.any((l) => l.languageCode == 'pt'), true);
      expect(locales.any((l) => l.languageCode == 'ar'), true);
      expect(locales.any((l) => l.languageCode == 'hi'), true);
      expect(locales.any((l) => l.languageCode == 'zh'), true);
    });
  });

  group('LocaleService - String Conversion', () {
    test('parses locale string without country code', () {
      final locale = service.parseLocaleString('en');
      expect(locale.languageCode, 'en');
      expect(locale.countryCode, null);
    });

    test('parses locale string with country code', () {
      final locale = service.parseLocaleString('en_US');
      expect(locale.languageCode, 'en');
      expect(locale.countryCode, 'US');
    });

    test('parses locale string with multiple underscores', () {
      final locale = service.parseLocaleString('zh_Hans_CN');
      expect(locale.languageCode, 'zh');
      expect(locale.countryCode, 'Hans');
    });

    test('converts locale to string without country code', () {
      final localeString = service.localeToString(const Locale('en'));
      expect(localeString, 'en');
    });

    test('converts locale to string with country code', () {
      final localeString = service.localeToString(const Locale('en', 'US'));
      expect(localeString, 'en_US');
    });

    test('round-trip conversion preserves locale', () {
      const original = Locale('fr', 'FR');
      final string = service.localeToString(original);
      final parsed = service.parseLocaleString(string);
      expect(parsed.languageCode, original.languageCode);
      expect(parsed.countryCode, original.countryCode);
    });
  });

  group('LocaleService - Persistence', () {
    test('persists locale across service instances', () async {
      await service.setLocale(const Locale('ar'));
      
      // Create a new service instance with the same SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final newService = LocaleServiceImpl(prefs: prefs);
      
      final locale = newService.getCurrentLocale();
      expect(locale.languageCode, 'ar');
    });

    test('changing locale updates stored value', () async {
      await service.setLocale(const Locale('en'));
      expect(service.getCurrentLocale().languageCode, 'en');
      
      await service.setLocale(const Locale('ar'));
      expect(service.getCurrentLocale().languageCode, 'ar');
      
      await service.setLocale(const Locale('zh'));
      expect(service.getCurrentLocale().languageCode, 'zh');
    });
  });
}
