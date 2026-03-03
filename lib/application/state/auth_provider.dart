import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/services/auth_service.dart';
import '../../infrastructure/services/firebase_auth_service.dart';
import '../../infrastructure/data_sources/local/user_local_data_source.dart';
import '../../infrastructure/data_sources/local/hive_database.dart';

/// Provider for HiveDatabase
final hiveDatabaseProvider = Provider<HiveDatabase>((ref) {
  return HiveDatabase.instance;
});

/// Provider for UserLocalDataSource
final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  final database = ref.watch(hiveDatabaseProvider);
  return UserLocalDataSource(database);
});

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final userLocalDataSource = ref.watch(userLocalDataSourceProvider);
  return FirebaseAuthService(userLocalDataSource: userLocalDataSource);
});

/// State for authentication flow
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final User? user;
  final bool otpSent;
  final String? emailOrPhone;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
    this.otpSent = false,
    this.emailOrPhone,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    User? user,
    bool? otpSent,
    String? emailOrPhone,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
      otpSent: otpSent ?? this.otpSent,
      emailOrPhone: emailOrPhone ?? this.emailOrPhone,
    );
  }
}

/// State notifier for authentication
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
      } else {
        state = const AuthState();
      }
    });
  }

  /// Send OTP to email or phone
  Future<void> sendOTP(String emailOrPhone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.sendOTP(emailOrPhone);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        otpSent: true,
        emailOrPhone: emailOrPhone,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
  }

  /// Verify OTP
  Future<void> verifyOTP(String otp) async {
    if (state.emailOrPhone == null) {
      state = state.copyWith(
        errorMessage: 'No email or phone number provided',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.verifyOTP(state.emailOrPhone!, otp);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        otpSent: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
  }

  /// Sign in with Firebase provider
  Future<void> signInWithFirebase(AuthProvider provider) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _authService.signInWithFirebase(provider);

    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        user: result.user,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});
