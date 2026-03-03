/// Helper class for implementing pagination in repositories
class PaginationHelper<T> {
  final List<T> _allItems;
  final int pageSize;

  PaginationHelper(this._allItems, {this.pageSize = 20});

  /// Gets a page of items
  List<T> getPage(int pageNumber) {
    final startIndex = pageNumber * pageSize;
    
    if (startIndex >= _allItems.length) {
      return [];
    }

    final endIndex = (startIndex + pageSize).clamp(0, _allItems.length);
    return _allItems.sublist(startIndex, endIndex);
  }

  /// Gets total number of pages
  int get totalPages => (_allItems.length / pageSize).ceil();

  /// Checks if a page exists
  bool hasPage(int pageNumber) => pageNumber < totalPages;

  /// Gets total number of items
  int get totalItems => _allItems.length;
}

/// Paginated result wrapper
class PaginatedResult<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  })  : hasNextPage = currentPage < totalPages - 1,
        hasPreviousPage = currentPage > 0;

  factory PaginatedResult.fromHelper(
    PaginationHelper<T> helper,
    int pageNumber,
  ) {
    return PaginatedResult(
      items: helper.getPage(pageNumber),
      currentPage: pageNumber,
      totalPages: helper.totalPages,
      totalItems: helper.totalItems,
    );
  }
}

/// Cursor-based pagination for efficient large dataset queries
class CursorPagination<T> {
  final List<T> items;
  final String? nextCursor;
  final String? previousCursor;
  final bool hasMore;

  CursorPagination({
    required this.items,
    this.nextCursor,
    this.previousCursor,
    required this.hasMore,
  });
}
