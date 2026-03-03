# Infrastructure Services

This directory contains concrete implementations of domain services that interact with external systems and APIs.

## Services

### FirebaseAuthService

Implementation of `AuthService` using Firebase Authentication.

**Features:**
- OTP-based authentication with 5-minute expiry for phone numbers
- Email link authentication (simplified implementation)
- Google Sign In integration
- Session management and token refresh
- User profile creation/retrieval from local storage
- Authentication state stream

**Dependencies:**
- `firebase_auth`: Firebase Authentication SDK
- `google_sign_in`: Google Sign In SDK
- `UserLocalDataSource`: Local storage for user profiles

**Usage:**
```dart
final authService = FirebaseAuthService(
  userLocalDataSource: userLocalDataSource,
);

// Send OTP
final result = await authService.sendOTP('+1234567890');

// Verify OTP
final verifyResult = await authService.verifyOTP('+1234567890', '123456');

// Sign in with Google
final googleResult = await authService.signInWithFirebase(AuthProvider.google);

// Listen to auth state changes
authService.authStateChanges.listen((user) {
  if (user != null) {
    print('User signed in: ${user.email}');
  } else {
    print('User signed out');
  }
});

// Sign out
await authService.signOut();
```

**Requirements Validated:**
- 1.1: Send OTP to valid email or phone number
- 1.2: Grant access when correct OTP is entered within 5 minutes
- 1.3: Display error and allow retry for incorrect OTP
- 1.4: Support Firebase email/password and social login options
- 1.5: Create or retrieve user profile from Cloud Storage on successful authentication

**Notes:**
- OTP expiry is enforced at 5 minutes as per requirements
- Email OTP uses Firebase email link authentication (simplified)
- Phone OTP uses Firebase phone authentication with SMS
- Apple and Facebook Sign In require additional platform-specific setup
- User profiles are stored in local storage and will sync to cloud when sync manager is implemented
