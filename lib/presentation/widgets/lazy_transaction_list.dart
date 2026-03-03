import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';

/// Lazy loading list widget for transactions with pagination
class LazyTransactionList extends StatefulWidget {
  final Future<List<Transaction>> Function(int page, int pageSize) loadPage;
  final Widget Function(BuildContext, Transaction) itemBuilder;
  final int pageSize;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const LazyTransactionList({
    super.key,
    required this.loadPage,
    required this.itemBuilder,
    this.pageSize = 20,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  State<LazyTransactionList> createState() => _LazyTransactionListState();
}

class _LazyTransactionListState extends State<LazyTransactionList> {
  final List<Transaction> _transactions = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newTransactions = await widget.loadPage(
        _currentPage,
        widget.pageSize,
      );

      setState(() {
        _transactions.addAll(newTransactions);
        _currentPage++;
        _hasMore = newTransactions.length == widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _transactions.clear();
      _currentPage = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _transactions.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading transactions'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (_transactions.isEmpty && !_isLoading) {
      return widget.emptyWidget ??
          const Center(
            child: Text('No transactions found'),
          );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _transactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return widget.loadingWidget ??
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
          }

          return widget.itemBuilder(context, _transactions[index]);
        },
      ),
    );
  }
}
