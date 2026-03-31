import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:personal_finance_tracker/domain/entities/user.dart' as domain;
import 'package:personal_finance_tracker/domain/services/auth_service.dart';
import 'package:personal_finance_tracker/domain/value_objects/currency.dart';
import 'package:personal_finance_tracker/infrastructure/services/firebase_auth_service.dart';
import 'package:personal_finance_tracker/infrastructure/data_sources/local/user_local_data_source.dart';

// Generate mocks
@GenerateMocks([
  firebase_auth.FirebaseAuth,
  firebase_auth.User,
  firebase_auth.UserCredential,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  UserLocalDataSource,
])
import 'firebase_auth_service_test.mocks.dart';

void main() {
  late FirebaseAuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUserLocalDataSource mockUserLocalDataSource;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUserLocalDataSource = MockUserLocalDataSource();

    authService = FirebaseAuthService(
      firebaseAuth: mockFirebaseAuth,
      googleSignIn: mockGoogleSignIn,
      userLocalDataSource: mockUserLocalDataSource,
    );
  });

  group('FirebaseAuthService', () {
    late MockUser mockFirebaseUser;

    setUp(() {
      mockFirebaseUser = MockUser();

      when(mockFirebaseUser.uid).thenReturn('firebase-user-123');
      when(mockFirebaseUser.email).thenReturn('user@example.com');
      when(mockFirebaseUser.phoneNumber).thenReturn(null);
      when(mockFirebaseUser.displayName).thenReturn('Finance User');
    });

    group('sendOTP', () {
      test('should send OTP for valid phone number', () async {
        // Arrange
        const phoneNumber = '+1234567890';
        const verificationId = 'test-verification-id';

        when(
          mockFirebaseAuth.verifyPhoneNumber(
            phoneNumber: anyNamed('phoneNumber'),
            verificationCompleted: anyNamed('verificationCompleted'),
            verificationFailed: anyNamed('verificationFailed'),
            codeSent: anyNamed('codeSent'),
            codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
            timeout: anyNamed('timeout'),
          ),
        ).thenAnswer((invocation) async {
          // Simulate code sent callback
          final codeSent =
              invocation.namedArguments[const Symbol('codeSent')]
                  as void Function(String, int?);
          codeSent(verificationId, null);
        });

        // Act
        final result = await authService.sendOTP(phoneNumber);

        // Assert
        expect(result.success, true);
        expect(result.errorMessage, isNull);
      });

      test('should return failure for invalid phone number', () async {
        // Arrange
        const phoneNumber = 'invalid-phone';

        when(
          mockFirebaseAuth.verifyPhoneNumber(
            phoneNumber: anyNamed('phoneNumber'),
            verificationCompleted: anyNamed('verificationCompleted'),
            verificationFailed: anyNamed('verificationFailed'),
            codeSent: anyNamed('codeSent'),
            codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
            timeout: anyNamed('timeout'),
          ),
        ).thenAnswer((invocation) async {
          // Simulate verification failed callback
          final verificationFailed =
              invocation.namedArguments[const Symbol('verificationFailed')]
                  as void Function(firebase_auth.FirebaseAuthException);
          verificationFailed(
            firebase_auth.FirebaseAuthException(
              code: 'invalid-phone-number',
              message: 'Invalid phone number',
            ),
          );
        });

        // Act
        final result = await authService.sendOTP(phoneNumber);

        // Assert
        expect(result.success, false);
        expect(result.errorMessage, isNotNull);
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
        verify(mockGoogleSignIn.signOut()).called(1);
      });

      test('should not throw error even if sign out fails', () async {
        // Arrange
        when(
          mockFirebaseAuth.signOut(),
        ).thenThrow(Exception('Sign out failed'));
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        // Act & Assert - should not throw
        await authService.signOut();
      });
    });

    group('authStateChanges', () {
      test('should emit null when user is not authenticated', () async {
        // Arrange
        when(
          mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => Stream.value(null));

        // Act
        final stream = authService.authStateChanges;

        // Assert
        await expectLater(stream, emits(null));
      });

      test(
        'should create and emit a user when Firebase is authenticated',
        () async {
          // Arrange
          when(
            mockFirebaseAuth.authStateChanges(),
          ).thenAnswer((_) => Stream.value(mockFirebaseUser));
          when(
            mockUserLocalDataSource.getById('firebase-user-123'),
          ).thenAnswer((_) async => null);
          when(mockUserLocalDataSource.store(any)).thenAnswer((
            invocation,
          ) async {
            return invocation.positionalArguments.first as domain.User;
          });

          // Act
          final emittedUser = await authService.authStateChanges.first;

          // Assert
          expect(emittedUser, isNotNull);
          expect(emittedUser!.id, 'firebase-user-123');
          expect(emittedUser.email, 'user@example.com');
          expect(emittedUser.displayName, 'Finance User');
          verify(mockUserLocalDataSource.store(any)).called(1);
        },
      );
    });

    group('signInWithFirebase', () {
      test(
        'should recover the current Firebase user after Google sign in throws',
        () async {
          // Arrange
          when(mockGoogleSignIn.signIn()).thenThrow(
            PlatformException(
              code: 'sign_in_failed',
              message: 'com.google.android.gms.common.api.ApiException: 10:',
            ),
          );
          when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
          when(
            mockUserLocalDataSource.getById('firebase-user-123'),
          ).thenAnswer((_) async => null);
          when(mockUserLocalDataSource.store(any)).thenAnswer((
            invocation,
          ) async {
            return invocation.positionalArguments.first as domain.User;
          });

          // Act
          final result = await authService.signInWithFirebase(
            AuthProvider.google,
          );

          // Assert
          expect(result.success, true);
          expect(result.errorMessage, isNull);
          expect(result.user, isNotNull);
          expect(result.user!.id, 'firebase-user-123');
          verify(mockUserLocalDataSource.store(any)).called(1);
        },
      );
    });
  });
}
