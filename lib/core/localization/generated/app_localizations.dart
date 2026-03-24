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
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
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
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bexly'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @planning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get planning;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @myTransactions.
  ///
  /// In en, this message translates to:
  /// **'My Transactions'**
  String get myTransactions;

  /// No description provided for @financialPlanning.
  ///
  /// In en, this message translates to:
  /// **'Financial Planning'**
  String get financialPlanning;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @earning.
  ///
  /// In en, this message translates to:
  /// **'Earning'**
  String get earning;

  /// No description provided for @spending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get spending;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @viewFullReport.
  ///
  /// In en, this message translates to:
  /// **'View full report'**
  String get viewFullReport;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'Bexly AI Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to help'**
  String get aiAssistantReady;

  /// No description provided for @aiAssistantTyping.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get aiAssistantTyping;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get clearChat;

  /// No description provided for @clearChatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all chat history?'**
  String get clearChatConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to'**
  String get languageChanged;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @numberFormat.
  ///
  /// In en, this message translates to:
  /// **'Number Format'**
  String get numberFormat;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @baseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base Currency'**
  String get baseCurrency;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get appInfo;

  /// No description provided for @myWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWallet;

  /// No description provided for @noActiveWallet.
  ///
  /// In en, this message translates to:
  /// **'No active wallet selected'**
  String get noActiveWallet;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bexly AI Assistant! I can help you track expenses, record income, check balances, and view transaction summaries. Note: Budget creation is now supported via chat!'**
  String get welcomeMessage;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @errorLoadingIncomeData.
  ///
  /// In en, this message translates to:
  /// **'Error loading income data'**
  String get errorLoadingIncomeData;

  /// No description provided for @errorLoadingExpenseData.
  ///
  /// In en, this message translates to:
  /// **'Error loading expense data'**
  String get errorLoadingExpenseData;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @noWallet.
  ///
  /// In en, this message translates to:
  /// **'No Wallet'**
  String get noWallet;

  /// No description provided for @createWallet.
  ///
  /// In en, this message translates to:
  /// **'Create Wallet'**
  String get createWallet;

  /// No description provided for @editWallet.
  ///
  /// In en, this message translates to:
  /// **'Edit Wallet'**
  String get editWallet;

  /// No description provided for @deleteWallet.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get deleteWallet;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @chooseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose Currency'**
  String get chooseCurrency;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this wallet?'**
  String get confirmDelete;

  /// No description provided for @walletDeleted.
  ///
  /// In en, this message translates to:
  /// **'Wallet deleted successfully'**
  String get walletDeleted;

  /// No description provided for @walletCreated.
  ///
  /// In en, this message translates to:
  /// **'Wallet created successfully'**
  String get walletCreated;

  /// No description provided for @walletUpdated.
  ///
  /// In en, this message translates to:
  /// **'Wallet updated successfully'**
  String get walletUpdated;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick Date'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick Time'**
  String get pickTime;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @addNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get addNewCategory;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @pickingCategory.
  ///
  /// In en, this message translates to:
  /// **'Picking Category'**
  String get pickingCategory;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted successfully'**
  String get transactionDeleted;

  /// No description provided for @transactionCreated.
  ///
  /// In en, this message translates to:
  /// **'Transaction created successfully'**
  String get transactionCreated;

  /// No description provided for @transactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated successfully'**
  String get transactionUpdated;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @spendingOverview.
  ///
  /// In en, this message translates to:
  /// **'Spending Overview'**
  String get spendingOverview;

  /// No description provided for @monthlySpending.
  ///
  /// In en, this message translates to:
  /// **'Monthly Spending'**
  String get monthlySpending;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @tapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first transaction'**
  String get tapToAdd;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get searchTransactions;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get oldest;

  /// No description provided for @highestAmount.
  ///
  /// In en, this message translates to:
  /// **'Highest amount'**
  String get highestAmount;

  /// No description provided for @lowestAmount.
  ///
  /// In en, this message translates to:
  /// **'Lowest amount'**
  String get lowestAmount;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup data'**
  String get backupData;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore data'**
  String get restoreData;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate app'**
  String get rateApp;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @myBalance.
  ///
  /// In en, this message translates to:
  /// **'My Balance'**
  String get myBalance;

  /// No description provided for @noWalletSelected.
  ///
  /// In en, this message translates to:
  /// **'No wallet selected.'**
  String get noWalletSelected;

  /// No description provided for @errorLoadingBalance.
  ///
  /// In en, this message translates to:
  /// **'Error loading balance'**
  String get errorLoadingBalance;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get noTransactionsYet;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLoading;

  /// No description provided for @mySpendingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'My spending this month'**
  String get mySpendingThisMonth;

  /// No description provided for @viewReport.
  ///
  /// In en, this message translates to:
  /// **'View report'**
  String get viewReport;

  /// No description provided for @errorLoadingSpendingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading spending data'**
  String get errorLoadingSpendingData;

  /// No description provided for @noTransactionsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded yet.'**
  String get noTransactionsRecorded;

  /// No description provided for @noTransactionsWithValidDates.
  ///
  /// In en, this message translates to:
  /// **'No transactions with valid dates found.'**
  String get noTransactionsWithValidDates;

  /// No description provided for @noTransactionsForMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions for this month.'**
  String get noTransactionsForMonth;

  /// No description provided for @searchAndFilters.
  ///
  /// In en, this message translates to:
  /// **'Search & Filters'**
  String get searchAndFilters;

  /// No description provided for @dinnerWithHint.
  ///
  /// In en, this message translates to:
  /// **'Dinner with ...'**
  String get dinnerWithHint;

  /// No description provided for @searchWithKeyword.
  ///
  /// In en, this message translates to:
  /// **'Search with keyword'**
  String get searchWithKeyword;

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min. Amount'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max. Amount'**
  String get maxAmount;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset Filters'**
  String get resetFilters;

  /// No description provided for @continueResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Continue to reset transaction filters?'**
  String get continueResetFilters;

  /// No description provided for @errorLoadingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Error loading transaction'**
  String get errorLoadingTransaction;

  /// No description provided for @noTransactionsToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No transactions to display.'**
  String get noTransactionsToDisplay;

  /// No description provided for @titleMax50.
  ///
  /// In en, this message translates to:
  /// **'Title (max. 50)'**
  String get titleMax50;

  /// No description provided for @lunchWithFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Lunch with my friends'**
  String get lunchWithFriendsHint;

  /// No description provided for @writeNote.
  ///
  /// In en, this message translates to:
  /// **'Write a note'**
  String get writeNote;

  /// No description provided for @writeHereHint.
  ///
  /// In en, this message translates to:
  /// **'Write here...'**
  String get writeHereHint;

  /// No description provided for @setDate.
  ///
  /// In en, this message translates to:
  /// **'Set a date'**
  String get setDate;

  /// No description provided for @transactionDateTime.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date & Time'**
  String get transactionDateTime;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @setDateRange.
  ///
  /// In en, this message translates to:
  /// **'Set a date range'**
  String get setDateRange;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @deleteMyData.
  ///
  /// In en, this message translates to:
  /// **'Delete My Data'**
  String get deleteMyData;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @errorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Error signing out'**
  String get errorSigningOut;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @reportLogFile.
  ///
  /// In en, this message translates to:
  /// **'Report Log File'**
  String get reportLogFile;

  /// No description provided for @developerPortal.
  ///
  /// In en, this message translates to:
  /// **'Developer Portal'**
  String get developerPortal;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @categoryFoodDrinks.
  ///
  /// In en, this message translates to:
  /// **'Food & Drinks'**
  String get categoryFoodDrinks;

  /// No description provided for @categoryTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryTransportation;

  /// No description provided for @categoryHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get categoryFinance;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get categoryRestaurants;

  /// No description provided for @categoryCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get categoryCoffee;

  /// No description provided for @categorySnacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnacks;

  /// No description provided for @categoryTakeout.
  ///
  /// In en, this message translates to:
  /// **'Takeout'**
  String get categoryTakeout;

  /// No description provided for @categoryPublicTransport.
  ///
  /// In en, this message translates to:
  /// **'Public Transport'**
  String get categoryPublicTransport;

  /// No description provided for @categoryFuelGas.
  ///
  /// In en, this message translates to:
  /// **'Fuel/Gas'**
  String get categoryFuelGas;

  /// No description provided for @categoryTaxiRideshare.
  ///
  /// In en, this message translates to:
  /// **'Taxi & Rideshare'**
  String get categoryTaxiRideshare;

  /// No description provided for @categoryVehicleMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Maintenance'**
  String get categoryVehicleMaintenance;

  /// No description provided for @categoryParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get categoryParking;

  /// No description provided for @categoryRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get categoryRent;

  /// No description provided for @categoryMortgage.
  ///
  /// In en, this message translates to:
  /// **'Mortgage'**
  String get categoryMortgage;

  /// No description provided for @categoryUtilitiesHousing.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilitiesHousing;

  /// No description provided for @categoryMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get categoryMaintenance;

  /// No description provided for @categoryPropertyTax.
  ///
  /// In en, this message translates to:
  /// **'Property Tax'**
  String get categoryPropertyTax;

  /// No description provided for @categoryMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get categoryMovies;

  /// No description provided for @categoryStreaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get categoryStreaming;

  /// No description provided for @categoryGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get categoryGaming;

  /// No description provided for @categoryEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get categoryEvents;

  /// No description provided for @categorySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get categorySubscriptions;

  /// No description provided for @categoryDoctorVisits.
  ///
  /// In en, this message translates to:
  /// **'Doctor Visits'**
  String get categoryDoctorVisits;

  /// No description provided for @categoryPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get categoryPharmacy;

  /// No description provided for @categoryInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get categoryInsurance;

  /// No description provided for @categoryFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get categoryFitness;

  /// No description provided for @categoryDental.
  ///
  /// In en, this message translates to:
  /// **'Dental'**
  String get categoryDental;

  /// No description provided for @categoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryClothing;

  /// No description provided for @categoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// No description provided for @categoryShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get categoryShoes;

  /// No description provided for @categoryAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get categoryAccessories;

  /// No description provided for @categoryOnlineShopping.
  ///
  /// In en, this message translates to:
  /// **'Online Shopping'**
  String get categoryOnlineShopping;

  /// No description provided for @categoryTuition.
  ///
  /// In en, this message translates to:
  /// **'Tuition'**
  String get categoryTuition;

  /// No description provided for @categoryBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get categoryBooks;

  /// No description provided for @categoryOnlineCourses.
  ///
  /// In en, this message translates to:
  /// **'Online Courses'**
  String get categoryOnlineCourses;

  /// No description provided for @categoryWorkshops.
  ///
  /// In en, this message translates to:
  /// **'Workshops'**
  String get categoryWorkshops;

  /// No description provided for @categorySchoolSupplies.
  ///
  /// In en, this message translates to:
  /// **'School Supplies'**
  String get categorySchoolSupplies;

  /// No description provided for @categoryFlights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get categoryFlights;

  /// No description provided for @categoryHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get categoryHotels;

  /// No description provided for @categoryTours.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get categoryTours;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categorySouvenirs.
  ///
  /// In en, this message translates to:
  /// **'Souvenirs'**
  String get categorySouvenirs;

  /// No description provided for @categoryLoanPayments.
  ///
  /// In en, this message translates to:
  /// **'Loan Payments'**
  String get categoryLoanPayments;

  /// No description provided for @categorySavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get categorySavings;

  /// No description provided for @categoryInvestments.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get categoryInvestments;

  /// No description provided for @categoryCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get categoryCreditCard;

  /// No description provided for @categoryBankFees.
  ///
  /// In en, this message translates to:
  /// **'Bank Fees'**
  String get categoryBankFees;

  /// No description provided for @categoryElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get categoryElectricity;

  /// No description provided for @categoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get categoryWater;

  /// No description provided for @categoryGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get categoryGas;

  /// No description provided for @categoryInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get categoryInternet;

  /// No description provided for @categoryPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get categoryPhone;

  /// No description provided for @recurringPayments.
  ///
  /// In en, this message translates to:
  /// **'Recurring Payments'**
  String get recurringPayments;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @noActiveRecurringPayments.
  ///
  /// In en, this message translates to:
  /// **'No Active Recurring Payments'**
  String get noActiveRecurringPayments;

  /// No description provided for @addFirstSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add your first subscription or recurring bill'**
  String get addFirstSubscription;

  /// No description provided for @noRecurringPayments.
  ///
  /// In en, this message translates to:
  /// **'No Recurring Payments'**
  String get noRecurringPayments;

  /// No description provided for @noPausedRecurringPayments.
  ///
  /// In en, this message translates to:
  /// **'No Paused Recurring Payments'**
  String get noPausedRecurringPayments;

  /// No description provided for @pausedSubscriptionsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Paused subscriptions and bills will appear here'**
  String get pausedSubscriptionsWillAppear;

  /// No description provided for @errorLoadingRecurrings.
  ///
  /// In en, this message translates to:
  /// **'Error loading recurrings'**
  String get errorLoadingRecurrings;

  /// No description provided for @pinnedGoals.
  ///
  /// In en, this message translates to:
  /// **'Pinned Goals'**
  String get pinnedGoals;

  /// No description provided for @noGoalsPinned.
  ///
  /// In en, this message translates to:
  /// **'No goals pinned.'**
  String get noGoalsPinned;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @selectWallet.
  ///
  /// In en, this message translates to:
  /// **'Select Wallet'**
  String get selectWallet;

  /// No description provided for @viewCombinedBalance.
  ///
  /// In en, this message translates to:
  /// **'View combined balance from all wallets'**
  String get viewCombinedBalance;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found. Add one!'**
  String get noCategoriesFound;

  /// No description provided for @repopulateCategories.
  ///
  /// In en, this message translates to:
  /// **'Re-populate Categories'**
  String get repopulateCategories;

  /// No description provided for @repopulate.
  ///
  /// In en, this message translates to:
  /// **'Re-populate'**
  String get repopulate;

  /// No description provided for @repopulateCategoriesWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: This will DELETE all categories and restore defaults.'**
  String get repopulateCategoriesWarning;

  /// No description provided for @repopulateCategoriesTransactions.
  ///
  /// In en, this message translates to:
  /// **'Your existing transactions may show \"Unknown Category\" and need manual re-assignment.'**
  String get repopulateCategoriesTransactions;

  /// No description provided for @repopulateCategoriesRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED: Use \"Delete My Data\" instead, then create a new wallet.'**
  String get repopulateCategoriesRecommended;

  /// No description provided for @categoriesRepopulatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Categories re-populated successfully'**
  String get categoriesRepopulatedSuccess;

  /// No description provided for @defaultCategoriesRestored.
  ///
  /// In en, this message translates to:
  /// **'Default categories have been restored'**
  String get defaultCategoriesRestored;

  /// No description provided for @errorRepopulatingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error re-populating categories'**
  String get errorRepopulatingCategories;

  /// No description provided for @bindAccount.
  ///
  /// In en, this message translates to:
  /// **'Bind Account'**
  String get bindAccount;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhoto;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty.'**
  String get nameCannotBeEmpty;

  /// No description provided for @uploadingProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Uploading new profile picture...'**
  String get uploadingProfilePicture;

  /// No description provided for @failedToUploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar'**
  String get failedToUploadAvatar;

  /// No description provided for @personalDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Personal details updated!'**
  String get personalDetailsUpdated;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @enableReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminder'**
  String get enableReminder;

  /// No description provided for @editRecurringPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring Payment'**
  String get editRecurringPayment;

  /// No description provided for @deleteRecurringPayment.
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring Payment'**
  String get deleteRecurringPayment;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @noBudgetsRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No budgets recorded yet.'**
  String get noBudgetsRecordedYet;

  /// No description provided for @noBudgetsForThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No budgets for this month.'**
  String get noBudgetsForThisMonth;

  /// No description provided for @noGoalsAddOne.
  ///
  /// In en, this message translates to:
  /// **'No goals. Add one!'**
  String get noGoalsAddOne;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see notifications and reminders here'**
  String get notificationsSubtitle;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get clearAllNotifications;

  /// No description provided for @areYouSureDeleteAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications?'**
  String get areYouSureDeleteAllNotifications;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get errorLoadingNotifications;

  /// No description provided for @defaultWalletSetting.
  ///
  /// In en, this message translates to:
  /// **'Default Wallet'**
  String get defaultWalletSetting;

  /// No description provided for @notSetYet.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get notSetYet;

  /// No description provided for @noWalletsCreateOne.
  ///
  /// In en, this message translates to:
  /// **'No wallets yet. Create one first.'**
  String get noWalletsCreateOne;

  /// No description provided for @setAsDefaultWallet.
  ///
  /// In en, this message translates to:
  /// **'Set as default wallet'**
  String get setAsDefaultWallet;

  /// No description provided for @usedForAiAndConversion.
  ///
  /// In en, this message translates to:
  /// **'Used for AI assistant and currency conversion'**
  String get usedForAiAndConversion;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @purchaseSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful!'**
  String get purchaseSuccessful;

  /// No description provided for @purchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get purchasesRestored;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'BEST VALUE'**
  String get bestValue;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get current;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get perYear;

  /// No description provided for @unlimitedWallets.
  ///
  /// In en, this message translates to:
  /// **'Unlimited wallets'**
  String get unlimitedWallets;

  /// No description provided for @unlimitedBudgetsGoals.
  ///
  /// In en, this message translates to:
  /// **'Unlimited budgets & goals'**
  String get unlimitedBudgetsGoals;

  /// No description provided for @unlimitedRecurring.
  ///
  /// In en, this message translates to:
  /// **'Unlimited recurring transactions'**
  String get unlimitedRecurring;

  /// No description provided for @aiMessagesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'50 AI messages/month'**
  String get aiMessagesPerMonth;

  /// No description provided for @sixMonthsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'6 months analytics history'**
  String get sixMonthsAnalytics;

  /// No description provided for @multiCurrencySupport.
  ///
  /// In en, this message translates to:
  /// **'Multi-currency support'**
  String get multiCurrencySupport;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get cloudSync;

  /// No description provided for @receiptPhotos1GB.
  ///
  /// In en, this message translates to:
  /// **'Receipt photos (1GB)'**
  String get receiptPhotos1GB;

  /// No description provided for @everythingInPlus.
  ///
  /// In en, this message translates to:
  /// **'Everything in Plus'**
  String get everythingInPlus;

  /// No description provided for @unlimitedAiMessages.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI messages'**
  String get unlimitedAiMessages;

  /// No description provided for @fullAnalyticsHistory.
  ///
  /// In en, this message translates to:
  /// **'Full analytics history'**
  String get fullAnalyticsHistory;

  /// No description provided for @unlimitedReceiptStorage.
  ///
  /// In en, this message translates to:
  /// **'Unlimited receipt storage'**
  String get unlimitedReceiptStorage;

  /// No description provided for @ocrReceiptScanning.
  ///
  /// In en, this message translates to:
  /// **'OCR receipt scanning'**
  String get ocrReceiptScanning;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get prioritySupport;

  /// No description provided for @weeklyOverview.
  ///
  /// In en, this message translates to:
  /// **'Weekly Overview'**
  String get weeklyOverview;

  /// No description provided for @currentMonthBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Current Month Breakdown'**
  String get currentMonthBreakdown;

  /// No description provided for @noTransactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month yet.'**
  String get noTransactionsThisMonth;

  /// No description provided for @noTransactionDataYet.
  ///
  /// In en, this message translates to:
  /// **'No transaction data available yet.'**
  String get noTransactionDataYet;

  /// No description provided for @incomeVsExpense.
  ///
  /// In en, this message translates to:
  /// **'Income vs. Expense'**
  String get incomeVsExpense;

  /// No description provided for @lastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get lastSixMonths;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @filterByWallet.
  ///
  /// In en, this message translates to:
  /// **'Filter by Wallet'**
  String get filterByWallet;

  /// No description provided for @allWallets.
  ///
  /// In en, this message translates to:
  /// **'All Wallets'**
  String get allWallets;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get monthlyReport;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @paymentsAndBills.
  ///
  /// In en, this message translates to:
  /// **'Payments & Bills'**
  String get paymentsAndBills;

  /// No description provided for @recurringPaymentReminders.
  ///
  /// In en, this message translates to:
  /// **'Recurring Payment Reminders'**
  String get recurringPaymentReminders;

  /// No description provided for @dailyAndWeekly.
  ///
  /// In en, this message translates to:
  /// **'Daily & Weekly'**
  String get dailyAndWeekly;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @monthlyAndGoals.
  ///
  /// In en, this message translates to:
  /// **'Monthly & Goals'**
  String get monthlyAndGoals;

  /// No description provided for @goalMilestones.
  ///
  /// In en, this message translates to:
  /// **'Goal Milestones'**
  String get goalMilestones;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotification;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. Please enable in system settings.'**
  String get notificationPermissionDenied;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'If you see this, notifications are working! ðŸŽ‰'**
  String get testNotificationBody;

  /// No description provided for @deleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get deleteBudget;

  /// No description provided for @deleteBudgetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this budget?'**
  String get deleteBudgetConfirm;

  /// No description provided for @deleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get deleteGoal;

  /// No description provided for @deleteGoalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this goal?'**
  String get deleteGoalConfirm;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteChecklist.
  ///
  /// In en, this message translates to:
  /// **'Delete Checklist'**
  String get deleteChecklist;

  /// No description provided for @deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get deleteImage;

  /// No description provided for @deleteImageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this image?'**
  String get deleteImageConfirm;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteMyAccount;

  /// No description provided for @notifDailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Your Expenses'**
  String get notifDailyReminderTitle;

  /// No description provided for @notifDailyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to record today\'s spending!'**
  String get notifDailyReminderBody;

  /// No description provided for @notifWeeklyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Spending Report'**
  String get notifWeeklyReportTitle;

  /// No description provided for @notifWeeklyReportBody.
  ///
  /// In en, this message translates to:
  /// **'Check out your spending summary from last week'**
  String get notifWeeklyReportBody;

  /// No description provided for @notifMonthlyReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Financial Report'**
  String get notifMonthlyReportTitle;

  /// No description provided for @notifMonthlyReportBody.
  ///
  /// In en, this message translates to:
  /// **'Your complete financial summary for last month is ready'**
  String get notifMonthlyReportBody;

  /// No description provided for @autoTransaction.
  ///
  /// In en, this message translates to:
  /// **'Auto Transaction'**
  String get autoTransaction;

  /// No description provided for @autoTransactionInfo.
  ///
  /// In en, this message translates to:
  /// **'Automatically create transactions from bank SMS messages and notifications. Transactions are created instantly and you can edit or delete them anytime.'**
  String get autoTransactionInfo;

  /// No description provided for @autoTransactionSms.
  ///
  /// In en, this message translates to:
  /// **'SMS Parsing'**
  String get autoTransactionSms;

  /// No description provided for @autoTransactionSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Parse Bank SMS'**
  String get autoTransactionSmsTitle;

  /// No description provided for @autoTransactionSmsDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically detect and create transactions from bank SMS messages'**
  String get autoTransactionSmsDescription;

  /// No description provided for @autoTransactionNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification Listener'**
  String get autoTransactionNotification;

  /// No description provided for @autoTransactionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Parse Bank Notifications'**
  String get autoTransactionNotificationTitle;

  /// No description provided for @autoTransactionNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically detect and create transactions from banking app notifications'**
  String get autoTransactionNotificationDescription;

  /// No description provided for @autoTransactionDefaultWallet.
  ///
  /// In en, this message translates to:
  /// **'Default Wallet'**
  String get autoTransactionDefaultWallet;

  /// No description provided for @autoTransactionUseActiveWallet.
  ///
  /// In en, this message translates to:
  /// **'Use Active Wallet'**
  String get autoTransactionUseActiveWallet;

  /// No description provided for @autoTransactionUseActiveWalletDescription.
  ///
  /// In en, this message translates to:
  /// **'Transactions will be added to your currently selected wallet'**
  String get autoTransactionUseActiveWalletDescription;

  /// No description provided for @autoTransactionIosNotice.
  ///
  /// In en, this message translates to:
  /// **'Auto transaction from SMS and notifications is only available on Android. iOS does not allow apps to read SMS messages or notifications from other apps.'**
  String get autoTransactionIosNotice;

  /// No description provided for @autoTransactionScanSms.
  ///
  /// In en, this message translates to:
  /// **'Scan SMS'**
  String get autoTransactionScanSms;

  /// No description provided for @autoTransactionScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning SMS...'**
  String get autoTransactionScanning;

  /// No description provided for @autoTransactionScanResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Banks Found'**
  String get autoTransactionScanResultsTitle;

  /// No description provided for @autoTransactionScanResultsDescription.
  ///
  /// In en, this message translates to:
  /// **'Found {count} banks/e-wallets in your SMS'**
  String autoTransactionScanResultsDescription(int count);

  /// No description provided for @autoTransactionCreateWallets.
  ///
  /// In en, this message translates to:
  /// **'Create Wallets ({count})'**
  String autoTransactionCreateWallets(int count);

  /// No description provided for @autoTransactionTargetWallet.
  ///
  /// In en, this message translates to:
  /// **'Target Wallet'**
  String get autoTransactionTargetWallet;

  /// No description provided for @autoTransactionCreateNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Create New Wallet'**
  String get autoTransactionCreateNewWallet;

  /// No description provided for @autoTransactionImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing from {bank}...'**
  String autoTransactionImporting(String bank);

  /// No description provided for @autoTransactionImportComplete.
  ///
  /// In en, this message translates to:
  /// **'Import Complete'**
  String get autoTransactionImportComplete;

  /// No description provided for @autoTransactionWalletsCreated.
  ///
  /// In en, this message translates to:
  /// **'{count} wallets created'**
  String autoTransactionWalletsCreated(int count);

  /// No description provided for @autoTransactionTransactionsImported.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions imported'**
  String autoTransactionTransactionsImported(int count);

  /// No description provided for @autoTransactionDuplicatesSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} duplicates skipped'**
  String autoTransactionDuplicatesSkipped(int count);

  /// No description provided for @autoTransactionViewPending.
  ///
  /// In en, this message translates to:
  /// **'View Pending Transactions'**
  String get autoTransactionViewPending;

  /// No description provided for @autoTransactionNoResults.
  ///
  /// In en, this message translates to:
  /// **'No bank SMS found'**
  String get autoTransactionNoResults;

  /// No description provided for @autoTransactionNoResultsDescription.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any SMS from known banks. Make sure you have SMS from your bank in your inbox.'**
  String get autoTransactionNoResultsDescription;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noPendingToReview.
  ///
  /// In en, this message translates to:
  /// **'No pending transactions to review'**
  String get noPendingToReview;

  /// No description provided for @bulkActions.
  ///
  /// In en, this message translates to:
  /// **'Bulk Actions'**
  String get bulkActions;

  /// No description provided for @acceptAll.
  ///
  /// In en, this message translates to:
  /// **'Accept All'**
  String get acceptAll;

  /// No description provided for @rejectAll.
  ///
  /// In en, this message translates to:
  /// **'Reject All'**
  String get rejectAll;

  /// No description provided for @acceptAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Accept All?'**
  String get acceptAllConfirm;

  /// No description provided for @acceptAllDescription.
  ///
  /// In en, this message translates to:
  /// **'This will import all pending transactions using their suggested categories. Transactions without a category will be skipped.'**
  String get acceptAllDescription;

  /// No description provided for @rejectAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject All?'**
  String get rejectAllConfirm;

  /// No description provided for @rejectAllDescription.
  ///
  /// In en, this message translates to:
  /// **'This will reject all pending transactions. They won\'t reappear on future scans.'**
  String get rejectAllDescription;

  /// No description provided for @transactionsImportedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions imported'**
  String transactionsImportedCount(int count);

  /// No description provided for @transactionsRejectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions rejected'**
  String transactionsRejectedCount(int count);

  /// No description provided for @transactionRejected.
  ///
  /// In en, this message translates to:
  /// **'Transaction rejected'**
  String get transactionRejected;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pendingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Pending Transactions'**
  String get pendingTransactions;

  /// No description provided for @reviewAndImport.
  ///
  /// In en, this message translates to:
  /// **'Review and import transactions'**
  String get reviewAndImport;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @reviewTransactions.
  ///
  /// In en, this message translates to:
  /// **'Review Transactions'**
  String get reviewTransactions;

  /// No description provided for @approveAll.
  ///
  /// In en, this message translates to:
  /// **'Approve All'**
  String get approveAll;

  /// No description provided for @noTransactionsToReview.
  ///
  /// In en, this message translates to:
  /// **'No transactions to review'**
  String get noTransactionsToReview;

  /// No description provided for @scanEmailsDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan your emails to find banking transactions'**
  String get scanEmailsDesc;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @pleaseSelectWallets.
  ///
  /// In en, this message translates to:
  /// **'Please select wallets'**
  String get pleaseSelectWallets;

  /// No description provided for @transactionsNeedWallet.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions need a wallet selected'**
  String transactionsNeedWallet(int count);

  /// No description provided for @importedCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} transactions'**
  String importedCount(int count);

  /// No description provided for @failedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} failed'**
  String failedCount(int count);

  /// No description provided for @pleaseSelectWalletFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a wallet first'**
  String get pleaseSelectWalletFirst;

  /// No description provided for @transactionImported.
  ///
  /// In en, this message translates to:
  /// **'Transaction imported'**
  String get transactionImported;

  /// No description provided for @approvedButImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Approved but import failed'**
  String get approvedButImportFailed;

  /// No description provided for @merchantDescription.
  ///
  /// In en, this message translates to:
  /// **'Merchant / Description'**
  String get merchantDescription;

  /// No description provided for @countPendingTransactions.
  ///
  /// In en, this message translates to:
  /// **'{count} pending transactions'**
  String countPendingTransactions(int count);

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueToday;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String dueInDays(int days);

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// No description provided for @frequencyQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get frequencyQuarterly;

  /// No description provided for @frequencyYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get frequencyYearly;

  /// No description provided for @frequencyCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get frequencyCustom;

  /// No description provided for @aiDetectedRecurring.
  ///
  /// In en, this message translates to:
  /// **'AI detected {count} patterns'**
  String aiDetectedRecurring(int count);
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
    'id',
    'ja',
    'ko',
    'pt',
    'ru',
    'th',
    'vi',
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
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
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
