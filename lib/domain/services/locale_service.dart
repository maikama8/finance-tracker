import 'package:flutter/material.dart';

/// Service for managing locale settings and text direction
/// 
/// This service provides methods to determine text direction (LTR/RTL)
/// based on locale and manage locale changes.
abstract class LocaleService {
  /// Get the text direction for a given locale
  /// 
  /// Returns TextDirection.rtl for Arabic, Hebrew, Persian, Urdu
  /// Returns TextDirection.ltr for all other languages
  TextDirection getTextDirection(Locale locale);

  /// Check if a locale uses right-to-left text direction
  bool isRTL(Locale locale);

  /// Get the current app locale
  Locale getCurrentLocale();

  /// Set the app locale
  Future<void> setLocale(Locale locale);

  /// Get list of supported locales
  List<Locale> getSupportedLocales();

  /// Parse a locale string (e.g., "en_US") into a Locale object
  Locale parseLocaleString(String localeString);

  /// Convert a Locale object to a string (e.g., "en_US")
  String localeToString(Locale locale);
}
