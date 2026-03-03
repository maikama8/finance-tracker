# Local Storage Layer

This directory contains the local storage implementation using Hive for the Personal Finance Tracker application.

## Overview

The local storage layer provides offline-first data persistence for all core entities:
- Users
- Transactions
- Categories
- Savings Goals
- Budgets
- Exchange Rates
- Sync Queue
- Receipt Image Metadata

## Architecture

### Hive Database Setup

The `HiveDatabase` class manages initialization and provides access to all Hive boxes:

```dart
// Initialize the database
await HiveDatabase.instance.initialize();

// Get a specific box
final box = HiveDatabase.instance.getBox(HiveBoxNames.transactions);
```

### Type Adapters

All domain models have custom Hive type adapters for efficient serialization:
- `DecimalAdapter` - Handles Decimal precision for monetary values
- `CurrencyAdapter` - Serializes Currency value objects
- `TransactionAdapter` - Serializes Transaction entities
- `CategoryAdapter` - Serializes Category entities
- `SavingsGoalAdapter` - Serializes SavingsGoal entities
- `BudgetAdapter` - Serializes Budget entities
- `ExchangeRateAdapter` - Serializes ExchangeRate value objects
- And more...

### Data Sources

Each entity has a dedicated local data source with CRUD operations:

#### TransactionLocalDataSource
- Create, update, delete transactions
- Query by date range, category, type
- Track sync status
- Batch operations

#### CategoryLocalDataSource
- Manage categories with hierarchy support
- Get default and custom categories
- Check for circular references
- Query by locale

#### SavingsGoalLocalDataSource
- Manage savings goals
- Track contributions
- Handle reminders
- Calculate progress

#### BudgetLocalDataSource
- Manage monthly budgets
- Track spending
- Reset budgets monthly
- Alert on thresholds

#### ExchangeRateLocalDataSource
- Store and retrieve exchange rates
- Handle cache expiry
- Batch operations for multiple currencies

#### UserLocalDataSource
- Store user profile
- Single user per device

#### SyncQueueLocalDataSource
- Queue pending sync operations
- Track retry counts
- Manage sync conflicts

#### ReceiptImageLocalDataSource
- Store receipt image metadata
- Track storage usage
- Link to transactions

## Usage Example

```dart
// Initialize database
await HiveDatabase.instance.initialize();

// Create data sources
final transactionDataSource = TransactionLocalDataSource(HiveDatabase.instance);
final categoryDataSource = CategoryLocalDataSource(HiveDatabase.instance);

// Create a transaction
final transaction = Transaction(
  id: 'tx_123',
  userId: 'user_1',
  amount: Decimal.parse('50.00'),
  currency: Currency.USD,
  type: TransactionType.expense,
  categoryId: 'cat_food',
  date: DateTime.now(),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await transactionDataSource.create(transaction);

// Query transactions
final allTransactions = await transactionDataSource.getAll(userId: 'user_1');
final expenseTransactions = await transactionDataSource.getByType(
  userId: 'user_1',
  type: TransactionType.expense,
);

// Watch for changes
transactionDataSource.watchAll(userId: 'user_1').listen((transactions) {
  print('Transactions updated: ${transactions.length}');
});
```

## Features

### Offline-First
All data is stored locally first, enabling full app functionality without internet connectivity.

### Reactive Streams
All data sources provide `watch` methods that return streams for real-time updates.

### Batch Operations
Support for batch create, update, and delete operations for better performance.

### Query Capabilities
- Filter by date range
- Filter by category
- Filter by type (income/expense)
- Filter by sync status
- Category hierarchy queries
- Budget tracking by month/year

### Sync Support
- Track pending sync operations
- Handle sync conflicts
- Retry failed syncs

### Data Integrity
- Type-safe serialization with Hive adapters
- Decimal precision for monetary values
- Proper handling of nullable fields
- Validation in data sources

## Box Names

All Hive boxes are defined in `HiveBoxNames`:
- `users` - User profiles
- `transactions` - Transaction records
- `categories` - Category definitions
- `savings_goals` - Savings goal data
- `budgets` - Budget configurations
- `exchange_rates` - Currency exchange rates
- `sync_queue` - Pending sync operations
- `receipt_images` - Receipt metadata

## Type IDs

Type adapters use the following type IDs:
- 0-4: Value objects (Decimal, Currency, enums)
- 10-19: Entities (Transaction, Category, etc.)

## Testing

To test the local storage layer:

```dart
// Clear all data
await HiveDatabase.instance.clearAll();

// Delete all boxes
await HiveDatabase.instance.deleteAll();
```

## Requirements Validated

This implementation validates the following requirements:
- 11.1: Offline-first operation with local storage
- 14.1: Data serialization to JSON format
- 14.2: Data parsing with validation
- 3.1, 3.4, 3.5: Transaction management
- 4.3, 4.4, 4.5: Category management
- 6.1, 6.2, 6.3: Savings goal management
- 8.1, 8.2, 8.5: Budget management
- 9.4, 9.5: Exchange rate caching
