import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/services/auth_service.dart';
import '../../domain/value_objects/currency.dart';
import '../data_sources/local/user_local_data_source.dart';

/// Firebase implementation of AuthService
///
/// Provides OTP-based authentication with 5-minute expiry,
/// Firebase social authentication, and session management.
class FirebaseAuthService implements AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final UserLocalDataSource _userLocalDataSource;

  // Store OTP verification IDs and timestamps for expiry checking
  final Map<String, _OTPSession> _otpSessions = {};

  // OTP expiry duration (5 minutes as per requirements)
  static const Duration _otpExpiryDuration = Duration(minutes: 5);

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    required UserLocalDataSource userLocalDataSource,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _userLocalDataSource = userLocalDataSource;

  @override
  Future<AuthResult> sendOTP(String emailOrPhone) async {
    try {
      // Determine if input is email or phone
      final isEmail = emailOrPhone.contains('@');

      if (isEmail) {
        // For email, we'll use Firebase email link authentication
        // Note: Firebase doesn't support OTP for email directly,
        // so we use email link as an alternative
        final actionCodeSettings = firebase_auth.ActionCodeSettings(
          url: 'https://your-app.firebaseapp.com/finishSignUp',
          handleCodeInApp: true,
          androidPackageName: 'com.example.personal_finance_tracker',
          iOSBundleId: 'com.example.personalFinanceTracker',
        );

        await _firebaseAuth.sendSignInLinkToEmail(
          email: emailOrPhone,
          actionCodeSettings: actionCodeSettings,
        );

        // Store session for expiry tracking
        _otpSessions[emailOrPhone] = _OTPSession(
          identifier: emailOrPhone,
          timestamp: DateTime.now(),
        );

        return AuthResult.success(
          domain.User(
            id: '',
            email: emailOrPhone,
            displayName: '',
            locale: const Locale('en', 'US'),
            baseCurrency: Currency.USD,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // For phone, use Firebase phone authentication
        final completer = Completer<AuthResult>();

        await _firebaseAuth.verifyPhoneNumber(
          phoneNumber: emailOrPhone,
          verificationCompleted:
              (firebase_auth.PhoneAuthCredential credential) {
                // Auto-verification completed (Android only)
                // This won't be used in our OTP flow
              },
          verificationFailed: (firebase_auth.FirebaseAuthException e) {
            completer.complete(
              AuthResult.failure(e.message ?? 'Failed to send OTP'),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            // Store verification ID and timestamp for later verification
            _otpSessions[emailOrPhone] = _OTPSession(
              identifier: emailOrPhone,
              verificationId: verificationId,
              timestamp: DateTime.now(),
            );

            completer.complete(
              AuthResult.success(
                domain.User(
                  id: '',
                  email: '',
                  phoneNumber: emailOrPhone,
                  displayName: '',
                  locale: const Locale('en', 'US'),
                  baseCurrency: Currency.USD,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Timeout for auto-retrieval
          },
          timeout: const Duration(seconds: 60),
        );

        return await completer.future;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'Failed to send OTP');
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<AuthResult> verifyOTP(String emailOrPhone, String otp) async {
    try {
      // Check if OTP session exists
      final session = _otpSessions[emailOrPhone];
      if (session == null) {
        return AuthResult.failure(
          'No OTP session found. Please request a new OTP.',
        );
      }

      // Check if OTP has expired (5-minute window)
      final now = DateTime.now();
      final elapsed = now.difference(session.timestamp);
      if (elapsed > _otpExpiryDuration) {
        _otpSessions.remove(emailOrPhone);
        return AuthResult.failure('OTP has expired. Please request a new OTP.');
      }

      // Determine if input is email or phone
      final isEmail = emailOrPhone.contains('@');

      firebase_auth.UserCredential userCredential;

      if (isEmail) {
        // For email, verify the sign-in link
        // Note: In a real implementation, the OTP would be part of the email link
        // For this implementation, we'll use a simplified approach
        return AuthResult.failure(
          'Email OTP verification not fully implemented. Use Firebase social auth instead.',
        );
      } else {
        // For phone, verify with the OTP code
        if (session.verificationId == null) {
          return AuthResult.failure('Invalid OTP session');
        }

        final credential = firebase_auth.PhoneAuthProvider.credential(
          verificationId: session.verificationId!,
          smsCode: otp,
        );

        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      // Clean up OTP session
      _otpSessions.remove(emailOrPhone);

      // Create or retrieve user profile
      final user = await _createOrRetrieveUserProfile(userCredential.user!);

      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        return AuthResult.failure('Incorrect OTP. Please try again.');
      }
      return AuthResult.failure(e.message ?? 'Failed to verify OTP');
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<AuthResult> signInWithFirebase(AuthProvider provider) async {
    try {
      firebase_auth.UserCredential userCredential;

      switch (provider) {
        case AuthProvider.google:
          userCredential = await _signInWithGoogle();
          break;
        case AuthProvider.apple:
          // Apple Sign In would require additional setup
          return AuthResult.failure('Apple Sign In not yet implemented');
        case AuthProvider.facebook:
          // Facebook Sign In would require additional setup
          return AuthResult.failure('Facebook Sign In not yet implemented');
        case AuthProvider.emailPassword:
          return AuthResult.failure(
            'Email/Password sign in requires separate implementation',
          );
      }

      // Create or retrieve user profile
      final user = await _createOrRetrieveUserProfile(userCredential.user!);

      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'Authentication failed');
    } catch (e) {
      final recoveredUser = await _recoverCurrentUser();
      if (recoveredUser != null) {
        return AuthResult.success(recoveredUser);
      }

      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Sign in with Google
  Future<firebase_auth.UserCredential> _signInWithGoogle() async {
    // Trigger the Google Sign In flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google Sign In was canceled',
      );
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Create or retrieve user profile from local/cloud storage
  ///
  /// Requirements: 1.5
  Future<domain.User> _createOrRetrieveUserProfile(
    firebase_auth.User firebaseUser,
  ) async {
    // Try to get existing user from local storage
    final existingUser = await _userLocalDataSource.getById(firebaseUser.uid);

    if (existingUser != null) {
      return existingUser;
    }

    // Create new user profile
    final newUser = domain.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      phoneNumber: firebaseUser.phoneNumber,
      displayName: firebaseUser.displayName ?? 'User',
      locale: const Locale('en', 'US'), // Default locale
      baseCurrency: Currency.USD, // Default currency
      notificationPrefs: const domain.NotificationPreferences(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to local storage
    await _userLocalDataSource.store(newUser);

    // TODO: Also save to cloud storage when sync is implemented

    return newUser;
  }

  /// Some Google Play Services flows can throw even after Firebase has a user.
  /// Recover that session so the app does not stay signed out.
  Future<domain.User?> _recoverCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    return _createOrRetrieveUserProfile(firebaseUser);
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      // Clear OTP sessions
      _otpSessions.clear();
    } catch (e) {
      // Log error but don't throw - sign out should always succeed
      debugPrint('Error during sign out: $e');
    }
  }

  @override
  Stream<domain.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      return _createOrRetrieveUserProfile(firebaseUser);
    });
  }
}

/// Internal class to track OTP sessions with expiry
class _OTPSession {
  final String identifier; // email or phone
  final String? verificationId; // for phone verification
  final DateTime timestamp;

  _OTPSession({
    required this.identifier,
    this.verificationId,
    required this.timestamp,
  });
}
