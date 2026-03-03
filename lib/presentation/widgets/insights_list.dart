import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../domain/services/report_generator.dart';
import '../../domain/value_objects/currency.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/dashboard_provider.dart';

/// List widget displaying financial insights and savings suggestions
class InsightsList extends ConsumerWidget {
  final String userId;

  const InsightsList({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportGenerator = ref.watch(reportGeneratorProvider);
    final user = ref.watch(currentUserProvider);

    return FutureBuilder<List<Insight>>(
      future: reportGenerator.generateInsights(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading insights: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final insights = snapshot.data ?? [];
        
        if (insights.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No insights available yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add more transactions to get personalized insights',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: insights.map((insight) {
            return _buildInsightCard(context, ref, insight, user);
          }).toList(),
        );
      },
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    WidgetRef ref,
    Insight insight,
    dynamic user,
  ) {
    final currencyService = ref.watch(currencyServiceProvider);
    
    // Determine icon and color based on insight type
    IconData icon;
    Color color;
    
    switch (insight.type) {
      case InsightType.highSpending:
        icon = Icons.trending_up;
        color = Colors.orange;
        break;
      case InsightType.savingsOpportunity:
        icon = Icons.savings;
        color = Colors.green;
        break;
      case InsightType.budgetWarning:
        icon = Icons.warning;
        color = Colors.red;
        break;
      case InsightType.goalProgress:
        icon = Icons.flag;
        color = Colors.blue;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          insight.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            insight.description,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        trailing: insight.amount != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currencyService.formatAmount(
                    amount: insight.amount!,
                    currency: user?.baseCurrency ?? const Currency(
                      code: 'USD',
                      symbol: '\$',
                      name: 'US Dollar',
                      decimalPlaces: 2,
                    ),
                    locale: user?.locale.toString() ?? 'en',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
