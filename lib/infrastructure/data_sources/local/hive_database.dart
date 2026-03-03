import 'package:hive_flutter/hive_flutter.dart';
import 'hive_type_adapters.dart';

/// Hive box names
class HiveBoxNames {
  static const String users = 'users';
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String savingsGoals = 'savings_goals';
  static const String budgets = 'budgets';
  static const String exchangeRates = 'exchange_rates';
  static const String syncQueue = 'sync_queue';
  static const String receiptImages = 'receipt_images';
}

/// Hive database manager for local storage
class HiveDatabase {
  static HiveDatabase? _instance;
  static HiveDatabase get instance => _instance ??= HiveDatabase._();

  HiveDatabase._();

  bool _isInitialized = false;

  /// Initialize Hive database with all type adapters and boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Hive with Flutter
    await Hive.initFlutter();

    // Register all type adapters
    _registerAdapters();

    // Open all boxes
    await _openBoxes();

    _isInitialized = true;
  }

  /// Register all Hive type adapters
  void _registerAdapters() {
    // Value object adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DecimalAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CurrencyAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ReminderFrequencyAdapter());
    }

    // Entity adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SavingsGoalAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(BudgetAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(NotificationPreferencesAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(LocaleAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(ExchangeRateAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(SyncQueueItemAdapter());
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(ReceiptImageMetadataAdapter());
    }
  }

  /// Open all Hive boxes
  Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox(HiveBoxNames.users),
      Hive.openBox(HiveBoxNames.transactions),
      Hive.openBox(HiveBoxNames.categories),
      Hive.openBox(HiveBoxNames.savingsGoals),
      Hive.openBox(HiveBoxNames.budgets),
      Hive.openBox(HiveBoxNames.exchangeRates),
      Hive.openBox(HiveBoxNames.syncQueue),
      Hive.openBox(HiveBoxNames.receiptImages),
    ]);
  }

  /// Get a specific box by name
  Box getBox(String boxName) {
    if (!_isInitialized) {
      throw StateError('HiveDatabase not initialized. Call initialize() first.');
    }
    return Hive.box(boxName);
  }

  /// Close all boxes and cleanup
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }

  /// Clear all data (useful for testing or logout)
  Future<void> clearAll() async {
    await Future.wait([
      getBox(HiveBoxNames.users).clear(),
      getBox(HiveBoxNames.transactions).clear(),
      getBox(HiveBoxNames.categories).clear(),
      getBox(HiveBoxNames.savingsGoals).clear(),
      getBox(HiveBoxNames.budgets).clear(),
      getBox(HiveBoxNames.exchangeRates).clear(),
      getBox(HiveBoxNames.syncQueue).clear(),
      getBox(HiveBoxNames.receiptImages).clear(),
    ]);
  }

  /// Delete all boxes (complete cleanup)
  Future<void> deleteAll() async {
    await Future.wait([
      Hive.deleteBoxFromDisk(HiveBoxNames.users),
      Hive.deleteBoxFromDisk(HiveBoxNames.transactions),
      Hive.deleteBoxFromDisk(HiveBoxNames.categories),
      Hive.deleteBoxFromDisk(HiveBoxNames.savingsGoals),
      Hive.deleteBoxFromDisk(HiveBoxNames.budgets),
      Hive.deleteBoxFromDisk(HiveBoxNames.exchangeRates),
      Hive.deleteBoxFromDisk(HiveBoxNames.syncQueue),
      Hive.deleteBoxFromDisk(HiveBoxNames.receiptImages),
    ]);
    _isInitialized = false;
  }
}
