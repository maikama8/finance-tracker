# Presentation Layer

This layer contains all UI components and user interaction logic.

## Structure

- **screens/**: Full-page screens (Dashboard, Transactions, Goals, Budgets, Settings)
- **widgets/**: Reusable UI components
- **theme/**: App theme configuration (colors, typography, etc.)

## Rules

- Contains Flutter widgets only
- Consumes application layer state
- Handles user input and navigation
- Depends on application layer
- Should be as thin as possible (minimal logic)
