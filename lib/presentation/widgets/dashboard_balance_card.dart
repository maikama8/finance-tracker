import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/dashboard_provider.dart';
import '../../domain/value_objects/currency.dart';

/// Card displaying the total balance
class DashboardBalanceCard extends ConsumerWidget {
  final Decimal balance;

  const DashboardBalanceCard({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final currencyService = ref.watch(currencyServiceProvider);

    // Format the balance with user's base currency
    final formattedBalance = currencyService.formatAmount(
      amount: balance,
      currency: user?.baseCurrency ?? const Currency(
        code: 'USD',
        symbol: '\$',
        name: 'US Dollar',
        decimalPlaces: 2,
      ),
      locale: user?.locale.toString() ?? 'en',
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.totalBalance ?? 'Total Balance',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedBalance,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
