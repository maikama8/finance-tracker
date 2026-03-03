// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Rastreador de Finanzas Personales';

  @override
  String get dashboard => 'Panel de control';

  @override
  String get transactions => 'Transacciones';

  @override
  String get savingsGoals => 'Objetivos de ahorro';

  @override
  String get budgets => 'Presupuestos';

  @override
  String get settings => 'Configuración';

  @override
  String get totalBalance => 'Saldo total';

  @override
  String get monthlySpending => 'Gasto mensual';

  @override
  String get addTransaction => 'Agregar transacción';

  @override
  String get income => 'Ingreso';

  @override
  String get expense => 'Gasto';

  @override
  String get amount => 'Cantidad';

  @override
  String get category => 'Categoría';

  @override
  String get date => 'Fecha';

  @override
  String get notes => 'Notas';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get goalName => 'Nombre del objetivo';

  @override
  String get targetAmount => 'Cantidad objetivo';

  @override
  String get currentAmount => 'Cantidad actual';

  @override
  String get deadline => 'Fecha límite';

  @override
  String get contribute => 'Contribuir';

  @override
  String get progress => 'Progreso';

  @override
  String get budgetLimit => 'Límite de presupuesto';

  @override
  String get spent => 'Gastado';

  @override
  String get remaining => 'Restante';

  @override
  String get language => 'Idioma';

  @override
  String get currency => 'Moneda';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get exportData => 'Exportar datos';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get noTransactions => 'Aún no hay transacciones';

  @override
  String get noGoals => 'Aún no hay objetivos de ahorro';

  @override
  String get noBudgets => 'No hay presupuestos establecidos';

  @override
  String get budgetWarning =>
      'Has alcanzado el 80% de tu límite de presupuesto';

  @override
  String get budgetExceeded => '¡Límite de presupuesto excedido!';

  @override
  String get goalAchieved =>
      '¡Felicitaciones! ¡Has alcanzado tu objetivo de ahorro!';

  @override
  String get reminderTitle => 'Recordatorio de ahorro';

  @override
  String syncStatus(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get offlineMode => 'Modo sin conexión';

  @override
  String get loginSubtitle => 'Manage your finances securely';

  @override
  String get emailOrPhone => 'Email or Phone Number';

  @override
  String get emailOrPhoneHint => 'Enter your email or phone';

  @override
  String get emailOrPhoneRequired => 'Please enter email or phone';

  @override
  String get invalidEmailOrPhone => 'Invalid email or phone format';

  @override
  String get otpCode => 'OTP Code';

  @override
  String get otpCodeHint => 'Enter 6-digit code';

  @override
  String get otpRequired => 'Please enter OTP';

  @override
  String get otpInvalid => 'OTP must be 6 digits';

  @override
  String get otpExpiryNote => 'OTP expires in 5 minutes';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get verifyOtp => 'Verify OTP';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get or => 'OR';

  @override
  String get continueWith => 'Continue with';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithFacebook => 'Sign in with Facebook';

  @override
  String get privacyTerms =>
      'By continuing, you agree to our Terms of Service and Privacy Policy';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get noTransactionsYet => 'No Transactions Yet';

  @override
  String get noTransactionsDescription =>
      'Start tracking your finances by adding your first transaction. You can record income, expenses, and attach receipts.';

  @override
  String get addFirstTransaction => 'Add First Transaction';

  @override
  String get createSavingsGoal => 'Create Savings Goal';

  @override
  String get addTransactionComingSoon => 'Add transaction feature coming soon!';

  @override
  String get savingsGoalsComingSoon => 'Savings goals feature coming soon!';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get amountMustBePositive => 'Amount must be positive';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get optional => 'Optional';

  @override
  String get receiptPhoto => 'Receipt Photo';

  @override
  String get receiptAttached => 'Receipt attached';

  @override
  String get remove => 'Remove';

  @override
  String get captureReceipt => 'Capture Receipt';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get pleaseFillAllFields => 'Please fill all required fields';

  @override
  String get transactionUpdated => 'Transaction updated';

  @override
  String get transactionAdded => 'Transaction added';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get deleteTransactionConfirmation =>
      'Are you sure you want to delete this transaction? This action cannot be undone.';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get filterTransactions => 'Filter Transactions';

  @override
  String get dateRange => 'Date Range';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get allCategories => 'All Categories';

  @override
  String get clearFilters => 'Clear';

  @override
  String get apply => 'Apply';

  @override
  String get noCategories => 'No categories yet';

  @override
  String get createFirstCategory => 'Create your first category';

  @override
  String get createCategory => 'Create Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get pleaseEnterCategoryName => 'Please enter a category name';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get selectColor => 'Select Color';

  @override
  String get categoryPreview => 'Category Preview';

  @override
  String get subcategoryOf => 'Subcategory of';

  @override
  String get categoryCreated => 'Category created successfully';

  @override
  String get noImageSelected => 'No image selected';

  @override
  String get retake => 'Retake';

  @override
  String get extractData => 'Extract Data';

  @override
  String get dataExtracted => 'Data Extracted';

  @override
  String get merchant => 'Merchant';

  @override
  String get confidence => 'Confidence';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get confirm => 'Confirm';

  @override
  String get skipOCR => 'Skip OCR and enter manually';

  @override
  String get ocrFailed =>
      'OCR extraction failed. You can still attach the receipt and enter data manually.';

  @override
  String get categories => 'Categories';

  @override
  String get categoryTemplates => 'Category Templates';

  @override
  String get errorLoadingCategories => 'Error loading categories';

  @override
  String get noCategoriesYet => 'No Categories Yet';

  @override
  String get addCategoryToGetStarted =>
      'Add a category to get started organizing your transactions';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get categoryNameRequired => 'Category name is required';

  @override
  String get tapToSelectIcon => 'Tap to select an icon';

  @override
  String get tapToSelectColor => 'Tap to select a color';

  @override
  String get parentCategory => 'Parent Category';

  @override
  String get noneRootCategory => 'None (Root Category)';

  @override
  String get categorySaved => 'Category saved';

  @override
  String get categoryAdded => 'Category added';

  @override
  String get errorSavingCategory => 'Error saving category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String deleteCategoryWarning(String name) {
    return 'Are you sure you want to delete \"$name\"? All transactions in this category will be reassigned.';
  }

  @override
  String get selectReassignCategory =>
      'Select a category to reassign transactions to:';

  @override
  String get cannotDeleteLastCategory =>
      'Cannot delete the last category. Please create another category first.';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get errorDeletingCategory => 'Error deleting category';

  @override
  String get selectTemplateForYourRegion =>
      'Select a category template that matches your region and lifestyle';

  @override
  String andMoreCategories(int count) {
    return 'and $count more...';
  }

  @override
  String get applyTemplate => 'Apply Template';

  @override
  String get templateApplied => 'Template applied successfully';

  @override
  String get errorApplyingTemplate => 'Error applying template';

  @override
  String get reports => 'Reports';

  @override
  String get export => 'Export';

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get spendingTrends => 'Spending Trends';

  @override
  String get insights => 'Insights';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get last90Days => 'Last 90 Days';

  @override
  String get thisYear => 'This Year';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get exportReport => 'Export Report';

  @override
  String get exportPdf => 'Export as PDF';

  @override
  String get exportCsv => 'Export as CSV';

  @override
  String get generatingReport => 'Generating report...';

  @override
  String get reportGenerated => 'Report generated successfully';
}
