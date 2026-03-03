import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../application/state/auth_provider.dart';
import '../../application/state/dashboard_provider.dart';
import '../../application/state/transaction_list_provider.dart';
import 'category_picker_screen.dart';
import 'receipt_capture_screen.dart';

/// Screen for adding or editing a transaction
class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const AddEditTransactionScreen({
    super.key,
    this.transaction,
  });

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _receiptImageId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _initializeFromTransaction();
    }
  }

  void _initializeFromTransaction() {
    final transaction = widget.transaction!;
    _amountController.text = transaction.amount.toString();
    _notesController.text = transaction.notes ?? '';
    _type = transaction.type;
    _selectedDate = transaction.date;
    _receiptImageId = transaction.receiptImageId;
    // Category will be loaded asynchronously
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final isEditing = widget.transaction != null;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    // Load category if editing
    if (isEditing && _selectedCategory == null) {
      final categoryAsync = ref.watch(categoryByIdProvider(widget.transaction!.categoryId));
      categoryAsync.whenData((category) {
        if (category != null && _selectedCategory == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedCategory = category;
            });
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? (l10n?.editTransaction ?? 'Edit Transaction')
              : (l10n?.addTransaction ?? 'Add Transaction'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context),
              tooltip: l10n?.delete ?? 'Delete',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Toggle
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text(l10n?.expense ?? 'Expense'),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text(l10n?.income ?? 'Income'),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n?.amount ?? 'Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n?.pleaseEnterAmount ?? 'Please enter an amount';
                  }
                  try {
                    final amount = Decimal.parse(value);
                    if (amount <= Decimal.zero) {
                      return l10n?.amountMustBePositive ?? 'Amount must be positive';
                    }
                  } catch (e) {
                    return l10n?.invalidAmount ?? 'Invalid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Picker
              InkWell(
                onTap: () => _pickCategory(context, user.id),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n?.category ?? 'Category',
                    border: const OutlineInputBorder(),
                    errorText: _selectedCategory == null
                        ? (l10n?.pleaseSelectCategory ?? 'Please select a category')
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (_selectedCategory != null) ...[
                        CircleAvatar(
                          backgroundColor: _selectedCategory!.colorValue,
                          radius: 16,
                          child: Text(
                            _selectedCategory!.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedCategory!.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ] else
                        Text(
                          l10n?.selectCategory ?? 'Select Category',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n?.date ?? 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes Field (Optional)
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: '${l10n?.notes ?? 'Notes'} (${l10n?.optional ?? 'Optional'})',
                  prefixIcon: const Icon(Icons.note),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Receipt Photo Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n?.receiptPhoto ?? 'Receipt Photo'} (${l10n?.optional ?? 'Optional'})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_receiptImageId != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(l10n?.receiptAttached ?? 'Receipt attached'),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _receiptImageId = null;
                                });
                              },
                              child: Text(l10n?.remove ?? 'Remove'),
                            ),
                          ],
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: () => _captureReceipt(context),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(l10n?.captureReceipt ?? 'Capture Receipt'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              FilledButton(
                onPressed: _isLoading ? null : () => _saveTransaction(context, user.id),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEditing
                            ? (l10n?.saveChanges ?? 'Save Changes')
                            : (l10n?.addTransaction ?? 'Add Transaction'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCategory(BuildContext context, String userId) async {
    final category = await Navigator.push<Category>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryPickerScreen(userId: userId),
      ),
    );
    if (category != null) {
      setState(() {
        _selectedCategory = category;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _captureReceipt(BuildContext context) async {
    final result = await Navigator.push<ReceiptCaptureResult>(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceiptCaptureScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _receiptImageId = result.imageId;
        // Pre-fill fields if OCR data is available
        if (result.receiptData != null) {
          final data = result.receiptData!;
          if (data.amount != null) {
            _amountController.text = data.amount.toString();
          }
          if (data.date != null) {
            _selectedDate = data.date!;
          }
        }
      });
    }
  }

  Future<void> _saveTransaction(BuildContext context, String userId) async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseFillAllFields ??
                'Please fill all required fields',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = Decimal.parse(_amountController.text);
      final input = TransactionInput(
        amount: amount,
        currencyCode: 'USD', // TODO: Get from user preferences
        type: _type,
        categoryId: _selectedCategory!.id,
        date: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        receiptImageId: _receiptImageId,
      );

      final transactionRepo = ref.read(transactionRepositoryProvider);
      
      if (widget.transaction != null) {
        await transactionRepo.update(widget.transaction!.id, input);
      } else {
        await transactionRepo.create(userId, input);
      }

      // Invalidate providers to refresh data
      ref.invalidate(transactionListProvider);
      ref.invalidate(dashboardDataProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transaction != null
                  ? (AppLocalizations.of(context)?.transactionUpdated ??
                      'Transaction updated')
                  : (AppLocalizations.of(context)?.transactionAdded ??
                      'Transaction added'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deleteTransaction ?? 'Delete Transaction'),
        content: Text(
          l10n?.deleteTransactionConfirmation ??
              'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteTransaction(context);
    }
  }

  Future<void> _deleteTransaction(BuildContext context) async {
    if (widget.transaction == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionRepo = ref.read(transactionRepositoryProvider);
      await transactionRepo.delete(widget.transaction!.id);

      // Invalidate providers to refresh data
      ref.invalidate(transactionListProvider);
      ref.invalidate(dashboardDataProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.transactionDeleted ??
                  'Transaction deleted',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
