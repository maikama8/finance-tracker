# Application Layer

This layer orchestrates the flow of data between domain and presentation layers.

## Structure

- **use_cases/**: Application-specific business logic and workflows
- **state/**: Riverpod providers and state management

## Rules

- Coordinates domain objects and services
- Contains use cases (e.g., AddTransaction, CreateSavingsGoal)
- Manages application state with Riverpod
- Depends on domain and infrastructure layers
- No UI code
