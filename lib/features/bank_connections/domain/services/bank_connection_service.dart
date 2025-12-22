import 'package:cloud_functions/cloud_functions.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/stripe/stripe_service.dart';
import 'package:bexly/features/bank_connections/data/models/linked_account_model.dart';

/// Service for managing bank connections via Stripe Financial Connections
class BankConnectionService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1', // Financial Connections functions are in US
  );

  /// Create a Financial Connection session and launch the account linking flow
  /// Returns list of linked accounts on success
  static Future<List<LinkedAccount>> linkBankAccounts() async {
    Log.i('Starting bank account linking flow', label: 'BankConnection');

    try {
      // Step 1: Create session via Cloud Function
      final createSession = _functions.httpsCallable('createFinancialConnectionSession');
      final sessionResult = await createSession.call<Map<String, dynamic>>({
        'returnUrl': 'bexly://bank-connections/callback',
      });

      final clientSecret = sessionResult.data['clientSecret'] as String?;
      final sessionId = sessionResult.data['sessionId'] as String?;

      if (clientSecret == null || sessionId == null) {
        throw Exception('Invalid session response');
      }

      Log.i('Created session: $sessionId', label: 'BankConnection');

      // Step 2: Launch Stripe Financial Connections UI
      final result = await StripeService.collectBankAccounts(
        clientSecret: clientSecret,
      );

      if (result == null) {
        Log.w('User cancelled bank account linking', label: 'BankConnection');
        return [];
      }

      Log.i('User completed Financial Connections flow', label: 'BankConnection');

      // Step 3: Complete the connection and save accounts
      final completeConnection = _functions.httpsCallable('completeFinancialConnection');
      final completeResult = await completeConnection.call<Map<String, dynamic>>({
        'sessionId': sessionId,
      });

      final accountsData = completeResult.data['accounts'] as List<dynamic>?;
      if (accountsData == null) {
        return [];
      }

      final accounts = accountsData
          .map((a) => LinkedAccount.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();

      Log.i('Linked ${accounts.length} accounts', label: 'BankConnection');
      return accounts;
    } on FirebaseFunctionsException catch (e) {
      Log.e('Firebase Functions error: ${e.code} - ${e.message}', label: 'BankConnection');
      rethrow;
    } catch (e) {
      Log.e('Failed to link bank accounts: $e', label: 'BankConnection');
      rethrow;
    }
  }

  /// Get all linked bank accounts for current user
  static Future<List<LinkedAccount>> getLinkedAccounts() async {
    try {
      final callable = _functions.httpsCallable('getLinkedAccounts');
      final result = await callable.call<Map<String, dynamic>>({});

      final accountsData = result.data['accounts'] as List<dynamic>?;
      if (accountsData == null) {
        return [];
      }

      return accountsData
          .map((a) => LinkedAccount.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      Log.e('Failed to get linked accounts: ${e.code} - ${e.message}', label: 'BankConnection');
      rethrow;
    }
  }

  /// Sync transactions from linked accounts
  static Future<int> syncTransactions({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Log.i('Syncing transactions...', label: 'BankConnection');

    try {
      final callable = _functions.httpsCallable(
        'syncFinancialConnectionTransactions',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        if (accountId != null) 'accountId': accountId,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      });

      final count = result.data['transactionCount'] as int? ?? 0;
      Log.i('Synced $count transactions', label: 'BankConnection');
      return count;
    } on FirebaseFunctionsException catch (e) {
      Log.e('Failed to sync transactions: ${e.code} - ${e.message}', label: 'BankConnection');
      rethrow;
    }
  }

  /// Disconnect a linked bank account
  static Future<void> disconnectAccount(String accountId) async {
    Log.i('Disconnecting account: $accountId', label: 'BankConnection');

    try {
      final callable = _functions.httpsCallable('disconnectFinancialAccount');
      await callable.call<Map<String, dynamic>>({
        'accountId': accountId,
      });

      Log.i('Disconnected account: $accountId', label: 'BankConnection');
    } on FirebaseFunctionsException catch (e) {
      Log.e('Failed to disconnect account: ${e.code} - ${e.message}', label: 'BankConnection');
      rethrow;
    }
  }
}
