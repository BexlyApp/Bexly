import 'dart:async';
import 'package:drift/drift.dart';
import 'package:workmanager/workmanager.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_api_service.dart';
import 'package:bexly/features/email_sync/domain/services/email_parser_service.dart' as parser;
import 'package:bexly/features/email_sync/domain/services/llm_email_parser_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background worker for email sync
///
/// This worker runs periodically in the background (even when app is closed)
/// to scan Gmail for new banking transactions.
class EmailSyncWorker {
  static const _label = 'EmailSyncWorker';

  /// Task name for background sync
  static const taskName = 'email_sync_periodic';

  /// Unique task tag
  static const taskTag = 'email_sync';

  /// Register periodic background sync
  ///
  /// [frequency] - How often to sync (in hours): 12 or 24
  static Future<void> registerPeriodicSync({required int frequencyHours}) async {
    try {
      Log.i('Registering periodic sync: every $frequencyHours hours', label: _label);

      // Cancel existing task first
      await Workmanager().cancelByUniqueName(taskTag);

      // Register new periodic task
      await Workmanager().registerPeriodicTask(
        taskTag,
        taskName,
        frequency: Duration(hours: frequencyHours),
        initialDelay: Duration(minutes: 5), // First sync after 5 minutes
        constraints: Constraints(
          networkType: NetworkType.connected, // Require internet
          requiresBatteryNotLow: true, // Don't run when battery < 20%
        ),
        inputData: {
          'frequency_hours': frequencyHours,
        },
      );

      Log.i('✅ Periodic sync registered successfully', label: _label);
    } catch (e) {
      Log.e('Failed to register periodic sync: $e', label: _label);
      rethrow;
    }
  }

  /// Cancel periodic background sync
  static Future<void> cancelPeriodicSync() async {
    try {
      Log.i('Cancelling periodic sync', label: _label);
      await Workmanager().cancelByUniqueName(taskTag);
      Log.i('✅ Periodic sync cancelled', label: _label);
    } catch (e) {
      Log.e('Failed to cancel periodic sync: $e', label: _label);
    }
  }

