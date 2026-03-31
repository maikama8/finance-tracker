import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import '../../application/state/auth_provider.dart';
import '../navigation/app_routes.dart';
import '../widgets/social_login_buttons.dart';
import '../widgets/auth_error_display.dart';

/// Login screen with OTP and Firebase authentication options
/// 
/// Implements Requirements 1.1, 1.2, 1.3, 1.4
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailPhoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    ref.listenManual<AuthState>(authProvider, (previous, next) {
      final userJustSignedIn = previous?.user == null && next.user != null;
      if (!userJustSignedIn || !mounted) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.dashboard,
          (route) => false,
        );
      });
    });
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App logo and title
                const Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.appTitle ?? 'Personal Finance Tracker',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.loginSubtitle ?? 'Manage your finances securely',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Error display with retry option
                if (authState.errorMessage != null) ...[
                  AuthErrorDisplay(
                    errorMessage: authState.errorMessage!,
                    onRetry: () {
                      authNotifier.clearError();
                      if (authState.otpSent) {
                        // Retry OTP verification
                        if (_otpController.text.isNotEmpty) {
                          authNotifier.verifyOTP(_otpController.text.trim());
                        }
                      } else {
                        // Retry sending OTP
                        if (_emailPhoneController.text.isNotEmpty) {
                          authNotifier.sendOTP(_emailPhoneController.text.trim());
                        }
                      }
                    },
                    onDismiss: () {
                      authNotifier.clearError();
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email/Phone input field
                TextFormField(
                  controller: _emailPhoneController,
                  decoration: InputDecoration(
                    labelText: l10n?.emailOrPhone ?? 'Email or Phone Number',
                    hintText: l10n?.emailOrPhoneHint ?? 'Enter your email or phone',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabled: !authState.otpSent && !authState.isLoading,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.emailOrPhoneRequired ?? 'Please enter email or phone';
                    }
                    // Basic validation for email or phone
                    if (!value.contains('@') && !RegExp(r'^\+?[\d\s-]+$').hasMatch(value)) {
                      return l10n?.invalidEmailOrPhone ?? 'Invalid email or phone format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // OTP input field (shown after OTP is sent)
                if (authState.otpSent) ...[
                  TextFormField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: l10n?.otpCode ?? 'OTP Code',
                      hintText: l10n?.otpCodeHint ?? 'Enter 6-digit code',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabled: !authState.isLoading,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n?.otpRequired ?? 'Please enter OTP';
                      }
                      if (value.length != 6) {
                        return l10n?.otpInvalid ?? 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.otpExpiryNote ?? 'OTP expires in 5 minutes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Send OTP / Verify OTP button
                ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            if (!authState.otpSent) {
                              // Send OTP
                              await authNotifier.sendOTP(_emailPhoneController.text.trim());
                            } else {
                              // Verify OTP
                              await authNotifier.verifyOTP(_otpController.text.trim());
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          authState.otpSent
                              ? (l10n?.verifyOtp ?? 'Verify OTP')
                              : (l10n?.sendOtp ?? 'Send OTP'),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),

                // Resend OTP button (shown after OTP is sent)
                if (authState.otpSent) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            await authNotifier.sendOTP(_emailPhoneController.text.trim());
                            _otpController.clear();
                          },
                    child: Text(l10n?.resendOtp ?? 'Resend OTP'),
                  ),
                ],

                const SizedBox(height: 32),

                // Social login buttons
                const SocialLoginButtons(),

                const SizedBox(height: 32),

                // Privacy policy and terms
                Text(
                  l10n?.privacyTerms ?? 'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
