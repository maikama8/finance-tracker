// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '个人财务追踪器';

  @override
  String get dashboard => '仪表板';

  @override
  String get transactions => '交易';

  @override
  String get savingsGoals => '储蓄目标';

  @override
  String get budgets => '预算';

  @override
  String get settings => '设置';

  @override
  String get totalBalance => '总余额';

  @override
  String get monthlySpending => '月度支出';

  @override
  String get addTransaction => '添加交易';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get amount => '金额';

  @override
  String get category => '类别';

  @override
  String get date => '日期';

  @override
  String get notes => '备注';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get goalName => '目标名称';

  @override
  String get targetAmount => '目标金额';

  @override
  String get currentAmount => '当前金额';

  @override
  String get deadline => '截止日期';

  @override
  String get contribute => '贡献';

  @override
  String get progress => '进度';

  @override
  String get budgetLimit => '预算限额';

  @override
  String get spent => '已花费';

  @override
  String get remaining => '剩余';

  @override
  String get language => '语言';

  @override
  String get currency => '货币';

  @override
  String get notifications => '通知';

  @override
  String get exportData => '导出数据';

  @override
  String get signOut => '退出登录';

  @override
  String get noTransactions => '暂无交易';

  @override
  String get noGoals => '暂无储蓄目标';

  @override
  String get noBudgets => '未设置预算';

  @override
  String get budgetWarning => '您已达到预算限额的80%';

  @override
  String get budgetExceeded => '预算限额已超出！';

  @override
  String get goalAchieved => '恭喜！您已达成储蓄目标！';

  @override
  String get reminderTitle => '储蓄提醒';

  @override
  String syncStatus(String time) {
    return '上次同步：$time';
  }

  @override
  String get offlineMode => '离线模式';

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
