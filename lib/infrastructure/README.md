# Infrastructure Layer

This layer contains implementations of domain interfaces and handles external dependencies.

## Structure

- **data_sources/**: Local (Hive) and remote (Firebase) data sources
- **repositories/**: Concrete implementations of domain repository interfaces
- **services/**: Concrete implementations of domain service interfaces (Auth, Currency, Sync, etc.)

## Rules

- Implements domain layer interfaces
- Handles data persistence (Hive, Firebase)
- Manages external API calls
- Contains platform-specific code
- Depends on domain layer only
