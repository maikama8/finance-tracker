import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance_tracker/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/value_objects/date_range.dart';
import '../../application/state/transaction_list_provider.dart';
import '../../application/state/auth_provider.dart';
import 'add_edit_transaction_screen.dart';

/// Transaction list screen with filtering and pull-to-refresh
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  DateRange? _selectedDateRange;
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final transactionsAsync = ref.watch(
      transactionListProvider(TransactionListParams(
        userId: user.id,
        dateRange: _selectedDateRange,
        categoryId: _selectedCategoryId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.transactions ?? 'Transactions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.noTransactions ?? 'No transactions yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.addFirstTransaction ?? 'Add your first transaction',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionListProvider);
            },
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return TransactionListItem(
                  transaction: transaction,
                  onTap: () => _navigateToEdit(context, transaction),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        initialDateRange: _selectedDateRange,
        initialCategoryId: _selectedCategoryId,
        onApply: (dateRange, categoryId) {
          setState(() {
            _selectedDateRange = dateRange;
            _selectedCategoryId = categoryId;
          });
        },
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditTransactionScreen(),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTransactionScreen(
          transaction: transaction,
        ),
      ),
    );
  }
}

/// Transaction list item widget
class TransactionListItem extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryByIdProvider(transaction.categoryId));
    final dateFormat = DateFormat.yMMMd();

    return categoryAsync.when(
      loading: () => const ListTile(
        leading: CircularProgressIndicator(),
      ),
      error: (error, stack) => ListTile(
        title: Text('Error loading category'),
      ),
      data: (category) {
        final isIncome = transaction.type == TransactionType.income;
        final amountColor = isIncome ? Colors.green : Colors.red;
        final amountPrefix = isIncome ? '+' : '-';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: category?.colorValue ?? Colors.grey,
              child: Text(
                category?.icon ?? '?',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              category?.name ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(dateFormat.format(transaction.date)),
            trailing: Text(
              '$amountPrefix${transaction.currency.symbol}${transaction.amount}',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: onTap,
          ),
        );
      },
    );
  }
}

/// Filter dialog for date range and category
class FilterDialog extends ConsumerStatefulWidget {
  final DateRange? initialDateRange;
  final String? initialCategoryId;
  final Function(DateRange?, String?) onApply;

  const FilterDialog({
    super.key,
    this.initialDateRange,
    this.initialCategoryId,
    required this.onApply,
  });

  @override
  ConsumerState<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<FilterDialog> {
  DateRange? _dateRange;
  String? _categoryId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initialDateRange;
    _categoryId = widget.initialCategoryId;
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    
    if (user == null) {
      return const AlertDialog(
        title: Text('Error'),
        content: Text('User not authenticated'),
      );
    }

    final categoriesAsync = ref.watch(allCategoriesProvider(user.id));

    return AlertDialog(
      title: Text(l10n?.filterTransactions ?? 'Filter Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.dateRange ?? 'Date Range',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectStartDate(context),
                    child: Text(
                      _startDate != null
                          ? DateFormat.yMd().format(_startDate!)
                          : l10n?.startDate ?? 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectEndDate(context),
                    child: Text(
                      _endDate != null
                          ? DateFormat.yMd().format(_endDate!)
                          : l10n?.endDate ?? 'End Date',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.category ?? 'Category',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
              data: (categories) {
                return DropdownButtonFormField<String>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  hint: Text(l10n?.allCategories ?? 'All Categories'),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(l10n?.allCategories ?? 'All Categories'),
                    ),
                    ...categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Row(
                          children: [
                            Text(category.icon),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoryId = value;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _startDate = null;
              _endDate = null;
              _categoryId = null;
              _dateRange = null;
            });
            widget.onApply(null, null);
            Navigator.pop(context);
          },
          child: Text(l10n?.clearFilters ?? 'Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_startDate != null && _endDate != null) {
              _dateRange = DateRange(start: _startDate!, end: _endDate!);
            } else {
              _dateRange = null;
            }
            widget.onApply(_dateRange, _categoryId);
            Navigator.pop(context);
          },
          child: Text(l10n?.apply ?? 'Apply'),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }
}
