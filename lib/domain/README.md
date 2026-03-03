# Domain Layer

This layer contains the core business logic and is independent of any external frameworks or libraries.

## Structure

- **entities/**: Core business objects (Transaction, Category, SavingsGoal, Budget, User)
- **value_objects/**: Immutable value objects (Currency, DateRange, ExchangeRate)
- **repositories/**: Abstract repository interfaces
- **services/**: Domain service interfaces

## Rules

- No dependencies on other layers
- Pure Dart code only (no Flutter dependencies)
- Business logic and domain rules live here
- All classes should be immutable where possible
