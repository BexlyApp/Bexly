import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/category/presentation/riverpod/category_providers.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/core/services/auto_transaction/bank_wallet_mapping.dart';
import 'package:bexly/core/services/auto_transaction/parsed_transaction.dart';
import 'package:bexly/core/services/auto_transaction/sms_service.dart';
import 'package:bexly/core/services/auto_transaction/notification_service.dart';
import 'package:bexly/core/services/auto_transaction/transaction_parser_service.dart';

/// Provider for auto transaction service
final autoTransactionServiceProvider = Provider<AutoTransactionService>((ref) {
  return AutoTransactionService(ref);
});

/// Service to manage auto transaction creation from SMS/notifications
class AutoTransactionService {
  final Ref _ref;
  SmsService? _smsService;
  NotificationListenerServiceWrapper? _notificationService;
  final BankWalletMappingService _mappingService = BankWalletMappingService();

  bool _isInitialized = false;
  bool _smsEnabled = false;
  bool _notificationEnabled = false;
  int? _defaultWalletId;

  AutoTransactionService(this._ref);

  /// Get the SMS service instance
  SmsService? get smsService => _smsService;

  /// Initialize the service and start listening if enabled
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadSettings();

    // Initialize parser service with Gemini API key
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      Log.w('Gemini API key not configured, auto transaction disabled', label: 'AutoTransaction');
      return;
    }

    final parserService = TransactionParserService(apiKey: apiKey);
    final deduplicationService = TransactionDeduplicationService();

    _smsService = SmsService(
      parserService: parserService,
      deduplicationService: deduplicationService,
    );
    _notificationService = NotificationListenerServiceWrapper(
      parserService: parserService,
      deduplicationService: deduplicationService,
    );

    // Start listening if SMS is enabled
    if (_smsEnabled && _smsService!.isAvailable) {
      await _startSmsListening();
    }

    // Start listening if notification is enabled
    if (_notificationEnabled && _notificationService!.isAvailable) {
      await _startNotificationListening();
    }

    _isInitialized = true;
    Log.d('AutoTransactionService initialized', label: 'AutoTransaction');
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _smsEnabled = prefs.getBool('auto_transaction_sms_enabled') ?? false;
    _notificationEnabled = prefs.getBool('auto_transaction_notification_enabled') ?? false;
    _defaultWalletId = prefs.getInt('auto_transaction_default_wallet_id');

    Log.d('Settings loaded: SMS=$_smsEnabled, Notification=$_notificationEnabled, WalletId=$_defaultWalletId',
        label: 'AutoTransaction');
  }

  /// Start listening for SMS messages
  Future<bool> _startSmsListening() async {
    if (_smsService == null) return false;

    return await _smsService!.startListening(
      onTransactionParsed: _handleParsedTransaction,
    );
  }

  /// Start listening for notifications
  Future<bool> _startNotificationListening() async {
    if (_notificationService == null) return false;

    return await _notificationService!.startListening(
      onTransactionParsed: _handleParsedTransaction,
    );
  }

  /// Handle a parsed transaction
  void _handleParsedTransaction(ParsedTransaction parsed) async {
    Log.d('Handling parsed transaction: $parsed', label: 'AutoTransaction');

    try {
      // Get wallet to use - first try mapping, then fall back to default
      final wallet = await _getTargetWalletForTransaction(parsed);
      if (wallet == null) {
        Log.e('No wallet available for auto transaction', label: 'AutoTransaction');
        return;
      }

      // Get appropriate category
      final category = await _findBestCategory(parsed);

      // Create transaction model
      final transaction = TransactionModel(
        transactionType: parsed.type,
        amount: parsed.amount,
        date: parsed.dateTime,
        title: parsed.title,
        category: category,
        wallet: wallet,
        notes: '${parsed.notes}\n\n[Auto-created from ${parsed.source}]',
      );

      // Save to database
      final db = _ref.read(databaseProvider);
      final id = await db.transactionDao.addTransaction(transaction);

      Log.d('Auto-created transaction with ID: $id', label: 'AutoTransaction');

      // TODO: Show local notification to user about the new transaction
    } catch (e, stack) {
      Log.e('Failed to create auto transaction: $e', label: 'AutoTransaction');
      Log.e('Stack: $stack', label: 'AutoTransaction');
    }
  }

  /// Get the target wallet for a specific parsed transaction
  /// First checks bank-wallet mapping, then falls back to default wallet
  Future<WalletModel?> _getTargetWalletForTransaction(ParsedTransaction parsed) async {
    // First try to find wallet via bank mapping
    if (parsed.senderId != null) {
      final mappedWalletId = await _mappingService.getWalletIdForSender(parsed.senderId!);
      if (mappedWalletId != null) {
        final db = _ref.read(databaseProvider);
        final wallet = await db.walletDao.getWalletById(mappedWalletId);
        if (wallet != null) {
          Log.d('Using mapped wallet ${wallet.name} for sender ${parsed.senderId}', label: 'AutoTransaction');
          return wallet.toModel();
        }
      }
    }

    // Fall back to default wallet selection
    return _getDefaultWallet();
  }

  /// Get the default wallet (either user-selected default or active wallet)
  Future<WalletModel?> _getDefaultWallet() async {
    // If a default wallet is set, use it
    if (_defaultWalletId != null) {
      final db = _ref.read(databaseProvider);
      final wallet = await db.walletDao.getWalletById(_defaultWalletId!);
      if (wallet != null) {
        return wallet.toModel();
      }
    }

    // Otherwise use the active wallet
    final activeWalletAsync = _ref.read(activeWalletProvider);
    return activeWalletAsync.valueOrNull;
  }

  /// Find the best category for the transaction
  Future<CategoryModel> _findBestCategory(ParsedTransaction parsed) async {
    final categoriesAsync = _ref.read(hierarchicalCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    if (categories.isEmpty) {
      throw Exception('No categories available');
    }

    // Flatten categories for searching
    final allCategories = _flattenCategories(categories);

    // Try to match based on transaction type and merchant
    CategoryModel? matched;

    if (parsed.type == TransactionType.income) {
      // Look for income-related categories
      matched = allCategories.firstWhere(
        (c) => c.title.toLowerCase().contains('income') ||
               c.title.toLowerCase().contains('salary') ||
               c.title.toLowerCase().contains('received'),
        orElse: () => allCategories.first,
      );
    } else {
      // For expenses, try to match merchant to category
      final merchant = parsed.merchant?.toLowerCase() ?? '';

      // Common category mappings
      if (merchant.contains('restaurant') ||
          merchant.contains('cafe') ||
          merchant.contains('food') ||
          merchant.contains('eat')) {
        matched = _findCategoryByKeywords(allCategories, ['food', 'restaurant', 'dining', 'eat']);
      } else if (merchant.contains('grab') ||
                 merchant.contains('uber') ||
                 merchant.contains('taxi') ||
                 merchant.contains('transport')) {
        matched = _findCategoryByKeywords(allCategories, ['transport', 'taxi', 'travel']);
      } else if (merchant.contains('shop') ||
                 merchant.contains('store') ||
                 merchant.contains('mart')) {
        matched = _findCategoryByKeywords(allCategories, ['shopping', 'groceries', 'store']);
      } else if (merchant.contains('electric') ||
                 merchant.contains('water') ||
                 merchant.contains('internet') ||
                 merchant.contains('phone')) {
        matched = _findCategoryByKeywords(allCategories, ['utilities', 'bills', 'electric']);
      }
    }

    // Fallback to first category if no match
    return matched ?? allCategories.first;
  }

  CategoryModel? _findCategoryByKeywords(List<CategoryModel> categories, List<String> keywords) {
    for (final keyword in keywords) {
      final match = categories.firstWhere(
        (c) => c.title.toLowerCase().contains(keyword),
        orElse: () => categories.first,
      );
      if (match.title.toLowerCase().contains(keyword)) {
        return match;
      }
    }
    return null;
  }

  List<CategoryModel> _flattenCategories(List<CategoryModel> categories) {
    final result = <CategoryModel>[];
    for (final cat in categories) {
      result.add(cat);
      if (cat.subCategories != null) {
        result.addAll(_flattenCategories(cat.subCategories!));
      }
    }
    return result;
  }

  /// Enable/disable SMS listening
  Future<void> setSmsEnabled(bool enabled) async {
    _smsEnabled = enabled;

    if (enabled && _smsService != null && _smsService!.isAvailable) {
      // Request permissions first
      final hasPermission = await _smsService!.requestPermissions();
      if (hasPermission) {
        await _startSmsListening();
      } else {
        // Reset setting if permission denied
        _smsEnabled = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auto_transaction_sms_enabled', false);
      }
    } else if (!enabled && _smsService != null) {
      _smsService!.stopListening();
    }
  }

  /// Scan existing SMS messages for transactions
  Future<List<ParsedTransaction>> scanExistingSms({
    int limit = 50,
    Duration? maxAge,
  }) async {
    if (_smsService == null) return [];
    return await _smsService!.scanExistingMessages(
      limit: limit,
      maxAge: maxAge ?? const Duration(days: 7),
    );
  }

  /// Check if SMS permissions are granted
  Future<bool> hasSmsPermission() async {
    return _smsService?.hasPermissions() ?? Future.value(false);
  }

  /// Request SMS permissions
  Future<bool> requestSmsPermission() async {
    return _smsService?.requestPermissions() ?? Future.value(false);
  }

  /// Enable/disable notification listening
  Future<void> setNotificationEnabled(bool enabled) async {
    _notificationEnabled = enabled;

    if (enabled && _notificationService != null && _notificationService!.isAvailable) {
      // Request permissions first (this opens system settings)
      final hasPermission = await _notificationService!.hasPermission();
      if (hasPermission) {
        await _startNotificationListening();
      } else {
        // User needs to grant permission in settings
        await _notificationService!.requestPermission();
        // Check again after user returns
        final granted = await _notificationService!.hasPermission();
        if (granted) {
          await _startNotificationListening();
        } else {
          // Reset setting if permission denied
          _notificationEnabled = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('auto_transaction_notification_enabled', false);
        }
      }
    } else if (!enabled && _notificationService != null) {
      _notificationService!.stopListening();
    }
  }

  /// Check if notification permissions are granted
  Future<bool> hasNotificationPermission() async {
    return _notificationService?.hasPermission() ?? Future.value(false);
  }

  /// Request notification permissions (opens system settings)
  Future<bool> requestNotificationPermission() async {
    return _notificationService?.requestPermission() ?? Future.value(false);
  }

  /// Dispose the service
  void dispose() {
    _smsService?.stopListening();
    _notificationService?.stopListening();
  }

  // ============================================================
  // SMS Scan and Import Methods
  // ============================================================

  /// Scan SMS inbox for bank senders
  Future<List<SmsScanResult>> scanSmsForBankSenders({
    int limit = 500,
    Duration? maxAge,
    void Function(int current, int total)? onProgress,
  }) async {
    await initialize();
    if (_smsService == null) return [];

    return await _smsService!.scanForBankSenders(
      limit: limit,
      maxAge: maxAge ?? const Duration(days: 90),
      onProgress: onProgress,
    );
  }

  /// Create a new wallet for a bank and add mapping
  Future<WalletModel?> createWalletForBank({
    required String bankName,
    required String bankCode,
    required String senderId,
    required String currency,
  }) async {
    try {
      final db = _ref.read(databaseProvider);

      // Create wallet using WalletModel
      final walletModel = WalletModel(
        name: bankName,
        balance: 0,
        currency: currency,
        iconName: 'bank',
        colorHex: _getBankColorHex(bankCode),
        walletType: WalletType.bankAccount,
      );

      final walletId = await db.walletDao.addWallet(walletModel);
      Log.d('Created wallet $bankName with ID: $walletId', label: 'AutoTransaction');

      // Add mapping
      await _mappingService.addMapping(BankWalletMapping(
        senderId: senderId,
        bankName: bankName,
        bankCode: bankCode,
        walletId: walletId,
      ));

      // Get and return the wallet
      final wallet = await db.walletDao.getWalletById(walletId);
      return wallet?.toModel();
    } catch (e) {
      Log.e('Failed to create wallet for bank: $e', label: 'AutoTransaction');
      return null;
    }
  }

  /// Add mapping for existing wallet
  Future<void> addMappingForExistingWallet({
    required String senderId,
    required String bankName,
    required String bankCode,
    required int walletId,
  }) async {
    await _mappingService.addMapping(BankWalletMapping(
      senderId: senderId,
      bankName: bankName,
      bankCode: bankCode,
      walletId: walletId,
    ));
  }

  /// Import transactions for a specific bank into a wallet
  Future<ImportResult> importTransactionsForBank({
    required String bankCode,
    required int walletId,
    int limit = 100,
    Duration? maxAge,
    void Function(int current, int total)? onProgress,
  }) async {
    await initialize();
    if (_smsService == null) {
      return ImportResult(imported: 0, duplicates: 0, errors: 0);
    }

    // Get the wallet
    final db = _ref.read(databaseProvider);
    final walletData = await db.walletDao.getWalletById(walletId);
    if (walletData == null) {
      Log.e('Wallet $walletId not found', label: 'AutoTransaction');
      return ImportResult(imported: 0, duplicates: 0, errors: 0);
    }
    final wallet = walletData.toModel();

    // Parse transactions
    final transactions = await _smsService!.parseTransactionsForSender(
      bankCode: bankCode,
      limit: limit,
      maxAge: maxAge ?? const Duration(days: 90),
      onProgress: onProgress,
    );

    Log.d('Parsed ${transactions.length} transactions for $bankCode', label: 'AutoTransaction');

    int imported = 0;
    int duplicates = 0;
    int errors = 0;

    for (final parsed in transactions) {
      try {
        // Check for duplicate in database
        final isDuplicate = await _checkDuplicateInDb(parsed, walletId);
        if (isDuplicate) {
          duplicates++;
          continue;
        }

        // Get category
        final category = await _findBestCategory(parsed);

        // Create transaction
        final transaction = TransactionModel(
          transactionType: parsed.type,
          amount: parsed.amount,
          date: parsed.dateTime,
          title: parsed.title,
          category: category,
          wallet: wallet,
          notes: '${parsed.notes}\n\n[Imported from SMS]',
        );

        await db.transactionDao.addTransaction(transaction);
        imported++;
      } catch (e) {
        Log.e('Error importing transaction: $e', label: 'AutoTransaction');
        errors++;
      }
    }

    Log.d('Import complete: $imported imported, $duplicates duplicates, $errors errors', label: 'AutoTransaction');
    return ImportResult(imported: imported, duplicates: duplicates, errors: errors);
  }

  /// Check if a similar transaction already exists in the database
  Future<bool> _checkDuplicateInDb(ParsedTransaction parsed, int walletId) async {
    final db = _ref.read(databaseProvider);

    // Get all transactions for this wallet and check for duplicates
    // A duplicate is same amount within 5 minutes of the same time
    final allTransactions = await db.transactionDao.getAllTransactions();

    final startTime = parsed.dateTime.subtract(const Duration(minutes: 5));
    final endTime = parsed.dateTime.add(const Duration(minutes: 5));

    for (final tx in allTransactions) {
      if (tx.walletId != walletId) continue;
      if (tx.date.isBefore(startTime) || tx.date.isAfter(endTime)) continue;

      if ((tx.amount - parsed.amount).abs() < 0.01) {
        return true; // Found duplicate
      }
    }

    return false;
  }

  /// Get bank color for wallet as hex string
  String _getBankColorHex(String bankCode) {
    final colors = {
      'VCB': '006A4E', // Vietcombank green
      'TCB': 'E31837', // Techcombank red
      'TPB': '5B2D8E', // TPBank purple
      'BIDV': '005BA1', // BIDV blue
      'CTG': '004B87', // VietinBank blue
      'AGR': '005C3C', // Agribank green
      'MB': '004B87', // MB Bank blue
      'ACB': '00529B', // ACB blue
      'VPB': '00623B', // VPBank green
      'STB': '00529B', // Sacombank blue
      'MOMO': 'D82D8B', // MoMo pink
      'ZALO': '0068FF', // ZaloPay blue
    };
    return colors[bankCode.toUpperCase()] ?? '6B7280'; // Default gray
  }

  /// Get all bank-wallet mappings
  Future<List<BankWalletMapping>> getAllMappings() async {
    return await _mappingService.getMappings();
  }

  /// Remove a bank-wallet mapping
  Future<void> removeMapping(String senderId) async {
    await _mappingService.removeMapping(senderId);
  }
}

/// Result of importing transactions
class ImportResult {
  final int imported;
  final int duplicates;
  final int errors;

  ImportResult({
    required this.imported,
    required this.duplicates,
    required this.errors,
  });

  int get total => imported + duplicates + errors;
}
