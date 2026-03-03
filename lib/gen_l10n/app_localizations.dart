import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Personal Finance Tracker'**
  String get appTitle;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Transactions screen title
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// Savings goals screen title
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get savingsGoals;

  /// Budgets screen title
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for total balance
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// Label for monthly spending
  ///
  /// In en, this message translates to:
  /// **'Monthly Spending'**
  String get monthlySpending;

  /// Button to add a new transaction
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// Income transaction type
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// Expense transaction type
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// Label for amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Label for category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Label for date field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Label for notes field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Label for savings goal name
  ///
  /// In en, this message translates to:
  /// **'Goal Name'**
  String get goalName;

  /// Label for target amount
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get targetAmount;

  /// Label for current amount
  ///
  /// In en, this message translates to:
  /// **'Current Amount'**
  String get currentAmount;

  /// Label for deadline
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// Button to contribute to a goal
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get contribute;

  /// Label for progress
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Label for budget limit
  ///
  /// In en, this message translates to:
  /// **'Budget Limit'**
  String get budgetLimit;

  /// Label for amount spent
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// Label for remaining amount
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// Label for language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for currency setting
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// Label for notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Button to export data
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Button to sign out
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Empty state message for transactions
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// Empty state message for savings goals
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get noGoals;

  /// Empty state message for budgets
  ///
  /// In en, this message translates to:
  /// **'No budgets set'**
  String get noBudgets;

  /// Budget warning notification
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached 80% of your budget limit'**
  String get budgetWarning;

  /// Budget exceeded notification
  ///
  /// In en, this message translates to:
  /// **'Budget limit exceeded!'**
  String get budgetExceeded;

  /// Goal achievement notification
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve reached your savings goal!'**
  String get goalAchieved;

  /// Title for savings reminder notification
  ///
  /// In en, this message translates to:
  /// **'Savings Reminder'**
  String get reminderTitle;

  /// Sync status message
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String syncStatus(String time);

  /// Offline mode indicator
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// Subtitle on login screen
  ///
  /// In en, this message translates to:
  /// **'Manage your finances securely'**
  String get loginSubtitle;

  /// Label for email or phone input
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get emailOrPhone;

  /// Hint for email or phone input
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone'**
  String get emailOrPhoneHint;

  /// Validation message for required email or phone
  ///
  /// In en, this message translates to:
  /// **'Please enter email or phone'**
  String get emailOrPhoneRequired;

  /// Validation message for invalid email or phone
  ///
  /// In en, this message translates to:
  /// **'Invalid email or phone format'**
  String get invalidEmailOrPhone;

  /// Label for OTP input
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// Hint for OTP input
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get otpCodeHint;

  /// Validation message for required OTP
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP'**
  String get otpRequired;

  /// Validation message for invalid OTP
  ///
  /// In en, this message translates to:
  /// **'OTP must be 6 digits'**
  String get otpInvalid;

  /// Note about OTP expiry time
  ///
  /// In en, this message translates to:
  /// **'OTP expires in 5 minutes'**
  String get otpExpiryNote;

  /// Button to send OTP
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// Button to verify OTP
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// Button to resend OTP
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// Divider text between authentication methods
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Text before social login options
  ///
  /// In en, this message translates to:
  /// **'Continue with'**
  String get continueWith;

  /// Button to sign in with Google
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Button to sign in with Apple
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// Button to sign in with Facebook
  ///
  /// In en, this message translates to:
  /// **'Sign in with Facebook'**
  String get signInWithFacebook;

  /// Privacy and terms notice
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy'**
  String get privacyTerms;

  /// Error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Empty state title when no transactions exist
  ///
  /// In en, this message translates to:
  /// **'No Transactions Yet'**
  String get noTransactionsYet;

  /// Empty state description when no transactions exist
  ///
  /// In en, this message translates to:
  /// **'Start tracking your finances by adding your first transaction. You can record income, expenses, and attach receipts.'**
  String get noTransactionsDescription;

  /// Button to add first transaction
  ///
  /// In en, this message translates to:
  /// **'Add First Transaction'**
  String get addFirstTransaction;

  /// Button to create savings goal
  ///
  /// In en, this message translates to:
  /// **'Create Savings Goal'**
  String get createSavingsGoal;

  /// Message for add transaction feature
  ///
  /// In en, this message translates to:
  /// **'Add transaction feature coming soon!'**
  String get addTransactionComingSoon;

  /// Message for savings goals feature
  ///
  /// In en, this message translates to:
  /// **'Savings goals feature coming soon!'**
  String get savingsGoalsComingSoon;

  /// Title for edit transaction screen
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// Validation message for amount field
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get pleaseEnterAmount;

  /// Validation message for positive amount
  ///
  /// In en, this message translates to:
  /// **'Amount must be positive'**
  String get amountMustBePositive;

  /// Validation message for invalid amount
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// Validation message for category selection
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// Placeholder for category selection
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// Label for optional fields
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// Label for receipt photo section
  ///
  /// In en, this message translates to:
  /// **'Receipt Photo'**
  String get receiptPhoto;

  /// Message when receipt is attached
  ///
  /// In en, this message translates to:
  /// **'Receipt attached'**
  String get receiptAttached;

  /// Button to remove item
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Button to capture receipt
  ///
  /// In en, this message translates to:
  /// **'Capture Receipt'**
  String get captureReceipt;

  /// Button to save changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Validation message for required fields
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillAllFields;

  /// Success message for transaction update
  ///
  /// In en, this message translates to:
  /// **'Transaction updated'**
  String get transactionUpdated;

  /// Success message for transaction creation
  ///
  /// In en, this message translates to:
  /// **'Transaction added'**
  String get transactionAdded;

  /// Title for delete transaction dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// Confirmation message for transaction deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction? This action cannot be undone.'**
  String get deleteTransactionConfirmation;

  /// Success message for transaction deletion
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// Title for filter dialog
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// Label for date range filter
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// Label for start date
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// Label for end date
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// Option for all categories filter
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// Button to clear filters
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilters;

  /// Button to apply filters
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Empty state message for categories
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategories;

  /// Empty state description for categories
  ///
  /// In en, this message translates to:
  /// **'Create your first category'**
  String get createFirstCategory;

  /// Button to create category
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// Label for category name field
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// Validation message for category name
  ///
  /// In en, this message translates to:
  /// **'Please enter a category name'**
  String get pleaseEnterCategoryName;

  /// Label for icon selection
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get selectIcon;

  /// Label for color selection
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// Label for category preview
  ///
  /// In en, this message translates to:
  /// **'Category Preview'**
  String get categoryPreview;

  /// Label for parent category
  ///
  /// In en, this message translates to:
  /// **'Subcategory of'**
  String get subcategoryOf;

  /// Success message for category creation
  ///
  /// In en, this message translates to:
  /// **'Category created successfully'**
  String get categoryCreated;

  /// Message when no image is selected
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// Button to retake photo
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// Button to extract data from receipt
  ///
  /// In en, this message translates to:
  /// **'Extract Data'**
  String get extractData;

  /// Message when data is extracted
  ///
  /// In en, this message translates to:
  /// **'Data Extracted'**
  String get dataExtracted;

  /// Label for merchant name
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// Label for OCR confidence score
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// Button to take photo
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Button to choose from gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Button to confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Button to skip OCR
  ///
  /// In en, this message translates to:
  /// **'Skip OCR and enter manually'**
  String get skipOCR;

  /// Message when OCR fails
  ///
  /// In en, this message translates to:
  /// **'OCR extraction failed. You can still attach the receipt and enter data manually.'**
  String get ocrFailed;

  /// Categories screen title
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Category templates screen title
  ///
  /// In en, this message translates to:
  /// **'Category Templates'**
  String get categoryTemplates;

  /// Error message when categories fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorLoadingCategories;

  /// Empty state title when no categories exist
  ///
  /// In en, this message translates to:
  /// **'No Categories Yet'**
  String get noCategoriesYet;

  /// Empty state description for categories
  ///
  /// In en, this message translates to:
  /// **'Add a category to get started organizing your transactions'**
  String get addCategoryToGetStarted;

  /// Button to add category
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// Title for edit category screen
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// Validation message for category name
  ///
  /// In en, this message translates to:
  /// **'Category name is required'**
  String get categoryNameRequired;

  /// Hint for icon selection
  ///
  /// In en, this message translates to:
  /// **'Tap to select an icon'**
  String get tapToSelectIcon;

  /// Hint for color selection
  ///
  /// In en, this message translates to:
  /// **'Tap to select a color'**
  String get tapToSelectColor;

  /// Label for parent category selection
  ///
  /// In en, this message translates to:
  /// **'Parent Category'**
  String get parentCategory;

  /// Option for no parent category
  ///
  /// In en, this message translates to:
  /// **'None (Root Category)'**
  String get noneRootCategory;

  /// Success message for category update
  ///
  /// In en, this message translates to:
  /// **'Category saved'**
  String get categorySaved;

  /// Success message for category creation
  ///
  /// In en, this message translates to:
  /// **'Category added'**
  String get categoryAdded;

  /// Error message when category save fails
  ///
  /// In en, this message translates to:
  /// **'Error saving category'**
  String get errorSavingCategory;

  /// Title for delete category dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// Warning message for category deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? All transactions in this category will be reassigned.'**
  String deleteCategoryWarning(String name);

  /// Instruction for reassigning transactions
  ///
  /// In en, this message translates to:
  /// **'Select a category to reassign transactions to:'**
  String get selectReassignCategory;

  /// Error message when trying to delete last category
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the last category. Please create another category first.'**
  String get cannotDeleteLastCategory;

  /// Success message for category deletion
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// Error message when category deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting category'**
  String get errorDeletingCategory;

  /// Instruction for template selection
  ///
  /// In en, this message translates to:
  /// **'Select a category template that matches your region and lifestyle'**
  String get selectTemplateForYourRegion;

  /// Text showing additional categories count
  ///
  /// In en, this message translates to:
  /// **'and {count} more...'**
  String andMoreCategories(int count);

  /// Button to apply category template
  ///
  /// In en, this message translates to:
  /// **'Apply Template'**
  String get applyTemplate;

  /// Success message for template application
  ///
  /// In en, this message translates to:
  /// **'Template applied successfully'**
  String get templateApplied;

  /// Error message when template application fails
  ///
  /// In en, this message translates to:
  /// **'Error applying template'**
  String get errorApplyingTemplate;

  /// Reports screen title
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// Export button text
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Title for spending by category chart
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get spendingByCategory;

  /// Title for spending trends chart
  ///
  /// In en, this message translates to:
  /// **'Spending Trends'**
  String get spendingTrends;

  /// Title for insights section
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// Quick date range option
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// Quick date range option
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// Quick date range option
  ///
  /// In en, this message translates to:
  /// **'Last 90 Days'**
  String get last90Days;

  /// Quick date range option
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// Daily granularity option
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// Weekly granularity option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Monthly granularity option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// Export report dialog title
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// Export as PDF option
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportPdf;

  /// Export as CSV option
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportCsv;

  /// Loading message while generating report
  ///
  /// In en, this message translates to:
  /// **'Generating report...'**
  String get generatingReport;

  /// Success message for report generation
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get reportGenerated;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
