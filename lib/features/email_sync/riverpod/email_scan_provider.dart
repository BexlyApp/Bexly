import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_api_service.dart';
import 'package:bexly/features/email_sync/domain/services/email_parser_service.dart';
import 'package:bexly/features/email_sync/data/models/parsed_email_transaction_model.dart';
import 'package:bexly/features/email_sync/riverpod/email_sync_provider.dart';
import 'package:bexly/features/email_sync/domain/services/email_import_service.dart';

/// Provider for GmailApiService
final gmailApiServiceProvider = Provider<GmailApiService>((ref) {
  return GmailApiService();
});

/// Provider for EmailParserService
final emailParserServiceProvider = Provider<EmailParserService>((ref) {
  return EmailParserService();
});

/// Scan result model
class EmailScanResult {
  final int totalEmails;
  final int parsedCount;
  final int errorCount;
  final List<ParsedEmailTransactionModel> transactions;
  final DateTime scanTime;

  const EmailScanResult({
    required this.totalEmails,
    required this.parsedCount,
    required this.errorCount,
    required this.transactions,
    required this.scanTime,
  });
}

/// State for email scanning
class EmailScanState {
  final bool isScanning;
  final EmailScanResult? lastResult;
  final String? error;
  final double progress;

  const EmailScanState({
    this.isScanning = false,
    this.lastResult,
    this.error,
    this.progress = 0,
  });

  EmailScanState copyWith({
    bool? isScanning,
    EmailScanResult? lastResult,
    String? error,
    double? progress,
  }) {
    return EmailScanState(
      isScanning: isScanning ?? this.isScanning,
      lastResult: lastResult ?? this.lastResult,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }
}

/// Notifier for email scanning
class EmailScanNotifier extends Notifier<EmailScanState> {
  static const _label = 'EmailScan';

  @override
  EmailScanState build() {
    return const EmailScanState();
  }

  /// Scan emails for banking transactions
  Future<EmailScanResult?> scanEmails({
    DateTime? since,
    int maxResults = 50,
  }) async {
    if (state.isScanning) {
      Log.w('Scan already in progress', label: _label);
      return null;
    }

    state = state.copyWith(isScanning: true, progress: 0, error: null);

    try {
      final gmailApi = ref.read(gmailApiServiceProvider);
      final parser = ref.read(emailParserServiceProvider);
      // Unwrap AsyncValue manually (Riverpod 3.x doesn't have valueOrNull)
      final syncState = ref.read(emailSyncProvider);
      final syncSettings = syncState.when(
        data: (data) => data,
        loading: () => null,
        error: (_, _) => null,
      );

      // Get filter domains from settings
      final filterDomains = syncSettings?.enabledBanks;

      Log.i('Starting email scan (since: $since, max: $maxResults)', label: _label);
      state = state.copyWith(progress: 0.1);

      // Fetch emails from Gmail
      final emails = await gmailApi.fetchBankingEmails(
        since: since,
        filterDomains: filterDomains,
        maxResults: maxResults,
      );

      Log.i('Fetched ${emails.length} emails', label: _label);
      state = state.copyWith(progress: 0.5);

      // Parse each email
      final transactions = <ParsedEmailTransactionModel>[];
      int errorCount = 0;

      for (int i = 0; i < emails.length; i++) {
        final email = emails[i];
        try {
          final parsed = parser.parseEmail(email);
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
              createdAt: DateTime.now(),
            ));
          }
        } catch (e) {
          Log.w('Error parsing email ${email.id}: $e', label: _label);
          errorCount++;
        }

        // Update progress
        final progress = 0.5 + (0.4 * (i + 1) / emails.length);
        state = state.copyWith(progress: progress);
      }

      Log.i('Parsed ${transactions.length} transactions from ${emails.length} emails', label: _label);

      // Save to database
      final db = ref.read(databaseProvider);
      int savedCount = 0;
      int skippedCount = 0;

      for (final tx in transactions) {
        // Check if already exists (deduplication by emailId)
        final exists = await db.parsedEmailTransactionDao.isEmailProcessed(tx.emailId);
        if (exists) {
          skippedCount++;
          continue;
        }

        // Insert into database
        await db.parsedEmailTransactionDao.insertParsedTransaction(
          ParsedEmailTransactionsCompanion.insert(
            emailId: tx.emailId,
            emailSubject: tx.emailSubject,
            fromEmail: tx.fromEmail,
            amount: tx.amount,
            currency: Value(tx.currency),
            transactionType: tx.transactionType,
            merchant: Value(tx.merchant),
            accountLast4: Value(tx.accountLast4),
            balanceAfter: Value(tx.balanceAfter),
            transactionDate: tx.transactionDate,
            emailDate: tx.emailDate,
            confidence: Value(tx.confidence),
            rawAmountText: tx.rawAmountText,
            categoryHint: Value(tx.categoryHint),
            bankName: tx.bankName,
          ),
        );
        savedCount++;
      }

