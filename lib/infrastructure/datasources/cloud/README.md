# Cloud Data Sources

This directory contains Firebase Firestore data source implementations for remote data storage and synchronization.

## Overview

Cloud data sources handle all remote CRUD operations for the Personal Finance Tracker application. They work in conjunction with local data sources to support the offline-first architecture.

## Data Sources

### 1. UserCloudDataSource
- **Collection**: `users`
- **Operations**: Create, Read, Update, Delete
- **Features**:
  - User profile management
  - Locale and currency preferences
  - Notification preferences

### 2. TransactionCloudDataSource
- **Collection**: `transactions`
- **Operations**: Create, Read, Update, Delete, Batch operations
- **Features**:
  - Transaction CRUD with filtering (date range, category, type)
  - Real-time updates via streams
  - Sync status tracking
  - Batch operations for efficient syncing

### 3. CategoryCloudDataSource
- **Collection**: `categories`
- **Operations**: Create, Read, Update, Delete, Batch operations
- **Features**:
  - Custom and default categories
  - Category hierarchy support
  - Locale-specific default categories
  - Batch operations

### 4. SavingsGoalCloudDataSource
- **Collection**: `savings_goals`
- **Operations**: Create, Read, Update, Delete, Batch operations
- **Features**:
  - Goal lifecycle management
  - Active, completed, and overdue goal queries
  - Reminder tracking
  - Real-time updates via streams

### 5. BudgetCloudDataSource
- **Collection**: `budgets`
- **Operations**: Create, Read, Update, Delete, Batch operations
- **Features**:
  - Monthly budget management
  - Budget tracking by category and month
  - Alert detection (near/over limit)
  - Monthly reset functionality

### 6. ExchangeRateCloudDataSource
- **Collection**: `exchange_rates`
- **Operations**: Read, Upsert (primarily read-only)
- **Features**:
  - Exchange rate caching
  - Expiry tracking
  - Batch upsert for efficient updates
  - Cleanup of expired rates

## Authentication

All cloud data sources automatically use Firebase Authentication tokens. The Firebase SDK handles authentication state and includes the user's auth token in all requests.

## Error Handling

Cloud data sources throw exceptions for:
- Network errors
- Permission denied (Firestore security rules)
- Document not found
- Invalid data format

These exceptions should be caught and handled by the repository layer.

## Data Conversion

Each data source includes:
- `_toFirestore()`: Converts domain entities to Firestore documents
- `_fromFirestore()`: Converts Firestore documents to domain entities

### Key Conversion Patterns

1. **Decimal Values**: Stored as strings to preserve precision
   ```dart
   'amount': transaction.amount.toString()
   amount: Decimal.parse(data['amount'] as String)
   ```

2. **Enums**: Stored as strings using `.name`
   ```dart
   'type': transaction.type.name
   type: TransactionType.values.firstWhere((e) => e.name == data['type'])
   ```

3. **DateTime**: Converted to/from Firestore Timestamps
   ```dart
   'createdAt': Timestamp.fromDate(entity.createdAt)
   createdAt: (data['createdAt'] as Timestamp).toDate()
   ```

4. **Complex Objects**: Stored as nested maps
   ```dart
   'currency': {
     'code': currency.code,
     'symbol': currency.symbol,
     ...
   }
   ```

## Sync Status

Entities that support offline-first sync include a `syncStatus` field:
- `synced`: Data is synchronized with cloud
- `pending`: Local changes waiting to be synced
- `conflict`: Sync conflict detected

## Batch Operations

All data sources support batch operations for efficient syncing:
- `batchCreate()`: Create multiple documents in one transaction
- `batchUpdate()`: Update multiple documents in one transaction
- `batchDelete()`: Delete multiple documents in one transaction

Batch operations use Firestore batch writes (max 500 operations per batch).

## Real-Time Updates

Data sources provide stream-based methods for real-time updates:
- `watchAll()`: Stream of all entities for a user
- `watchGoal()`: Stream of a specific savings goal
- `watchByMonth()`: Stream of budgets for a specific month

## Firestore Security Rules

The following security rules should be configured in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Categories collection
    match /categories/{categoryId} {
      // Allow read for default categories and user's custom categories
      allow read: if isAuthenticated() && 
        (resource.data.isDefault == true || resource.data.userId == request.auth.uid);
      // Allow write only for user's custom categories
      allow write: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
    }
    
    // Savings goals collection
    match /savings_goals/{goalId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Budgets collection
    match /budgets/{budgetId} {
      allow read, write: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Exchange rates collection (read-only for clients)
    match /exchange_rates/{rateId} {
      allow read: if isAuthenticated();
      allow write: if false; // Only server can write
    }
  }
}
```

## Usage Example

```dart
// Initialize Firestore
final firestore = FirebaseFirestore.instance;

// Create data source
final transactionDataSource = TransactionCloudDataSource(firestore);

// Create a transaction
final transaction = Transaction(
  id: 'txn_123',
  userId: 'user_456',
  amount: Decimal.parse('50.00'),
  currency: Currency.USD,
  type: TransactionType.expense,
  categoryId: 'cat_789',
  date: DateTime.now(),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await transactionDataSource.create(transaction);

// Query transactions
final transactions = await transactionDataSource.getAll(
  userId: 'user_456',
  dateRange: DateRange(
    start: DateTime(2024, 1, 1),
    end: DateTime(2024, 1, 31),
  ),
);

// Watch for real-time updates
transactionDataSource.watchAll(userId: 'user_456').listen((transactions) {
  print('Transactions updated: ${transactions.length}');
});
```

## Testing

Cloud data sources should be tested with:
1. Firebase Emulator Suite for local testing
2. Mock Firestore instances for unit tests
3. Integration tests with test Firebase project

## Performance Considerations

1. **Indexing**: Create composite indexes for complex queries
2. **Pagination**: Implement pagination for large result sets
3. **Caching**: Use local cache for frequently accessed data
4. **Batch Operations**: Use batch writes for multiple operations
5. **Query Optimization**: Minimize the number of queries and use appropriate filters

## Related Files

- Local data sources: `lib/infrastructure/datasources/local/`
- Domain entities: `lib/domain/entities/`
- Sync manager: `lib/infrastructure/services/sync_manager_impl.dart`
