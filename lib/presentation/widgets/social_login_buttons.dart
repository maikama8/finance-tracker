import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import '../../application/state/auth_provider.dart';
import '../../domain/services/auth_service.dart';

/// Widget for social login buttons (Google, Apple, Facebook)
/// 
/// Implements Requirement 1.4: Firebase authentication with social login options
class SocialLoginButtons extends ConsumerWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider with "OR" text
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n?.or ?? 'OR',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          l10n?.continueWith ?? 'Continue with',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Google Sign In button
        _SocialLoginButton(
          onPressed: authState.isLoading
              ? null
              : () async {
                  await authNotifier.signInWithFirebase(AuthProvider.google);
                },
          icon: Image.asset(
            'assets/images/google_logo.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.g_mobiledata, size: 24, color: Colors.red);
            },
          ),
          label: l10n?.signInWithGoogle ?? 'Sign in with Google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
        ),
        const SizedBox(height: 12),

        // Apple Sign In button
        _SocialLoginButton(
          onPressed: authState.isLoading
              ? null
              : () async {
                  await authNotifier.signInWithFirebase(AuthProvider.apple);
                },
          icon: const Icon(Icons.apple, size: 24, color: Colors.white),
          label: l10n?.signInWithApple ?? 'Sign in with Apple',
          backgroundColor: Colors.black,
          textColor: Colors.white,
        ),
        const SizedBox(height: 12),

        // Facebook Sign In button
        _SocialLoginButton(
          onPressed: authState.isLoading
              ? null
              : () async {
                  await authNotifier.signInWithFirebase(AuthProvider.facebook);
                },
          icon: const Icon(Icons.facebook, size: 24, color: Colors.white),
          label: l10n?.signInWithFacebook ?? 'Sign in with Facebook',
          backgroundColor: const Color(0xFF1877F2),
          textColor: Colors.white,
        ),
      ],
    );
  }
}

/// Internal widget for individual social login button
class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: backgroundColor == Colors.white
              ? BorderSide(color: Colors.grey[300]!)
              : BorderSide.none,
        ),
        elevation: backgroundColor == Colors.white ? 0 : 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
