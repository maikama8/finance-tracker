import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../domain/entities/savings_goal.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/savings_goal_provider.dart';
import '../widgets/goal_progress_chart.dart';
import 'add_edit_goal_screen.dart';
import 'payment_gateway_selection_screen.dart';

/// Screen showing detailed information about a savings goal
class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;
  final bool showContributeDialog;

  const GoalDetailScreen({
    super.key,
    required this.goalId,
    this.showContributeDialog = false,
  });

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showContributeDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showContributeDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final savingsGoalManager = ref.watch(savingsGoalManagerProvider);
    final currencyService = ref.watch(currencyServiceProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view goal details')),
      );
    }

    return StreamBuilder<SavingsGoal?>(
      stream: savingsGoalManager.watchGoal(widget.goalId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error loading goal: ${snapshot.error}'),
            ),
          );
        }

        final goal = snapshot.data;
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Goal Not Found')),
            body: const Center(child: Text('This goal no longer exists')),
          );
        }

        final progressPercentage = goal.progressPercentage.toDouble();
        final formattedCurrent = currencyService.formatAmount(
          amount: goal.currentAmount,
          currency: goal.currency,
          locale: user.locale.toString(),
        );
        final formattedTarget = currencyService.formatAmount(
          amount: goal.targetAmount,
          currency: goal.currency,
          locale: user.locale.toString(),
        );
        final remaining = goal.targetAmount - goal.currentAmount;
        final formattedRemaining = currencyService.formatAmount(
          amount: remaining,
          currency: goal.currency,
          locale: user.locale.toString(),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditGoalScreen(goalId: goal.id),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Progress Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Large Progress Circle
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: (progressPercentage / 100).clamp(0.0, 1.0),
                              strokeWidth: 16,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getProgressColor(progressPercentage),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${progressPercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Amount Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAmountColumn(
                            'Current',
                            formattedCurrent,
                            Colors.blue,
                          ),
                          _buildAmountColumn(
                            'Target',
                            formattedTarget,
                            Colors.green,
                          ),
                          _buildAmountColumn(
                            'Remaining',
                            formattedRemaining,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deadline Card
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: goal.isOverdue ? Colors.red : Colors.blue,
                  ),
                  title: const Text('Deadline'),
                  subtitle: Text(_formatDate(goal.deadline)),
                  trailing: goal.isOverdue
                      ? const Chip(
                          label: Text('Overdue'),
                          backgroundColor: Colors.red,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : Text(
                          '${_daysUntilDeadline(goal.deadline)} days left',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Suggested Contribution
              if (!goal.isCompleted)
                FutureBuilder<Decimal>(
                  future: savingsGoalManager.calculateSuggestedContribution(goal.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data! > Decimal.zero) {
                      final suggested = currencyService.formatAmount(
                        amount: snapshot.data!,
                        currency: goal.currency,
                        locale: user.locale.toString(),
                      );
                      return Card(
                        color: Colors.blue[50],
                        child: ListTile(
                          leading: const Icon(Icons.lightbulb, color: Colors.blue),
                          title: const Text('Suggested Contribution'),
                          subtitle: Text(
                            'Based on your ${_formatFrequency(goal.reminderFrequency ?? ReminderFrequency.monthly)} reminder',
                          ),
                          trailing: Text(
                            suggested,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              const SizedBox(height: 16),

              // Progress Chart
              const Text(
                'Progress Over Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GoalProgressChart(goal: goal),
                ),
              ),
              const SizedBox(height: 16),

              // Reminder Settings
              Card(
                child: ListTile(
                  leading: Icon(
                    goal.reminderEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: goal.reminderEnabled ? Colors.blue : Colors.grey,
                  ),
                  title: const Text('Reminders'),
                  subtitle: Text(
                    goal.reminderEnabled
                        ? 'Enabled - ${_formatFrequency(goal.reminderFrequency!)}'
                        : 'Disabled',
                  ),
                ),
              ),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
          floatingActionButton: goal.isCompleted
              ? null
              : FloatingActionButton.extended(
                  onPressed: _showContributeDialog,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Contribute'),
                ),
        );
      },
    );
  }

  Widget _buildAmountColumn(String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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

  int _daysUntilDeadline(DateTime deadline) {
    return deadline.difference(DateTime.now()).inDays;
  }

  String _formatFrequency(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return 'daily';
      case ReminderFrequency.weekly:
        return 'weekly';
      case ReminderFrequency.monthly:
        return 'monthly';
    }
  }

  Future<void> _showContributeDialog() async {
    final amountController = TextEditingController();
    final user = ref.read(currentUserProvider);
    final savingsGoalManager = ref.read(savingsGoalManagerProvider);
    final currencyService = ref.read(currencyServiceProvider);

    final goal = await savingsGoalManager.getById(widget.goalId);
    if (goal == null || !mounted) return;

    // Get suggested contribution
    final suggested = await savingsGoalManager.calculateSuggestedContribution(goal.id);
    if (suggested > Decimal.zero) {
      amountController.text = suggested.toString();
    }

    if (!mounted) return;

    final result = await showDialog<Decimal>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contribute to Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixText: '${goal.currency.symbol} ',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
            ),
            if (suggested > Decimal.zero) ...[
              const SizedBox(height: 8),
              Text(
                'Suggested: ${currencyService.formatAmount(
                  amount: suggested,
                  currency: goal.currency,
                  locale: user?.locale.toString() ?? 'en',
                )}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final amount = Decimal.parse(amountController.text);
                if (amount > Decimal.zero) {
                  Navigator.pop(context, amount);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      // Navigate to payment gateway selection
      _showPaymentGatewaySelection(result);
    }
  }

  Future<void> _showPaymentGatewaySelection(Decimal amount) async {
    final savingsGoalManager = ref.read(savingsGoalManagerProvider);
    final goal = await savingsGoalManager.getById(widget.goalId);
    
    if (goal == null || !mounted) return;

    // Navigate to payment gateway selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGatewaySelectionScreen(
          goalId: goal.id,
          amount: amount,
          goalName: goal.name,
        ),
      ),
    );
  }
}