      Log.i('Saved $savedCount new transactions, skipped $skippedCount duplicates', label: _label);

      state = state.copyWith(progress: 0.95);

      // Get actual pending count from database
      final pendingCount = await db.parsedEmailTransactionDao.getPendingCount();

      final result = EmailScanResult(
        totalEmails: emails.length,
        parsedCount: transactions.length,
        errorCount: errorCount,
        transactions: transactions,
        scanTime: DateTime.now(),
      );

      state = state.copyWith(
        isScanning: false,
        lastResult: result,
        progress: 1.0,
      );

      // Update sync stats with actual pending count
      final syncNotifier = ref.read(emailSyncProvider.notifier);
      await syncNotifier.updateSyncStats(
        lastSyncTime: DateTime.now(),
        pendingReview: pendingCount,
      );

      return result;
    } catch (e, stack) {
      Log.e('Email scan failed: $e', label: _label);
      Log.e('Stack: $stack', label: _label);

      state = state.copyWith(
        isScanning: false,
        error: e.toString(),
        progress: 0,
      );

      return null;
    }
  }

  /// Cancel ongoing scan
  void cancelScan() {
    if (state.isScanning) {
      state = state.copyWith(isScanning: false, progress: 0);
    }
  }

  /// Clear last result
  void clearResult() {
    state = state.copyWith(lastResult: null, error: null);
  }
}

/// Provider for email scanning
final emailScanProvider = NotifierProvider<EmailScanNotifier, EmailScanState>(
  EmailScanNotifier.new,
);

/// Provider for scanned transactions (pending review)
final pendingEmailTransactionsProvider = Provider<List<ParsedEmailTransactionModel>>((ref) {
  final scanState = ref.watch(emailScanProvider);
  return scanState.lastResult?.transactions ?? [];
});

/// Provider for scan progress
final emailScanProgressProvider = Provider<double>((ref) {
  return ref.watch(emailScanProvider).progress;
});

/// Provider for checking if scan is in progress
final isEmailScanningProvider = Provider<bool>((ref) {
  return ref.watch(emailScanProvider).isScanning;
});

/// Provider for EmailImportService
final emailImportServiceProvider = Provider<EmailImportService>((ref) {
  final db = ref.watch(databaseProvider);
  return EmailImportService(db);
});

/// State for import operation
class EmailImportState {
  final bool isImporting;
  final ImportResult? lastResult;
  final String? error;

  const EmailImportState({
    this.isImporting = false,
    this.lastResult,
    this.error,
  });

  EmailImportState copyWith({
    bool? isImporting,
    ImportResult? lastResult,
    String? error,
  }) {
    return EmailImportState(
      isImporting: isImporting ?? this.isImporting,
      lastResult: lastResult ?? this.lastResult,
      error: error ?? this.error,
    );
  }
}

/// Notifier for importing approved transactions
class EmailImportNotifier extends Notifier<EmailImportState> {
  static const _label = 'EmailImport';

  @override
  EmailImportState build() {
    return const EmailImportState();
  }

  /// Import all approved transactions
  Future<ImportResult?> importAllApproved() async {
    if (state.isImporting) {
      Log.w('Import already in progress', label: _label);
      return null;
    }

    state = state.copyWith(isImporting: true, error: null);

    try {
      final importService = ref.read(emailImportServiceProvider);
      final result = await importService.importAllApproved();

      state = state.copyWith(
        isImporting: false,
        lastResult: result,
      );

      // Update pending count in sync stats
      final db = ref.read(databaseProvider);
      final pendingCount = await db.parsedEmailTransactionDao.getPendingCount();
      final syncNotifier = ref.read(emailSyncProvider.notifier);
      await syncNotifier.updateSyncStats(pendingReview: pendingCount);

      return result;
    } catch (e, stack) {
      Log.e('Import failed: $e', label: _label);
      Log.e('Stack: $stack', label: _label);

      state = state.copyWith(
        isImporting: false,
        error: e.toString(),
      );

      return null;
    }
  }

  /// Clear last result
  void clearResult() {
    state = state.copyWith(lastResult: null, error: null);
  }
}

/// Provider for email import
final emailImportProvider = NotifierProvider<EmailImportNotifier, EmailImportState>(
  EmailImportNotifier.new,
);

/// Provider for checking if import is in progress
final isEmailImportingProvider = Provider<bool>((ref) {
  return ref.watch(emailImportProvider).isImporting;
});
