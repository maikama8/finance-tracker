import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/locale_service.dart';

/// Implementation of LocaleService
/// 
/// This service manages locale settings and determines text direction
/// for right-to-left (RTL) languages like Arabic and Hebrew.
class LocaleServiceImpl implements LocaleService {
  final SharedPreferences _prefs;
  static const String _localeKey = 'app_locale';

  // RTL language codes
  static const Set<String> _rtlLanguages = {
    'ar', // Arabic
    'he', // Hebrew
    'fa', // Persian (Farsi)
    'ur', // Urdu
    'yi', // Yiddish
  };

  // Supported locales as defined in requirements
  static const List<Locale> _supportedLocales = [
    Locale('en'), // English
    Locale('fr'), // French
    Locale('es'), // Spanish
    Locale('de'), // German
    Locale('pt'), // Portuguese
    Locale('ar'), // Arabic (RTL)
    Locale('hi'), // Hindi
    Locale('zh'), // Chinese
  ];

  LocaleServiceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  TextDirection getTextDirection(Locale locale) {
    return isRTL(locale) ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  bool isRTL(Locale locale) {
    return _rtlLanguages.contains(locale.languageCode);
  }

  @override
  Locale getCurrentLocale() {
    final localeString = _prefs.getString(_localeKey);
    if (localeString != null) {
      return parseLocaleString(localeString);
    }
    // Default to English if no locale is set
    return const Locale('en');
  }

  @override
  Future<void> setLocale(Locale locale) async {
    final localeString = localeToString(locale);
    await _prefs.setString(_localeKey, localeString);
  }

  @override
  List<Locale> getSupportedLocales() {
    return List.unmodifiable(_supportedLocales);
  }

  @override
  Locale parseLocaleString(String localeString) {
    final parts = localeString.split('_');
    if (parts.length == 1) {
      return Locale(parts[0]);
    } else if (parts.length >= 2) {
      return Locale(parts[0], parts[1]);
    }
    // Fallback to English
    return const Locale('en');
  }

  @override
  String localeToString(Locale locale) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }
}
