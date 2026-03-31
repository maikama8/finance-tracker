import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/locale_service.dart';
import '../../infrastructure/services/locale_service_impl.dart';

/// Provider for SharedPreferences
/// Override this in ProviderScope with a pre-initialized instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden with a pre-initialized instance');
});

/// Provider for LocaleService
final localeServiceProvider = Provider<LocaleService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleServiceImpl(prefs: prefs);
});

/// State notifier for managing app locale
class LocaleNotifier extends StateNotifier<Locale> {
  final LocaleService _localeService;

  LocaleNotifier(this._localeService) : super(_localeService.getCurrentLocale());

  /// Change the app locale
  Future<void> setLocale(Locale locale) async {
    await _localeService.setLocale(locale);
    state = locale;
  }

  /// Get text direction for current locale
  TextDirection getTextDirection() {
    return _localeService.getTextDirection(state);
  }

  /// Check if current locale is RTL
  bool isRTL() {
    return _localeService.isRTL(state);
  }

  /// Get list of supported locales
  List<Locale> getSupportedLocales() {
    return _localeService.getSupportedLocales();
  }
}

/// Provider for locale state
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final localeService = ref.watch(localeServiceProvider);
  return LocaleNotifier(localeService);
});

/// Provider for text direction based on current locale
final textDirectionProvider = Provider<TextDirection>((ref) {
  final locale = ref.watch(localeProvider);
  final localeService = ref.watch(localeServiceProvider);
  return localeService.getTextDirection(locale);
});
