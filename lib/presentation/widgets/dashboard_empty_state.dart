import 'package:flutter/material.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import '../screens/add_edit_transaction_screen.dart';

/// Empty state widget shown when user has no transactions
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 120,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  l10n?.noTransactionsYet ?? 'No Transactions Yet',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  l10n?.noTransactionsDescription ??
                      'Start tracking your finances by adding your first transaction. '
                          'You can record income, expenses, and attach receipts.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Call-to-action button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddEditTransactionScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(
                    l10n?.addFirstTransaction ?? 'Add First Transaction',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Secondary action
                TextButton.icon(
                  onPressed: () {
                    // TODO: Navigate to goals screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.savingsGoalsComingSoon ??
                              'Savings goals feature coming soon!',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(l10n?.createSavingsGoal ?? 'Create Savings Goal'),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
