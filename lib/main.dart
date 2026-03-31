import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/navigation/app_routes.dart';
import 'presentation/navigation/route_generator.dart';
import 'presentation/widgets/error_boundary.dart';
import 'application/state/auth_provider.dart';
import 'application/state/locale_provider.dart';
import 'infrastructure/data_sources/local/hive_database.dart';
import 'infrastructure/services/error_handler.dart';
import 'dart:async';

void main() {
  // Handle errors outside of Flutter framework
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Set up global error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        ErrorHandler().handleError(
          details.exception,
          details.stack,
          context: 'Flutter Framework',
          severity: ErrorSeverity.error,
        );
      };

      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize Hive for local storage
      await HiveDatabase.instance.initialize();

      // Pre-initialize SharedPreferences
      final sharedPreferences = await SharedPreferences.getInstance();

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const PersonalFinanceTrackerApp(),
        ),
      );
    },
    (error, stackTrace) {
      ErrorHandler().handleError(
        error,
        stackTrace,
        context: 'Uncaught Error',
        severity: ErrorSeverity.critical,
      );
    },
  );
}

class PersonalFinanceTrackerApp extends ConsumerWidget {
  const PersonalFinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the locale provider to rebuild when locale changes
    final locale = ref.watch(localeProvider);
    // Watch the auth state to determine which screen to show
    final currentUser = ref.watch(currentUserProvider);
    
    return ErrorBoundary(
      child: MaterialApp(
        title: 'Personal Finance Tracker',
        // Localization configuration
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('fr'), // French
          Locale('es'), // Spanish
          Locale('de'), // German
          Locale('pt'), // Portuguese
          Locale('ar'), // Arabic
          Locale('hi'), // Hindi
          Locale('zh'), // Chinese
        ],
        // Set the current locale
        locale: locale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        // Use named routes with route generator
        initialRoute: currentUser == null ? AppRoutes.login : AppRoutes.dashboard,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}
