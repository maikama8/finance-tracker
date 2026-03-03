// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'व्यक्तिगत वित्त ट्रैकर';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get transactions => 'लेन-देन';

  @override
  String get savingsGoals => 'बचत लक्ष्य';

  @override
  String get budgets => 'बजट';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get totalBalance => 'कुल शेष';

  @override
  String get monthlySpending => 'मासिक खर्च';

  @override
  String get addTransaction => 'लेन-देन जोड़ें';

  @override
  String get income => 'आय';

  @override
  String get expense => 'व्यय';

  @override
  String get amount => 'राशि';

  @override
  String get category => 'श्रेणी';

  @override
  String get date => 'तारीख';

  @override
  String get notes => 'नोट्स';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get goalName => 'लक्ष्य का नाम';

  @override
  String get targetAmount => 'लक्ष्य राशि';

  @override
  String get currentAmount => 'वर्तमान राशि';

  @override
  String get deadline => 'समय सीमा';

  @override
  String get contribute => 'योगदान करें';

  @override
  String get progress => 'प्रगति';

  @override
  String get budgetLimit => 'बजट सीमा';

  @override
  String get spent => 'खर्च किया';

  @override
  String get remaining => 'शेष';

  @override
  String get language => 'भाषा';

  @override
  String get currency => 'मुद्रा';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get exportData => 'डेटा निर्यात करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get noTransactions => 'अभी तक कोई लेन-देन नहीं';

  @override
  String get noGoals => 'अभी तक कोई बचत लक्ष्य नहीं';

  @override
  String get noBudgets => 'कोई बजट निर्धारित नहीं';

  @override
  String get budgetWarning => 'आप अपनी बजट सीमा के 80% तक पहुंच गए हैं';

  @override
  String get budgetExceeded => 'बजट सीमा पार हो गई!';

  @override
  String get goalAchieved => 'बधाई हो! आपने अपना बचत लक्ष्य हासिल कर लिया है!';

  @override
  String get reminderTitle => 'बचत अनुस्मारक';

  @override
  String syncStatus(String time) {
    return 'अंतिम समन्वयन: $time';
  }

  @override
  String get offlineMode => 'ऑफ़लाइन मोड';

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
