/// Centralized route names for the application
class AppRoutes {
  // Auth routes
  static const String login = '/login';
  
  // Main routes
  static const String dashboard = '/';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String editTransaction = '/transactions/edit';
  
  // Category routes
  static const String categories = '/categories';
  static const String addCategory = '/categories/add';
  static const String editCategory = '/categories/edit';
  static const String categoryPicker = '/categories/picker';
  static const String categoryTemplatePicker = '/categories/template-picker';
  static const String createCategory = '/categories/create';
  
  // Savings goal routes
  static const String savingsGoals = '/goals';
  static const String addGoal = '/goals/add';
  static const String editGoal = '/goals/edit';
  static const String goalDetail = '/goals/detail';
  
  // Budget routes
  static const String budgets = '/budgets';
  static const String addBudget = '/budgets/add';
  static const String editBudget = '/budgets/edit';
  
  // Report routes
  static const String reports = '/reports';
  
  // Settings routes
  static const String settings = '/settings';
  
  // Receipt routes
  static const String receiptCapture = '/receipt/capture';
  
  // Payment routes
  static const String paymentGatewaySelection = '/payment/gateway-selection';
  static const String paymentProcessing = '/payment/processing';
}
