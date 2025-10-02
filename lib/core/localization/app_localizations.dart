import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appTitle': 'Bexly',
      'home': 'Home',
      'aiChat': 'AI Chat',
      'add': 'Add',
      'history': 'History',
      'planning': 'Planning',
      'settings': 'Settings',
      'myTransactions': 'My Transactions',
      'financialPlanning': 'Financial Planning',
      'budget': 'Budget',
      'goals': 'Goals',
      'earning': 'Earning',
      'spending': 'Spending',
      'total': 'Total',
      'today': 'Today',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'viewFullReport': 'View full report',
      'aiAssistantTitle': 'Bexly AI Assistant',
      'aiAssistantReady': 'Ready to help',
      'aiAssistantTyping': 'Typing...',
      'typeYourMessage': 'Type your message...',
      'clearChat': 'Clear chat',
      'clearChatConfirm': 'Are you sure you want to clear all chat history?',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'justNow': 'Just now',
      'selectLanguage': 'Select Language',
      'language': 'Language',
      'languageChanged': 'Language changed to',
      'preferences': 'Preferences',
      'notifications': 'Notifications',
      'finance': 'Finance',
      'data': 'Data',
      'appInfo': 'App Info',
      'myWallet': 'My Wallet',
      'noActiveWallet': 'No active wallet selected',
      'errorOccurred': 'An error occurred. Please try again.',
      'welcomeMessage': 'Welcome to Bexly AI Assistant! I can help you track expenses, record income, check balances, and view transaction summaries. Note: Budget creation is now supported via chat!',
      'income': 'Income',
      'expense': 'Expense',
      'errorLoadingIncomeData': 'Error loading income data',
      'errorLoadingExpenseData': 'Error loading expense data',
      'recentTransactions': 'Recent Transactions',
      'seeAll': 'See all',
      'noTransactions': 'No transactions yet',
      'balance': 'Balance',
      'noWallet': 'No Wallet',
      'createWallet': 'Create Wallet',
      'editWallet': 'Edit Wallet',
      'deleteWallet': 'Delete Wallet',
      'walletName': 'Wallet Name',
      'initialBalance': 'Initial Balance',
      'currency': 'Currency',
      'chooseCurrency': 'Choose Currency',
      'save': 'Save',
      'delete': 'Delete',
      'confirmDelete': 'Are you sure you want to delete this wallet?',
      'walletDeleted': 'Wallet deleted successfully',
      'walletCreated': 'Wallet created successfully',
      'walletUpdated': 'Wallet updated successfully',
      'addTransaction': 'Add Transaction',
      'editTransaction': 'Edit Transaction',
      'deleteTransaction': 'Delete Transaction',
      'amount': 'Amount',
      'category': 'Category',
      'description': 'Description',
      'date': 'Date',
      'time': 'Time',
      'type': 'Type',
      'pickDate': 'Pick Date',
      'pickTime': 'Pick Time',
      'selectCategory': 'Select Category',
      'addNewCategory': 'Add New Category',
      'manageCategories': 'Manage Categories',
      'pickingCategory': 'Picking Category',
      'transactionDeleted': 'Transaction deleted successfully',
      'transactionCreated': 'Transaction created successfully',
      'transactionUpdated': 'Transaction updated successfully',
      'goodMorning': 'Good morning',
      'goodAfternoon': 'Good afternoon',
      'goodEvening': 'Good evening',
      'welcome': 'Welcome',
      'spendingOverview': 'Spending Overview',
      'monthlySpending': 'Monthly Spending',
      'lastMonth': 'Last month',
      'thisYear': 'This year',
      'allTime': 'All time',
      'noData': 'No data available',
      'tapToAdd': 'Tap + to add your first transaction',
      'transfer': 'Transfer',
      'others': 'Others',
      'searchTransactions': 'Search transactions',
      'filter': 'Filter',
      'sort': 'Sort',
      'newest': 'Newest',
      'oldest': 'Oldest',
      'highestAmount': 'Highest amount',
      'lowestAmount': 'Lowest amount',
      'exportData': 'Export data',
      'importData': 'Import data',
      'backupData': 'Backup data',
      'restoreData': 'Restore data',
      'security': 'Security',
      'privacy': 'Privacy',
      'theme': 'Theme',
      'darkMode': 'Dark mode',
      'lightMode': 'Light mode',
      'systemDefault': 'System default',
      'about': 'About',
      'version': 'Version',
      'rateApp': 'Rate app',
      'contactSupport': 'Contact support',
      'termsOfService': 'Terms of service',
      'privacyPolicy': 'Privacy policy',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to logout?',
      'noInternet': 'No internet connection',
      'tryAgain': 'Try again',
      'success': 'Success',
      'error': 'Error',
      'warning': 'Warning',
      'info': 'Info',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'apply': 'Apply',
      'reset': 'Reset',
      'done': 'Done',
      'edit': 'Edit',
      'share': 'Share',
      'copy': 'Copy',
      'paste': 'Paste',
      'cut': 'Cut',
      'selectAll': 'Select all',
      'undo': 'Undo',
      'redo': 'Redo',
      'myBalance': 'My Balance',
      'noWalletSelected': 'No wallet selected.',
      'errorLoadingBalance': 'Error loading balance',
      'noTransactionsYet': 'No transactions yet.',
      'errorLoading': 'Error',
      'mySpendingThisMonth': 'My spending this month',
      'viewReport': 'View report',
      'errorLoadingSpendingData': 'Error loading spending data',
      'noTransactionsRecorded': 'No transactions recorded yet.',
      'noTransactionsWithValidDates': 'No transactions with valid dates found.',
      'noTransactionsForMonth': 'No transactions for this month.',
      'searchAndFilters': 'Search & Filters',
      'dinnerWithHint': 'Dinner with ...',
      'searchWithKeyword': 'Search with keyword',
      'minAmount': 'Min. Amount',
      'maxAmount': 'Max. Amount',
      'applyFilters': 'Apply Filters',
      'resetFilters': 'Reset Filters',
      'continueResetFilters': 'Continue to reset transaction filters?',
      'errorLoadingTransaction': 'Error loading transaction',
      'noTransactionsToDisplay': 'No transactions to display.',
      'titleMax50': 'Title (max. 50)',
      'lunchWithFriendsHint': 'Lunch with my friends',
      'writeNote': 'Write a note',
      'writeHereHint': 'Write here...',
      'setDate': 'Set a date',
      'transactionDateTime': 'Transaction Date & Time',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'setDateRange': 'Set a date range',
      'wallets': 'Wallets',
      'dataManagement': 'Data Management',
      'backupAndRestore': 'Backup & Restore',
      'deleteMyData': 'Delete My Data',
      'signOut': 'Sign Out',
      'signOutConfirm': 'Are you sure you want to sign out?',
      'errorSigningOut': 'Error signing out',
      'termsAndConditions': 'Terms and Conditions',
      'reportLogFile': 'Report Log File',
      'developerPortal': 'Developer Portal',
      'profile': 'Profile',
      'personalDetails': 'Personal Details'
    },
    'vi': {
      'appTitle': 'Bexly',
      'home': 'Trang chủ',
      'aiChat': 'Trò chuyện AI',
      'add': 'Thêm',
      'history': 'Lịch sử',
      'planning': 'Kế hoạch',
      'settings': 'Cài đặt',
      'myTransactions': 'Giao dịch của tôi',
      'financialPlanning': 'Kế hoạch tài chính',
      'budget': 'Ngân sách',
      'goals': 'Mục tiêu',
      'earning': 'Thu nhập',
      'spending': 'Chi tiêu',
      'total': 'Tổng cộng',
      'today': 'Hôm nay',
      'thisWeek': 'Tuần này',
      'thisMonth': 'Tháng này',
      'viewFullReport': 'Xem báo cáo đầy đủ',
      'aiAssistantTitle': 'Trợ lý AI Bexly',
      'aiAssistantReady': 'Sẵn sàng hỗ trợ',
      'aiAssistantTyping': 'Đang nhập...',
      'typeYourMessage': 'Nhập tin nhắn của bạn...',
      'clearChat': 'Xóa cuộc trò chuyện',
      'clearChatConfirm': 'Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện?',
      'cancel': 'Hủy',
      'clear': 'Xóa',
      'justNow': 'Vừa xong',
      'selectLanguage': 'Chọn ngôn ngữ',
      'language': 'Ngôn ngữ',
      'languageChanged': 'Đã chuyển sang',
      'preferences': 'Tùy chọn',
      'notifications': 'Thông báo',
      'finance': 'Tài chính',
      'data': 'Dữ liệu',
      'appInfo': 'Thông tin ứng dụng',
      'myWallet': 'Ví của tôi',
      'noActiveWallet': 'Chưa chọn ví hoạt động',
      'errorOccurred': 'Đã có lỗi xảy ra. Vui lòng thử lại.',
      'welcomeMessage': 'Chào mừng đến với Trợ lý AI Bexly! Tôi có thể giúp bạn theo dõi chi tiêu, ghi nhận thu nhập, kiểm tra số dư và xem tổng kết giao dịch. Lưu ý: Hiện đã hỗ trợ tạo ngân sách qua chat!',
      'income': 'Thu nhập',
      'expense': 'Chi tiêu',
      'errorLoadingIncomeData': 'Lỗi tải dữ liệu thu nhập',
      'errorLoadingExpenseData': 'Lỗi tải dữ liệu chi tiêu',
      'recentTransactions': 'Giao dịch gần đây',
      'seeAll': 'Xem tất cả',
      'noTransactions': 'Chưa có giao dịch',
      'balance': 'Số dư',
      'noWallet': 'Chưa có ví',
      'createWallet': 'Tạo ví',
      'editWallet': 'Sửa ví',
      'deleteWallet': 'Xóa ví',
      'walletName': 'Tên ví',
      'initialBalance': 'Số dư ban đầu',
      'currency': 'Tiền tệ',
      'chooseCurrency': 'Chọn tiền tệ',
      'save': 'Lưu',
      'delete': 'Xóa',
      'confirmDelete': 'Bạn có chắc chắn muốn xóa ví này?',
      'walletDeleted': 'Đã xóa ví thành công',
      'walletCreated': 'Đã tạo ví thành công',
      'walletUpdated': 'Đã cập nhật ví thành công',
      'addTransaction': 'Thêm giao dịch',
      'editTransaction': 'Sửa giao dịch',
      'deleteTransaction': 'Xóa giao dịch',
      'amount': 'Số tiền',
      'category': 'Danh mục',
      'description': 'Mô tả',
      'date': 'Ngày',
      'time': 'Giờ',
      'type': 'Loại',
      'pickDate': 'Chọn ngày',
      'pickTime': 'Chọn giờ',
      'selectCategory': 'Chọn danh mục',
      'addNewCategory': 'Thêm danh mục mới',
      'manageCategories': 'Quản lý danh mục',
      'pickingCategory': 'Chọn danh mục',
      'transactionDeleted': 'Đã xóa giao dịch thành công',
      'transactionCreated': 'Đã tạo giao dịch thành công',
      'transactionUpdated': 'Đã cập nhật giao dịch thành công',
      'goodMorning': 'Chào buổi sáng',
      'goodAfternoon': 'Chào buổi chiều',
      'goodEvening': 'Chào buổi tối',
      'welcome': 'Chào mừng',
      'spendingOverview': 'Tổng quan chi tiêu',
      'monthlySpending': 'Chi tiêu hàng tháng',
      'lastMonth': 'Tháng trước',
      'thisYear': 'Năm nay',
      'allTime': 'Tất cả thời gian',
      'noData': 'Không có dữ liệu',
      'tapToAdd': 'Nhấn + để thêm giao dịch đầu tiên',
      'transfer': 'Chuyển khoản',
      'others': 'Khác',
      'searchTransactions': 'Tìm giao dịch',
      'filter': 'Lọc',
      'sort': 'Sắp xếp',
      'newest': 'Mới nhất',
      'oldest': 'Cũ nhất',
      'highestAmount': 'Số tiền cao nhất',
      'lowestAmount': 'Số tiền thấp nhất',
      'exportData': 'Xuất dữ liệu',
      'importData': 'Nhập dữ liệu',
      'backupData': 'Sao lưu dữ liệu',
      'restoreData': 'Khôi phục dữ liệu',
      'security': 'Bảo mật',
      'privacy': 'Quyền riêng tư',
      'theme': 'Giao diện',
      'darkMode': 'Chế độ tối',
      'lightMode': 'Chế độ sáng',
      'systemDefault': 'Theo hệ thống',
      'about': 'Giới thiệu',
      'version': 'Phiên bản',
      'rateApp': 'Đánh giá ứng dụng',
      'contactSupport': 'Liên hệ hỗ trợ',
      'termsOfService': 'Điều khoản dịch vụ',
      'privacyPolicy': 'Chính sách bảo mật',
      'logout': 'Đăng xuất',
      'logoutConfirm': 'Bạn có chắc chắn muốn đăng xuất?',
      'noInternet': 'Không có kết nối internet',
      'tryAgain': 'Thử lại',
      'success': 'Thành công',
      'error': 'Lỗi',
      'warning': 'Cảnh báo',
      'info': 'Thông tin',
      'confirm': 'Xác nhận',
      'yes': 'Có',
      'no': 'Không',
      'ok': 'OK',
      'apply': 'Áp dụng',
      'reset': 'Đặt lại',
      'done': 'Xong',
      'edit': 'Sửa',
      'share': 'Chia sẻ',
      'copy': 'Sao chép',
      'paste': 'Dán',
      'cut': 'Cắt',
      'selectAll': 'Chọn tất cả',
      'undo': 'Hoàn tác',
      'redo': 'Làm lại',
      'myBalance': 'Số dư của tôi',
      'noWalletSelected': 'Chưa chọn ví.',
      'errorLoadingBalance': 'Lỗi khi tải số dư',
      'noTransactionsYet': 'Chưa có giao dịch.',
      'errorLoading': 'Lỗi',
      'mySpendingThisMonth': 'Chi tiêu của tôi tháng này',
      'viewReport': 'Xem báo cáo',
      'errorLoadingSpendingData': 'Lỗi tải dữ liệu chi tiêu',
      'noTransactionsRecorded': 'Chưa có giao dịch nào được ghi nhận.',
      'noTransactionsWithValidDates': 'Không tìm thấy giao dịch có ngày hợp lệ.',
      'noTransactionsForMonth': 'Không có giao dịch cho tháng này.',
      'searchAndFilters': 'Tìm kiếm & Bộ lọc',
      'dinnerWithHint': 'Ăn tối với...',
      'searchWithKeyword': 'Tìm kiếm với từ khóa',
      'minAmount': 'Số tiền tối thiểu',
      'maxAmount': 'Số tiền tối đa',
      'applyFilters': 'Áp dụng bộ lọc',
      'resetFilters': 'Đặt lại bộ lọc',
      'continueResetFilters': 'Tiếp tục đặt lại bộ lọc giao dịch?',
      'errorLoadingTransaction': 'Lỗi khi tải giao dịch',
      'noTransactionsToDisplay': 'Không có giao dịch để hiển thị.',
      'titleMax50': 'Tiêu đề (tối đa 50)',
      'lunchWithFriendsHint': 'Ăn trưa với bạn bè',
      'writeNote': 'Viết ghi chú',
      'writeHereHint': 'Viết ở đây...',
      'setDate': 'Chọn ngày',
      'transactionDateTime': 'Ngày & giờ giao dịch',
      'camera': 'Máy ảnh',
      'gallery': 'Thư viện',
      'setDateRange': 'Chọn khoảng thời gian',
      'wallets': 'Ví',
      'dataManagement': 'Quản lý dữ liệu',
      'backupAndRestore': 'Sao lưu & Khôi phục',
      'deleteMyData': 'Xóa dữ liệu của tôi',
      'signOut': 'Đăng xuất',
      'signOutConfirm': 'Bạn có chắc chắn muốn đăng xuất?',
      'errorSigningOut': 'Lỗi khi đăng xuất',
      'termsAndConditions': 'Điều khoản & Điều kiện',
      'reportLogFile': 'Báo cáo file log',
      'developerPortal': 'Cổng nhà phát triển',
      'profile': 'Hồ sơ',
      'personalDetails': 'Thông tin cá nhân'
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for all strings
  String get appTitle => get('appTitle');
  String get home => get('home');
  String get aiChat => get('aiChat');
  String get add => get('add');
  String get history => get('history');
  String get planning => get('planning');
  String get settings => get('settings');
  String get myTransactions => get('myTransactions');
  String get financialPlanning => get('financialPlanning');
  String get budget => get('budget');
  String get goals => get('goals');
  String get earning => get('earning');
  String get spending => get('spending');
  String get total => get('total');
  String get today => get('today');
  String get thisWeek => get('thisWeek');
  String get thisMonth => get('thisMonth');
  String get viewFullReport => get('viewFullReport');
  String get aiAssistantTitle => get('aiAssistantTitle');
  String get aiAssistantReady => get('aiAssistantReady');
  String get aiAssistantTyping => get('aiAssistantTyping');
  String get typeYourMessage => get('typeYourMessage');
  String get clearChat => get('clearChat');
  String get clearChatConfirm => get('clearChatConfirm');
  String get cancel => get('cancel');
  String get clear => get('clear');
  String get justNow => get('justNow');
  String get selectLanguage => get('selectLanguage');
  String get language => get('language');
  String get preferences => get('preferences');
  String get notifications => get('notifications');
  String get finance => get('finance');
  String get data => get('data');
  String get appInfo => get('appInfo');
  String get myWallet => get('myWallet');
  String get noActiveWallet => get('noActiveWallet');
  String get errorOccurred => get('errorOccurred');
  String get welcomeMessage => get('welcomeMessage');
  String get income => get('income');
  String get expense => get('expense');
  String get errorLoadingIncomeData => get('errorLoadingIncomeData');
  String get errorLoadingExpenseData => get('errorLoadingExpenseData');
  String get recentTransactions => get('recentTransactions');
  String get seeAll => get('seeAll');
  String get noTransactions => get('noTransactions');
  String get balance => get('balance');
  String get noWallet => get('noWallet');
  String get createWallet => get('createWallet');
  String get editWallet => get('editWallet');
  String get deleteWallet => get('deleteWallet');
  String get walletName => get('walletName');
  String get initialBalance => get('initialBalance');
  String get currency => get('currency');
  String get chooseCurrency => get('chooseCurrency');
  String get save => get('save');
  String get delete => get('delete');
  String get confirmDelete => get('confirmDelete');
  String get walletDeleted => get('walletDeleted');
  String get walletCreated => get('walletCreated');
  String get walletUpdated => get('walletUpdated');
  String get addTransaction => get('addTransaction');
  String get editTransaction => get('editTransaction');
  String get deleteTransaction => get('deleteTransaction');
  String get amount => get('amount');
  String get category => get('category');
  String get description => get('description');
  String get date => get('date');
  String get time => get('time');
  String get type => get('type');
  String get pickDate => get('pickDate');
  String get pickTime => get('pickTime');
  String get selectCategory => get('selectCategory');
  String get addNewCategory => get('addNewCategory');
  String get manageCategories => get('manageCategories');
  String get pickingCategory => get('pickingCategory');
  String get transactionDeleted => get('transactionDeleted');
  String get transactionCreated => get('transactionCreated');
  String get transactionUpdated => get('transactionUpdated');
  String get goodMorning => get('goodMorning');
  String get goodAfternoon => get('goodAfternoon');
  String get goodEvening => get('goodEvening');
  String get welcome => get('welcome');
  String get spendingOverview => get('spendingOverview');
  String get monthlySpending => get('monthlySpending');
  String get lastMonth => get('lastMonth');
  String get thisYear => get('thisYear');
  String get allTime => get('allTime');
  String get noData => get('noData');
  String get tapToAdd => get('tapToAdd');
  String get transfer => get('transfer');
  String get others => get('others');
  String get searchTransactions => get('searchTransactions');
  String get filter => get('filter');
  String get sort => get('sort');
  String get newest => get('newest');
  String get oldest => get('oldest');
  String get highestAmount => get('highestAmount');
  String get lowestAmount => get('lowestAmount');
  String get exportData => get('exportData');
  String get importData => get('importData');
  String get backupData => get('backupData');
  String get restoreData => get('restoreData');
  String get security => get('security');
  String get privacy => get('privacy');
  String get theme => get('theme');
  String get darkMode => get('darkMode');
  String get lightMode => get('lightMode');
  String get systemDefault => get('systemDefault');
  String get about => get('about');
  String get version => get('version');
  String get rateApp => get('rateApp');
  String get contactSupport => get('contactSupport');
  String get termsOfService => get('termsOfService');
  String get privacyPolicy => get('privacyPolicy');
  String get logout => get('logout');
  String get logoutConfirm => get('logoutConfirm');
  String get noInternet => get('noInternet');
  String get tryAgain => get('tryAgain');
  String get success => get('success');
  String get error => get('error');
  String get warning => get('warning');
  String get info => get('info');
  String get confirm => get('confirm');
  String get yes => get('yes');
  String get no => get('no');
  String get ok => get('ok');
  String get apply => get('apply');
  String get reset => get('reset');
  String get done => get('done');
  String get edit => get('edit');
  String get share => get('share');
  String get copy => get('copy');
  String get paste => get('paste');
  String get cut => get('cut');
  String get selectAll => get('selectAll');
  String get undo => get('undo');
  String get redo => get('redo');
  String get myBalance => get('myBalance');
  String get noWalletSelected => get('noWalletSelected');
  String get errorLoadingBalance => get('errorLoadingBalance');
  String get noTransactionsYet => get('noTransactionsYet');
  String get errorLoading => get('errorLoading');
  String get mySpendingThisMonth => get('mySpendingThisMonth');
  String get viewReport => get('viewReport');
  String get errorLoadingSpendingData => get('errorLoadingSpendingData');
  String get noTransactionsRecorded => get('noTransactionsRecorded');
  String get noTransactionsWithValidDates => get('noTransactionsWithValidDates');
  String get noTransactionsForMonth => get('noTransactionsForMonth');
  String get searchAndFilters => get('searchAndFilters');
  String get dinnerWithHint => get('dinnerWithHint');
  String get searchWithKeyword => get('searchWithKeyword');
  String get minAmount => get('minAmount');
  String get maxAmount => get('maxAmount');
  String get applyFilters => get('applyFilters');
  String get resetFilters => get('resetFilters');
  String get continueResetFilters => get('continueResetFilters');
  String get errorLoadingTransaction => get('errorLoadingTransaction');
  String get noTransactionsToDisplay => get('noTransactionsToDisplay');
  String get titleMax50 => get('titleMax50');
  String get lunchWithFriendsHint => get('lunchWithFriendsHint');
  String get writeNote => get('writeNote');
  String get writeHereHint => get('writeHereHint');
  String get setDate => get('setDate');
  String get transactionDateTime => get('transactionDateTime');
  String get camera => get('camera');
  String get gallery => get('gallery');
  String get setDateRange => get('setDateRange');
  String get wallets => get('wallets');
  String get dataManagement => get('dataManagement');
  String get backupAndRestore => get('backupAndRestore');
  String get deleteMyData => get('deleteMyData');
  String get signOut => get('signOut');
  String get signOutConfirm => get('signOutConfirm');
  String get errorSigningOut => get('errorSigningOut');
  String get termsAndConditions => get('termsAndConditions');
  String get reportLogFile => get('reportLogFile');
  String get developerPortal => get('developerPortal');
  String get profile => get('profile');
  String get personalDetails => get('personalDetails');

  String languageChanged(String language) {
    return '${get('languageChanged')} $language';
  }

  String minutesAgo(int count) {
    if (locale.languageCode == 'vi') {
      return '$count phút trước';
    }
    return count == 1 ? '1 minute ago' : '$count minutes ago';
  }

  String hoursAgo(int count) {
    if (locale.languageCode == 'vi') {
      return '$count giờ trước';
    }
    return count == 1 ? '1 hour ago' : '$count hours ago';
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}