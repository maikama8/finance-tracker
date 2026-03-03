import '../entities/user.dart';

/// Result of an authentication operation
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });

  factory AuthResult.success(User user) {
    return AuthResult(
      success: true,
      user: user,
    );
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Authentication provider types for Firebase
enum AuthProvider {
  google,
  apple,
  facebook,
  emailPassword,
}

/// Abstract service for user authentication
/// 
/// Handles OTP-based authentication, Firebase social auth,
/// and session management with 5-minute OTP expiry.
abstract class AuthService {
  /// Send OTP to the provided email or phone number
  /// 
  /// Returns [AuthResult] indicating if OTP was sent successfully.
  /// The OTP will expire after 5 minutes.
  /// 
  /// Requirements: 1.1
  Future<AuthResult> sendOTP(String emailOrPhone);

  /// Verify the OTP for the given email or phone number
  /// 
  /// Returns [AuthResult] with user data if OTP is correct and not expired.
  /// OTP must be verified within 5 minutes of generation.
  /// 
  /// Requirements: 1.2, 1.3
  Future<AuthResult> verifyOTP(String emailOrPhone, String otp);

  /// Sign in using Firebase authentication provider
  /// 
  /// Supports Google, Apple, Facebook, and email/password authentication.
  /// Creates or retrieves user profile from cloud storage on success.
  /// 
  /// Requirements: 1.4, 1.5
  Future<AuthResult> signInWithFirebase(AuthProvider provider);

  /// Sign out the current user
  /// 
  /// Clears the authentication session and tokens.
  Future<void> signOut();

  /// Stream of authentication state changes
  /// 
  /// Emits the current user when authenticated, null when signed out.
  Stream<User?> get authStateChanges;
}
