import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loading state for different operations
class LoadingState {
  final bool isLoading;
  final String? message;
  final double? progress;

  const LoadingState({
    this.isLoading = false,
    this.message,
    this.progress,
  });

  LoadingState copyWith({
    bool? isLoading,
    String? message,
    double? progress,
  }) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}

/// Provider for managing loading states across the app
class LoadingStateNotifier extends StateNotifier<Map<String, LoadingState>> {
  LoadingStateNotifier() : super({});

  /// Starts loading for a specific operation
  void startLoading(String operationKey, {String? message}) {
    state = {
      ...state,
      operationKey: LoadingState(isLoading: true, message: message),
    };
  }

  /// Updates loading progress
  void updateProgress(String operationKey, double progress, {String? message}) {
    final currentState = state[operationKey];
    if (currentState != null) {
      state = {
        ...state,
        operationKey: currentState.copyWith(
          progress: progress,
          message: message,
        ),
      };
    }
  }

  /// Stops loading for a specific operation
  void stopLoading(String operationKey) {
    final newState = Map<String, LoadingState>.from(state);
    newState.remove(operationKey);
    state = newState;
  }

  /// Checks if any operation is loading
  bool get isAnyLoading => state.values.any((s) => s.isLoading);

  /// Gets loading state for a specific operation
  LoadingState? getLoadingState(String operationKey) => state[operationKey];
}

/// Global loading state provider
final loadingStateProvider =
    StateNotifierProvider<LoadingStateNotifier, Map<String, LoadingState>>(
  (ref) => LoadingStateNotifier(),
);

/// Provider for checking if a specific operation is loading
final isLoadingProvider = Provider.family<bool, String>((ref, operationKey) {
  final loadingStates = ref.watch(loadingStateProvider);
  return loadingStates[operationKey]?.isLoading ?? false;
});

/// Provider for getting loading message for a specific operation
final loadingMessageProvider = Provider.family<String?, String>((ref, operationKey) {
  final loadingStates = ref.watch(loadingStateProvider);
  return loadingStates[operationKey]?.message;
});

/// Provider for getting loading progress for a specific operation
final loadingProgressProvider = Provider.family<double?, String>((ref, operationKey) {
  final loadingStates = ref.watch(loadingStateProvider);
  return loadingStates[operationKey]?.progress;
});

/// Common operation keys
class LoadingKeys {
  static const String fetchTransactions = 'fetch_transactions';
  static const String createTransaction = 'create_transaction';
  static const String updateTransaction = 'update_transaction';
  static const String deleteTransaction = 'delete_transaction';
  
  static const String fetchGoals = 'fetch_goals';
  static const String createGoal = 'create_goal';
  static const String updateGoal = 'update_goal';
  static const String contributeToGoal = 'contribute_to_goal';
  
  static const String fetchBudgets = 'fetch_budgets';
  static const String createBudget = 'create_budget';
  static const String updateBudget = 'update_budget';
  
  static const String fetchCategories = 'fetch_categories';
  static const String createCategory = 'create_category';
  
  static const String generateReport = 'generate_report';
  static const String exportData = 'export_data';
  
  static const String syncData = 'sync_data';
  static const String processPayment = 'process_payment';
  static const String processReceipt = 'process_receipt';
}
