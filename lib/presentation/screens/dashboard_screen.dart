import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:decimal/decimal.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import '../../application/state/dashboard_provider.dart';
import '../../application/state/auth_provider.dart';
import '../../domain/services/currency_service.dart';
import '../widgets/dashboard_balance_card.dart';
import '../widgets/dashboard_spending_chart.dart';
import '../widgets/dashboard_goals_section.dart';
import '../widgets/dashboard_empty_state.dart';
import 'transaction_list_screen.dart';

/// Dashboard screen showing balance, spending breakdown, and savings goals
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.dashboard ?? 'Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionListScreen(),
                ),
              );
            },
            tooltip: l10n?.transactions ?? 'Transactions',
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const DashboardLoadingState(),
        error: (error, stack) => DashboardErrorState(error: error.toString()),
        data: (dashboardData) {
          // Show empty state if no transactions
          if (!dashboardData.hasTransactions) {
            return const DashboardEmptyState();
          }

          // Show dashboard with data
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh dashboard data
              ref.invalidate(dashboardDataProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance card
                  DashboardBalanceCard(balance: dashboardData.balance),
                  const SizedBox(height: 24),

                  // Monthly spending breakdown
                  if (dashboardData.spendingBreakdown.isNotEmpty) ...[
                    Text(
                      l10n?.monthlySpending ?? 'Monthly Spending',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DashboardSpendingChart(
                      spendingBreakdown: dashboardData.spendingBreakdown,
                      categories: dashboardData.categories,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Savings goals section
                  if (dashboardData.activeGoals.isNotEmpty) ...[
                    Text(
                      l10n?.savingsGoals ?? 'Savings Goals',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DashboardGoalsSection(goals: dashboardData.activeGoals),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Loading state widget
class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading dashboard...'),
        ],
      ),
    );
  }
}

/// Error state widget
class DashboardErrorState extends StatelessWidget {
  final String error;

  const DashboardErrorState({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
