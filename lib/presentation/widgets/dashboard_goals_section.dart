import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/savings_goal.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/dashboard_provider.dart';

/// Section displaying savings goal progress circles
class DashboardGoalsSection extends ConsumerWidget {
  final List<SavingsGoal> goals;

  const DashboardGoalsSection({
    super.key,
    required this.goals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: goals.map((goal) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SavingsGoalProgressCard(goal: goal),
        );
      }).toList(),
    );
  }
}

/// Card showing individual savings goal progress
class SavingsGoalProgressCard extends ConsumerWidget {
  final SavingsGoal goal;

  const SavingsGoalProgressCard({
    super.key,
    required this.goal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currencyService = ref.watch(currencyServiceProvider);

    final progressPercentage = goal.progressPercentage.toDouble();
    final progressValue = (progressPercentage / 100).clamp(0.0, 1.0);

    final formattedCurrent = currencyService.formatAmount(
      amount: goal.currentAmount,
      currency: goal.currency,
      locale: user?.locale.toString() ?? 'en',
    );

    final formattedTarget = currencyService.formatAmount(
      amount: goal.targetAmount,
      currency: goal.currency,
      locale: user?.locale.toString() ?? 'en',
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Progress circle
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progressValue,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progressPercentage),
                    ),
                  ),
                  Text(
                    '${progressPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Goal details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedCurrent of $formattedTarget',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deadline: ${_formatDate(goal.deadline)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) {
      return Colors.green;
    } else if (percentage >= 75) {
      return Colors.lightGreen;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else if (percentage >= 25) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
