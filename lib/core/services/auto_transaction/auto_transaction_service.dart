import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/core/services/ai/background_ai_service.dart';
import 'package:bexly/core/services/auto_transaction/bank_wallet_mapping.dart';
import 'package:bexly/core/services/auto_transaction/parsed_transaction.dart';
import 'package:bexly/core/services/auto_transaction/sms_service.dart';
import 'package:bexly/core/services/auto_transaction/notification_service.dart';
import 'package:bexly/core/services/auto_transaction/transaction_parser_service.dart';
import 'package:bexly/core/services/auto_transaction/pending_notification.dart';
import 'package:bexly/core/services/auto_transaction/account_identifier.dart';

/// Provider for auto transaction service
final autoTransactionServiceProvider = Provider<AutoTransactionService>((ref) {
  return AutoTransactionService(ref);
});

/// Service to manage auto transaction creation from SMS/notifications
class AutoTransactionService {
  final Ref _ref;
  SmsService? _smsService;
  NotificationListenerServiceWrapper? _notificationService;
  AIDuplicateCheckService? _aiDuplicateCheckService;
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

    // Initialize AI service using configured provider
    if (!BackgroundAIService.isAvailable) {
      Log.w('No AI provider available, auto transaction disabled', label: 'AutoTransaction');
      return;
    }

    final backgroundAI = BackgroundAIService();
    final parserService = TransactionParserService(ai: backgroundAI);
    final deduplicationService = TransactionDeduplicationService();
    _aiDuplicateCheckService = AIDuplicateCheckService(ai: backgroundAI);

    _smsService = SmsService(
      parserService: parserService,
      deduplicationService: deduplicationService,
    );
    _notificationService = NotificationListenerServiceWrapper(
      parserService: parserService,
      deduplicationService: deduplicationService,
    );

    // Check if there's a pending notification permission request.
    // Android may kill the app when the user toggles notification listener
    // permission in system settings. On restart, this check detects that
    // the permission was granted and auto-enables the listener.
    await _checkPendingNotificationPermissionOnStartup();

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