  /// Background callback - runs in isolate
  ///
  /// This is called by WorkManager when it's time to sync.
  /// App doesn't need to be open - OS will wake it up.
  static Future<bool> syncCallback() async {
    try {
      Log.i('🔄 Background sync started', label: _label);

      // 1. Check if email sync is enabled
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('email_sync_is_enabled') ?? false;
      final gmailEmail = prefs.getString('email_sync_gmail_email');

      if (!isEnabled || gmailEmail == null) {
        Log.i('Email sync disabled or not connected, skipping', label: _label);
        return true; // Return true to indicate task completed successfully
      }

      // 2. Initialize services
      final gmailApi = GmailApiService();
      final regexParser = parser.EmailParserService();
      final llmParser = LLMEmailParserService();

      // Get enabled banks from prefs
      final enabledBanks = prefs.getStringList('email_sync_enabled_banks') ?? [];

      // 3. Fetch emails from last 7 days (to catch recent transactions)
      final since = DateTime.now().subtract(const Duration(days: 7));

      Log.i('Fetching emails since $since', label: _label);
      final emails = await gmailApi.fetchBankingEmails(
        since: since,
        filterDomains: enabledBanks.isNotEmpty ? enabledBanks : null,
        maxResults: 50,
      );

      Log.i('Fetched ${emails.length} emails', label: _label);

      // 4. Parse emails (LLM first, fallback to regex)
      final transactions = <ParsedEmailTransactionModel>[];
      int llmSuccessCount = 0;
      int regexFallbackCount = 0;

      for (final email in emails) {
        try {
          // Try LLM parser first
          parser.ParsedEmail? parsed;
          try {
            parsed = await llmParser.parseEmail(email);
            if (parsed != null) {
              llmSuccessCount++;
            }
          } catch (e) {
            Log.w('LLM parser failed for ${email.id}, falling back to regex: $e', label: _label);
          }

          // Fallback to regex parser if LLM failed
          if (parsed == null) {
            parsed = regexParser.parseEmail(email);
            if (parsed != null) {
              regexFallbackCount++;
            }
          }

          if (parsed != null) {
            transactions.add(ParsedEmailTransactionModel(
              emailId: parsed.emailId,
              emailSubject: parsed.emailSubject,
              fromEmail: parsed.fromEmail,
              amount: parsed.amount,
              currency: parsed.currency,
              transactionType: parsed.transactionType,
              merchant: parsed.merchant,
              accountLast4: parsed.accountLast4,
              balanceAfter: parsed.balanceAfter,
              transactionDate: parsed.transactionDate,
              emailDate: parsed.emailDate,
              confidence: parsed.confidence,
              rawAmountText: parsed.rawAmountText,
              categoryHint: parsed.categoryHint,
              bankName: parsed.bankName,
            ));
          }
        } catch (e) {
          Log.w('Error parsing email ${email.id}: $e', label: _label);
        }
      }

      Log.i('Parsed ${transactions.length} transactions (LLM: $llmSuccessCount, Regex: $regexFallbackCount)', label: _label);

      if (transactions.isEmpty) {
        Log.i('No new transactions found', label: _label);

        // Update last sync time
        await prefs.setInt(
          'email_sync_last_sync_time',
          DateTime.now().millisecondsSinceEpoch,
        );

        return true;
      }

      // 5. Save to database
      final db = AppDatabase();
      int savedCount = 0;

      for (final tx in transactions) {
        // Check if already exists (deduplication)
        final exists = await db.parsedEmailTransactionDao.isEmailProcessed(tx.emailId);
        if (exists) continue;

        // Insert new transaction
        await db.parsedEmailTransactionDao.insertParsedTransaction(
          ParsedEmailTransactionsCompanion.insert(
            emailId: tx.emailId,
            emailSubject: tx.emailSubject,
            fromEmail: tx.fromEmail,
            amount: tx.amount,
            currency: tx.currency != null ? Value(tx.currency!) : const Value.absent(),
            transactionType: tx.transactionType,
            merchant: Value(tx.merchant),
            accountLast4: Value(tx.accountLast4),
            balanceAfter: Value(tx.balanceAfter),
            transactionDate: tx.transactionDate,
            emailDate: tx.emailDate,
            confidence: tx.confidence != null ? Value(tx.confidence!) : const Value.absent(),
            rawAmountText: tx.rawAmountText,
            categoryHint: Value(tx.categoryHint),
            bankName: tx.bankName,
          ),
        );
        savedCount++;
      }

      Log.i('Saved $savedCount new transactions', label: _label);

      // 6. Update sync stats in SharedPreferences
      final pendingCount = await db.parsedEmailTransactionDao.getPendingCount();
      await prefs.setInt('email_sync_last_sync_time', DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt('email_sync_pending_review', pendingCount);

      // Close database
      await db.close();

      // 7. Show notification if found new transactions
      if (savedCount > 0) {
        Log.i('📧 Found $savedCount new transactions - should show notification', label: _label);
        // TODO: Show local notification
        // Use flutter_local_notifications to show:
        // "Found $savedCount new transactions from Gmail"
        // Tap to open app → Email Review screen
      }

      Log.i('✅ Background sync completed successfully', label: _label);
      return true;
    } catch (e, stack) {
      Log.e('❌ Background sync failed: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      return false; // Return false to indicate task failed
    }
  }
}

/// Model for parsed email transaction (lightweight, for worker)
class ParsedEmailTransactionModel {
  final String emailId;
  final String emailSubject;
  final String fromEmail;
  final double amount;
  final String? currency;
  final String transactionType;
  final String? merchant;
  final String? accountLast4;
  final double? balanceAfter;
  final DateTime transactionDate;
  final DateTime emailDate;
  final double? confidence;
  final String rawAmountText;
  final String? categoryHint;
  final String bankName;

  const ParsedEmailTransactionModel({
    required this.emailId,
    required this.emailSubject,
    required this.fromEmail,
    required this.amount,
    this.currency,
    required this.transactionType,
    this.merchant,
    this.accountLast4,
    this.balanceAfter,
    required this.transactionDate,
    required this.emailDate,
    this.confidence,
    required this.rawAmountText,
    this.categoryHint,
    required this.bankName,
  });
}
