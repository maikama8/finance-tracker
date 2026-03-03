import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decimal/decimal.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/services/savings_goal_manager.dart';
import '../../domain/value_objects/currency.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/savings_goal_provider.dart';

/// Screen for creating or editing a savings goal
class AddEditGoalScreen extends ConsumerStatefulWidget {
  final String? goalId;

  const AddEditGoalScreen({super.key, this.goalId});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  
  Currency _selectedCurrency = Currency.USD;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  bool _reminderEnabled = false;
  ReminderFrequency? _reminderFrequency;
  
  bool _isLoading = false;
  SavingsGoal? _existingGoal;

  @override
  void initState() {
    super.initState();
    if (widget.goalId != null) {
      _loadExistingGoal();
    }
  }

  Future<void> _loadExistingGoal() async {
    setState(() => _isLoading = true);
    
    final savingsGoalManager = ref.read(savingsGoalManagerProvider);
    final goal = await savingsGoalManager.getById(widget.goalId!);
    
    if (goal != null) {
      setState(() {
        _existingGoal = goal;
        _nameController.text = goal.name;
        _targetAmountController.text = goal.targetAmount.toString();
        _selectedCurrency = goal.currency;
        _selectedDeadline = goal.deadline;
        _reminderEnabled = goal.reminderEnabled;
        _reminderFrequency = goal.reminderFrequency;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isEditing = widget.goalId != null;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to create goals')),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'Create Goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Goal Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g., Emergency Fund, Vacation',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a goal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Target Amount
            TextFormField(
              controller: _targetAmountController,
              decoration: const InputDecoration(
                labelText: 'Target Amount',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a target amount';
                }
                try {
                  final amount = Decimal.parse(value);
                  if (amount <= Decimal.zero) {
                    return 'Amount must be greater than zero';
                  }
                } catch (e) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Currency Selector
            DropdownButtonFormField<Currency>(
              value: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
              ),
              items: Currency.commonCurrencies.map((currency) {
                return DropdownMenuItem(
                  value: currency,
                  child: Text('${currency.code} (${currency.symbol})'),
                );
              }).toList(),
              onChanged: (currency) {
                if (currency != null) {
                  setState(() => _selectedCurrency = currency);
                }
              },
            ),
            const SizedBox(height: 16),

            // Deadline Picker
            ListTile(
              title: const Text('Deadline'),
              subtitle: Text(_formatDate(_selectedDeadline)),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDeadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() => _selectedDeadline = picked);
                }
              },
            ),
            const SizedBox(height: 24),

            // Reminder Configuration
            const Text(
              'Reminder Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Enable Reminders'),
              subtitle: const Text('Get notifications to contribute'),
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                  if (!value) {
                    _reminderFrequency = null;
                  } else if (_reminderFrequency == null) {
                    _reminderFrequency = ReminderFrequency.weekly;
                  }
                });
              },
            ),

            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<ReminderFrequency>(
                value: _reminderFrequency,
                decoration: const InputDecoration(
                  labelText: 'Reminder Frequency',
                  border: OutlineInputBorder(),
                ),
                items: ReminderFrequency.values.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(_formatFrequency(frequency)),
                  );
                }).toList(),
                onChanged: (frequency) {
                  setState(() => _reminderFrequency = frequency);
                },
                validator: (value) {
                  if (_reminderEnabled && value == null) {
                    return 'Please select a reminder frequency';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveGoal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Goal' : 'Create Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not logged in');
      }

      final savingsGoalManager = ref.read(savingsGoalManagerProvider);
      
      final input = SavingsGoalInput(
        name: _nameController.text.trim(),
        targetAmount: Decimal.parse(_targetAmountController.text),
        currency: _selectedCurrency,
        deadline: _selectedDeadline,
        reminderEnabled: _reminderEnabled,
        reminderFrequency: _reminderFrequency,
      );

      if (widget.goalId != null) {
        // Update existing goal
        await savingsGoalManager.update(widget.goalId!, input);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal updated successfully')),
          );
        }
      } else {
        // Create new goal
        await savingsGoalManager.create(user.id, input);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Goal created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFrequency(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
    }
  }
}