  /// Check if there's a pending notification permission request from before
  /// the app was killed by Android.
  Future<void> _checkPendingNotificationPermissionOnStartup() async {
    if (_notificationService == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingRequest = prefs.getBool('pending_notification_permission_request') ?? false;
      if (!pendingRequest) return;

      Log.d('Detected pending notification permission request from before app kill',
          label: 'AutoTransaction');

      final granted = await _notificationService!.hasPermission();

      // Clear the flag regardless
      await prefs.remove('pending_notification_permission_request');

      if (granted) {
        _notificationEnabled = true;
        await prefs.setBool('auto_transaction_notification_enabled', true);
        Log.d('Notification listener permission granted after app restart — auto-enabled',
            label: 'AutoTransaction');
      } else {
        Log.w('Notification listener permission NOT granted after app restart',
            label: 'AutoTransaction');
      }
    } catch (e) {
      Log.e('Error checking pending notification permission: $e', label: 'AutoTransaction');
    }
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

  /// Handle a parsed transaction — routes to Pending Tab for user review
  void _handleParsedTransaction(ParsedTransaction parsed) async {
    Log.d('Handling parsed transaction: $parsed', label: 'AutoTransaction');

    try {
      await _addToPendingTab(parsed);
    } catch (e, stack) {
      Log.e('Failed to add to pending tab: $e', label: 'AutoTransaction');
      Log.e('Stack: $stack', label: 'AutoTransaction');
    }
  }

  /// Add a parsed transaction to the pending_transactions table.
  ///
  /// Flow: parse → hash dedup → DB dedup → AI duplicate check → insert to pending
  /// All automation sources (SMS, notification, email) go through this.
  Future<bool> _addToPendingTab(ParsedTransaction parsed) async {
    final db = _ref.read(databaseProvider);
    final sourceId = parsed.deduplicationHash;

    // 1. Check if already exists in pending_transactions (source+sourceId unique)
    final alreadyProcessed = await db.pendingTransactionDao.isAlreadyProcessed(
      parsed.source,
      sourceId,
    );
    if (alreadyProcessed) {
      Log.d('Already in pending tab, skipping: $sourceId', label: 'AutoTransaction');
      return false;
    }

    // 2. AI duplicate check against existing transactions in DB
    String? duplicateNote;
    final isDuplicate = await _aiDuplicateCheckAgainstDb(parsed);
    if (isDuplicate) {
      duplicateNote = '[AI: Possible duplicate of existing transaction]';
      Log.d('AI flagged as possible duplicate: $parsed', label: 'AutoTransaction');
    }

    // 3. Try to find target wallet
    final wallet = await _getTargetWalletForTransaction(parsed);

    // 4. Build category hint from merchant
    final categoryHint = parsed.merchant;

    // 5. Insert to pending_transactions table
    final now = DateTime.now();
    await db.pendingTransactionDao.insertOrIgnore(PendingTransactionsCompanion(
      source: Value(parsed.source),
      sourceId: Value(sourceId),
      amount: Value(parsed.amount),
      currency: Value(parsed.currency),
      transactionType: Value(
        parsed.type == TransactionType.income ? 'income' : 'expense',
      ),
      title: Value(parsed.title),
      merchant: Value(parsed.merchant),
      transactionDate: Value(parsed.dateTime),
      confidence: const Value(0.8),
      categoryHint: Value(categoryHint),
      sourceDisplayName: Value(parsed.bankName ?? parsed.source),
      accountIdentifier: Value(parsed.accountNumber),
      targetWalletId: wallet != null ? Value(wallet.id!) : const Value.absent(),
      rawSourceData: Value(jsonEncode(parsed.toJson())),
      userNotes: duplicateNote != null ? Value(duplicateNote) : const Value.absent(),
      status: const Value('pending_review'),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    Log.d('Added to pending tab: ${parsed.title} (${parsed.amount})',
        label: 'AutoTransaction');
    return true;
  }

  /// Run AI duplicate check against existing transactions in the database.
  ///
  /// Pre-filters by amount (±20%) and date (last 7 days) before calling AI.
  Future<bool> _aiDuplicateCheckAgainstDb(ParsedTransaction parsed) async {
    if (_aiDuplicateCheckService == null) return false;

    try {
      final db = _ref.read(databaseProvider);
      final allTx = await db.transactionDao.getAllTransactions();

      // Pre-filter: same amount ±20%, within last 7 days
      final amountLow = parsed.amount * 0.8;
      final amountHigh = parsed.amount * 1.2;
      final dateCutoff = parsed.dateTime.subtract(const Duration(days: 7));

      final candidates = allTx.where((tx) {
        if (tx.amount < amountLow || tx.amount > amountHigh) return false;
        if (tx.date.isBefore(dateCutoff)) return false;
        return true;
      }).take(10).map((tx) => {
        'amount': tx.amount,
        'date': tx.date.toIso8601String(),
        'title': tx.title,
        'notes': tx.notes ?? '',
      }).toList();

      if (candidates.isEmpty) return false;

      return await _aiDuplicateCheckService!.isDuplicate(
        parsed: parsed,
        candidates: candidates,
      );
    } catch (e) {
      Log.w('AI duplicate check error: $e', label: 'AutoTransaction');
      return false; // On error, allow through
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
    return activeWalletAsync.value;
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

  /// Request notification permissions (opens system settings).
  /// Android may kill the app when the user toggles the permission.
  Future<void> requestNotificationPermission() async {
    await _notificationService?.requestPermission();
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
    DateTime? startDate,
    Duration? maxAge,
    void Function(int current, int total)? onProgress,
  }) async {
    await initialize();
    if (_smsService == null) return [];

    // Calculate maxAge from startDate if provided
    Duration effectiveMaxAge;
    if (startDate != null) {
      effectiveMaxAge = DateTime.now().difference(startDate);
    } else {
      effectiveMaxAge = maxAge ?? const Duration(days: 90);
    }

    return await _smsService!.scanForBankSenders(
      limit: limit,
      maxAge: effectiveMaxAge,
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

  /// Import transactions for a specific bank into pending tab for review
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

    // Verify wallet exists
    final db = _ref.read(databaseProvider);
    final walletData = await db.walletDao.getWalletById(walletId);
    if (walletData == null) {
      Log.e('Wallet $walletId not found', label: 'AutoTransaction');
      return ImportResult(imported: 0, duplicates: 0, errors: 0);
    }

    // Parse transactions from SMS
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
        final added = await _addToPendingTab(parsed);
        if (added) {
          imported++;
        } else {
          duplicates++;
        }
      } catch (e) {
        Log.e('Error adding to pending: $e', label: 'AutoTransaction');
        errors++;
      }
    }

    Log.d('Import to pending complete: $imported added, $duplicates skipped, $errors errors',
        label: 'AutoTransaction');
    return ImportResult(imported: imported, duplicates: duplicates, errors: errors);
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

  // ============================================================
  // Pending Notification Methods
  // ============================================================

  /// Check if there are pending notifications to process
  Future<bool> hasPendingNotifications() async {
    if (_notificationService == null) return false;
    return await _notificationService!.hasPendingNotifications();
  }

  /// Get pending notification count
  Future<int> getPendingNotificationCount() async {
    if (_notificationService == null) return 0;
    return await _notificationService!.getPendingCount();
  }

  /// Get all unprocessed pending notifications
  Future<List<PendingNotification>> getUnprocessedNotifications() async {
    if (_notificationService == null) return [];
    return await _notificationService!.getUnprocessedNotifications();
  }

  /// Get pending notifications grouped by bank
  Future<Map<String, List<PendingNotification>>> getPendingNotificationsByBank() async {
    if (_notificationService == null) return {};
    return await _notificationService!.getPendingByBank();
  }

  /// Get pending notifications grouped by bank and account
  Future<Map<String, List<PendingNotification>>> getPendingNotificationsByBankAndAccount() async {
    if (_notificationService == null) return {};
    return await _notificationService!.getPendingByBankAndAccount();
  }

  /// Enable pending mode for notifications (store instead of process)
  void setNotificationPendingMode(bool enabled) {
    _notificationService?.setStorePendingMode(enabled);
  }

  /// Process pending notifications and add to pending tab for review
  ///
  /// This method should be called when the user opens the app and
  /// there are pending notifications that need wallet mapping.
  Future<PendingProcessResult> processPendingNotifications({
    required Map<String, int> bankAccountToWalletMap, // "bankCode_accountId" -> walletId
  }) async {
    await initialize();
    if (_notificationService == null) {
      return PendingProcessResult(processed: 0, skipped: 0, errors: 0);
    }

    final pending = await _notificationService!.getUnprocessedNotifications();
    int processed = 0;
    int skipped = 0;
    int errors = 0;

    for (final notification in pending) {
      try {
        // Parse the notification
        final parsed = await _notificationService!.processPendingNotification(notification);
        if (parsed == null) {
          Log.d('Could not parse notification ${notification.id}', label: 'AutoTransaction');
          errors++;
          continue;
        }

        // Add to pending tab (includes AI duplicate check)
        final added = await _addToPendingTab(parsed);
        if (added) {
          processed++;
        } else {
          skipped++;
        }

        Log.d('Processed notification ${notification.id} → pending tab', label: 'AutoTransaction');
      } catch (e) {
        Log.e('Error processing pending notification: $e', label: 'AutoTransaction');
        errors++;
      }
    }

    Log.d('Processed notifications: $processed added to pending, $skipped skipped, $errors errors',
        label: 'AutoTransaction');

    return PendingProcessResult(processed: processed, skipped: skipped, errors: errors);
  }

  /// Create wallet for a bank/account from pending notifications
  ///
  /// This creates a wallet and mapping for notifications that don't have
  /// a wallet assigned yet.
  Future<WalletModel?> createWalletForPendingNotifications({
    required String bankCode,
    required String? accountId,
    required String bankName,
    required String currency,
    String? accountType,
  }) async {
    try {
      final db = _ref.read(databaseProvider);

      // Generate wallet name with account info
      final walletName = AccountIdentifier.generateDisplayName(
        bankName,
        accountId,
        accountType,
      );

      // Create wallet
      final walletModel = WalletModel(
        name: walletName,
        balance: 0,
        currency: currency,
        iconName: 'bank',
        colorHex: _getBankColorHex(bankCode),
        walletType: accountType == 'credit' ? WalletType.creditCard : WalletType.bankAccount,
      );

      final walletId = await db.walletDao.addWallet(walletModel);
      Log.d('Created wallet $walletName with ID: $walletId', label: 'AutoTransaction');

      // Add mapping with account ID
      await _mappingService.addMapping(BankWalletMapping(
        senderId: bankCode, // Use bank code as sender ID for notifications
        bankName: bankName,
        bankCode: bankCode,
        walletId: walletId,
        accountId: accountId,
        accountType: accountType,
      ));

      // Get and return the wallet
      final wallet = await db.walletDao.getWalletById(walletId);
      return wallet?.toModel();
    } catch (e) {
      Log.e('Failed to create wallet for pending notifications: $e', label: 'AutoTransaction');
      return null;
    }
  }

  /// Mark pending notifications as processed without creating transactions
  Future<void> dismissPendingNotifications(List<String> notificationIds) async {
    if (_notificationService == null) return;
    await _notificationService!.markMultiplePendingAsProcessed(notificationIds);
  }

  /// Clear all processed pending notifications
  Future<void> clearProcessedNotifications() async {
    if (_notificationService == null) return;
    await _notificationService!.clearProcessedNotifications();
  }

  /// Check for pending notifications on app startup
  ///
  /// Returns a summary of pending notifications grouped by bank and account.
  /// The UI should use this to show a dialog asking the user to create wallets
  /// or assign existing wallets to the pending notifications.
  Future<PendingNotificationSummary> checkPendingOnStartup() async {
    await initialize();

    if (_notificationService == null || !_notificationEnabled) {
      return PendingNotificationSummary.empty();
    }

    final hasPending = await _notificationService!.hasPendingNotifications();
    if (!hasPending) {
      return PendingNotificationSummary.empty();
    }

    final grouped = await _notificationService!.getPendingByBankAndAccount();
    final entries = <PendingNotificationGroup>[];

    for (final entry in grouped.entries) {
      final notifications = entry.value;
      if (notifications.isEmpty) continue;

      final first = notifications.first;
      final bankCode = first.bankCode ?? 'unknown';
      final accountId = first.accountId;
      final accountType = first.accountType;

      // Check if we already have a mapping for this bank/account
      final existingWalletId = await _mappingService.getWalletIdForSender(
        bankCode,
        accountId: accountId,
      );

      entries.add(PendingNotificationGroup(
        bankCode: bankCode,
        bankName: first.appName ?? bankCode,
        accountId: accountId,
        accountType: accountType,
        notificationCount: notifications.length,
        notifications: notifications,
        existingWalletId: existingWalletId,
      ));
    }

    return PendingNotificationSummary(groups: entries);
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

/// Result of processing pending notifications
class PendingProcessResult {
  final int processed;
  final int skipped;
  final int errors;

  PendingProcessResult({
    required this.processed,
    required this.skipped,
    required this.errors,
  });

  int get total => processed + skipped + errors;
}

/// Summary of pending notifications for startup check
class PendingNotificationSummary {
  final List<PendingNotificationGroup> groups;

  PendingNotificationSummary({required this.groups});

  factory PendingNotificationSummary.empty() {
    return PendingNotificationSummary(groups: []);
  }

  bool get isEmpty => groups.isEmpty;
  bool get isNotEmpty => groups.isNotEmpty;

  int get totalNotifications =>
      groups.fold(0, (sum, g) => sum + g.notificationCount);

  /// Groups that don't have a wallet assigned yet
  List<PendingNotificationGroup> get unmappedGroups =>
      groups.where((g) => g.existingWalletId == null).toList();

  /// Groups that already have a wallet assigned
  List<PendingNotificationGroup> get mappedGroups =>
      groups.where((g) => g.existingWalletId != null).toList();
}

/// A group of pending notifications from the same bank/account
class PendingNotificationGroup {
  final String bankCode;
  final String bankName;
  final String? accountId;
  final String? accountType;
  final int notificationCount;
  final List<PendingNotification> notifications;
  final int? existingWalletId;

  PendingNotificationGroup({
    required this.bankCode,
    required this.bankName,
    this.accountId,
    this.accountType,
    required this.notificationCount,
    required this.notifications,
    this.existingWalletId,
  });

  /// Display name for this group
  String get displayName => AccountIdentifier.generateDisplayName(
        bankName,
        accountId,
        accountType,
      );

  /// Mapping key for this group
  String get mappingKey => accountId != null
      ? '${bankCode}_$accountId'
      : bankCode;

  /// Whether this group has a wallet assigned
  bool get hasWallet => existingWalletId != null;
}
