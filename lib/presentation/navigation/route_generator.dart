import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'app_routes.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/transaction_list_screen.dart';
import '../screens/add_edit_transaction_screen.dart';
import '../screens/category_list_screen.dart';
import '../screens/add_edit_category_screen.dart';
import '../screens/savings_goals_list_screen.dart';
import '../screens/add_edit_goal_screen.dart';
import '../screens/goal_detail_screen.dart';
import '../screens/budgets_list_screen.dart';
import '../screens/add_edit_budget_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/receipt_capture_screen.dart';
import '../screens/payment_gateway_selection_screen.dart';
import '../screens/payment_processing_screen.dart';
import '../screens/category_picker_screen.dart';
import '../screens/category_template_picker_screen.dart';
import '../screens/create_category_screen.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/entities/budget.dart';

/// Generates routes for the application with proper argument handling
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Auth routes
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // Main routes
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case AppRoutes.transactions:
        return MaterialPageRoute(builder: (_) => const TransactionListScreen());

      case AppRoutes.addTransaction:
        return MaterialPageRoute(
          builder: (_) => const AddEditTransactionScreen(),
        );

      case AppRoutes.editTransaction:
        if (args is Transaction) {
          return MaterialPageRoute(
            builder: (_) => AddEditTransactionScreen(transaction: args),
          );
        }
        return _errorRoute('Transaction required for edit');

      // Category routes
      case AppRoutes.categories:
        return MaterialPageRoute(builder: (_) => const CategoryListScreen());

      case AppRoutes.addCategory:
        return MaterialPageRoute(
          builder: (_) => const AddEditCategoryScreen(),
        );

      case AppRoutes.editCategory:
        if (args is Category) {
          return MaterialPageRoute(
            builder: (_) => AddEditCategoryScreen(category: args),
          );
        }
        return _errorRoute('Category required for edit');

      case AppRoutes.categoryPicker:
        return MaterialPageRoute(
          builder: (_) => const CategoryPickerScreen(),
        );

      case AppRoutes.categoryTemplatePicker:
        return MaterialPageRoute(
          builder: (_) => const CategoryTemplatePickerScreen(),
        );

      case AppRoutes.createCategory:
        return MaterialPageRoute(
          builder: (_) => const CreateCategoryScreen(),
        );

      // Savings goal routes
      case AppRoutes.savingsGoals:
        return MaterialPageRoute(
          builder: (_) => const SavingsGoalsListScreen(),
        );

      case AppRoutes.addGoal:
        return MaterialPageRoute(
          builder: (_) => const AddEditGoalScreen(),
        );

      case AppRoutes.editGoal:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => AddEditGoalScreen(goalId: args),
          );
        }
        return _errorRoute('Goal ID required for edit');

      case AppRoutes.goalDetail:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => GoalDetailScreen(goalId: args),
          );
        }
        return _errorRoute('Goal ID required for detail view');

      // Budget routes
      case AppRoutes.budgets:
        return MaterialPageRoute(builder: (_) => const BudgetsListScreen());

      case AppRoutes.addBudget:
        return MaterialPageRoute(
          builder: (_) => const AddEditBudgetScreen(),
        );

      case AppRoutes.editBudget:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => AddEditBudgetScreen(budgetId: args),
          );
        }
        return _errorRoute('Budget ID required for edit');

      // Report routes
      case AppRoutes.reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());

      // Settings routes
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      // Receipt routes
      case AppRoutes.receiptCapture:
        return MaterialPageRoute(
          builder: (_) => const ReceiptCaptureScreen(),
        );

      // Payment routes
      case AppRoutes.paymentGatewaySelection:
        if (args is Map<String, dynamic>) {
          final goalId = args['goalId'] as String?;
          final amount = args['amount'];
          final goalName = args['goalName'] as String?;
          if (goalId != null && amount != null && goalName != null) {
            return MaterialPageRoute(
              builder: (_) => PaymentGatewaySelectionScreen(
                goalId: goalId,
                amount: amount is Decimal ? amount : Decimal.parse(amount.toString()),
                goalName: goalName,
              ),
            );
          }
        }
        return _errorRoute('Goal ID, amount, and goal name required for payment');

      case AppRoutes.paymentProcessing:
        if (args is Map<String, dynamic>) {
          final session = args['session'];
          final goalId = args['goalId'] as String?;
          final amount = args['amount'];
          if (session != null && goalId != null && amount != null) {
            return MaterialPageRoute(
              builder: (_) => PaymentProcessingScreen(
                session: session,
                goalId: goalId,
                amount: amount is Decimal ? amount : Decimal.parse(amount.toString()),
              ),
            );
          }
        }
        return _errorRoute('Session, goal ID, and amount required');

      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  /// Creates an error route for invalid navigation
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Navigation Error: $message',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
