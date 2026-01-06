import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/stripe/stripe_service.dart';
import 'package:bexly/core/services/firebase_init_service.dart';
import 'package:bexly/features/bank_connections/data/models/linked_account_model.dart';

/// Service for managing bank connections via Stripe Financial Connections
/// Uses dos-me HTTP API (handles all user data)
class BankConnectionService {
  static const String _baseUrl = 'https://api-v2.dos.me/bank';
  static const String _label = 'BankConnection';

  /// Get Firebase ID token for authentication (force refresh to avoid expired token)
  static Future<String> _getIdToken() async {
    final dosmeApp = FirebaseInitService.dosmeApp;
    if (dosmeApp == null) {
      throw Exception('DOS-Me Firebase not initialized');
    }
    final auth = FirebaseAuth.instanceFor(app: dosmeApp);
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    // Force refresh token to ensure it's not expired
    final token = await user.getIdToken(true);
    if (token == null) {
      throw Exception('Failed to get ID token');
    }
    Log.i('Got ID token for user: ${user.uid}', label: _label);
    return token;
  }

  /// Create a Financial Connection session and launch the account linking flow
  /// Returns list of linked accounts on success
  static Future<List<LinkedAccount>> linkBankAccounts() async {
    Log.i('Starting bank account linking flow', label: _label);

    try {
      final idToken = await _getIdToken();
      Log.d('Got token, creating session at $_baseUrl/session', label: _label);

      // Step 1: Create session via DOS-Me API
      final sessionResponse = await http.post(
        Uri.parse('$_baseUrl/session'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // Note: returnUrl is required by Stripe but not used in native SDK flow
          // Using https URL as Stripe doesn't accept custom URL schemes
          'returnUrl': 'https://bexly.app/bank-callback',
        }),
      );

      Log.d('POST /session response status: ${sessionResponse.statusCode}', label: _label);
      Log.d('POST /session response headers: ${sessionResponse.headers}', label: _label);
      Log.d('POST /session response body: ${sessionResponse.body}', label: _label);

      if (sessionResponse.statusCode != 200 && sessionResponse.statusCode != 201) {
        Log.e('API error: ${sessionResponse.statusCode}', label: _label);
        throw Exception('API error: ${sessionResponse.statusCode} - ${sessionResponse.body}');
      }

      final sessionData = jsonDecode(sessionResponse.body) as Map<String, dynamic>;
      if (sessionData['success'] != true) {
        final errorMsg = sessionData['message'] ?? sessionData['error']?['message'] ?? 'Failed to create session';
        Log.e('Session creation failed: $errorMsg', label: _label);
        throw Exception(errorMsg);
      }

      final clientSecret = sessionData['data']?['clientSecret'] as String?;
      final sessionId = sessionData['data']?['sessionId'] as String?;

      if (clientSecret == null || sessionId == null) {
        Log.e('Missing clientSecret or sessionId in response', label: _label);
        throw Exception('Invalid session response: missing clientSecret or sessionId');
      }

      Log.i('Created session: $sessionId, clientSecret length: ${clientSecret.length}', label: _label);

      // Step 2: Launch Stripe Financial Connections UI
      Log.d('Launching Stripe Financial Connections UI...', label: _label);
      bool stripeFlowCanceled = false;
      bool userExplicitlyDismissed = false;
      try {
        final result = await StripeService.collectBankAccounts(
          clientSecret: clientSecret,
        );

        if (result == null) {
          // User might have dismissed the sheet manually (before completing)
          // But we should STILL try to complete - they might have connected accounts
          // before dismissing
          Log.w('Stripe SDK returned null - user may have dismissed early', label: _label);
          userExplicitlyDismissed = true;
        } else {
          Log.d('Stripe UI completed successfully with result', label: _label);
        }
      } catch (stripeError) {
        // Check if this is a "canceled" error - the webview might have issues
        // but the connection could still be successful on Stripe's backend
        final errorStr = stripeError.toString().toLowerCase();
        if (errorStr.contains('cancel')) {
          Log.w('Stripe flow reported canceled, but will try to complete anyway', label: _label);
          stripeFlowCanceled = true;
        } else {
          Log.e('STRIPE SDK ERROR: $stripeError', label: _label);
          Log.e('Stripe error type: ${stripeError.runtimeType}', label: _label);
          rethrow;
        }
      }

      Log.i('Proceeding to complete Financial Connections flow (canceled=$stripeFlowCanceled, dismissed=$userExplicitlyDismissed)', label: _label);

      // ALWAYS wait for Stripe webhook to be processed on backend
      // Even on "success", Stripe may not have updated the session yet
      Log.d('Waiting 3 seconds for Stripe webhook processing...', label: _label);
      await Future.delayed(const Duration(seconds: 3));

      // Step 3: Complete the connection and save accounts
      Log.d('Calling POST /complete with sessionId: $sessionId', label: _label);
      final completeResponse = await http.post(
        Uri.parse('$_baseUrl/complete'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sessionId': sessionId,
        }),
      );

      Log.d('POST /complete response status: ${completeResponse.statusCode}', label: _label);
      Log.d('POST /complete response body: ${completeResponse.body}', label: _label);
      final completeData = jsonDecode(completeResponse.body) as Map<String, dynamic>;
      if (completeData['success'] != true) {
        // If Stripe flow was "canceled" but complete also failed,
        // it's likely a true cancellation - don't throw error, just return empty
        if (stripeFlowCanceled) {
          Log.w('Complete failed after canceled flow - treating as user cancellation', label: _label);
          return [];
        }
        throw Exception(completeData['error']?['message'] ?? 'Failed to complete connection');
      }

      final accountsData = completeData['data']?['accounts'] as List<dynamic>?;
      if (accountsData == null || accountsData.isEmpty) {
        // No accounts returned - if flow was canceled, this is expected
        if (stripeFlowCanceled) {
          Log.w('No accounts after canceled flow - user likely canceled', label: _label);
        }
        return [];
      }

      final accounts = accountsData
          .map((a) => LinkedAccount.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();

      Log.i('Linked ${accounts.length} accounts', label: _label);
      return accounts;
    } catch (e) {
      Log.e('Failed to link bank accounts: $e', label: _label);
      rethrow;
    }
  }

  /// Get all linked bank accounts for current user
  static Future<List<LinkedAccount>> getLinkedAccounts() async {
    try {
      Log.d('getLinkedAccounts() called', label: _label);
      final idToken = await _getIdToken();
      Log.d('Got token, calling GET /accounts', label: _label);

      final response = await http.get(
        Uri.parse('$_baseUrl/accounts'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      Log.d('GET /accounts response: ${response.statusCode} - ${response.body}', label: _label);

      if (response.statusCode == 401) {
        throw Exception('Invalid or expired token');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        final errorMsg = data['error'] is Map
            ? data['error']['message']
            : data['message'] ?? 'Failed to get accounts';
        throw Exception(errorMsg);
      }

      // Handle different response formats
      final dataField = data['data'];
      if (dataField == null) {
        return [];
      }

      // If data is a list directly
      if (dataField is List) {
        return dataField
            .map((a) => LinkedAccount.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      }

      // If data has accounts field
      final accountsData = dataField['accounts'] as List<dynamic>?;
      if (accountsData == null) {
        return [];
      }

      return accountsData
          .map((a) => LinkedAccount.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();
    } catch (e) {
      Log.e('Failed to get linked accounts: $e', label: _label);
      rethrow;
    }
  }

  /// Sync transactions from linked accounts
  static Future<int> syncTransactions({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Log.i('Syncing transactions...', label: _label);

    try {
      final idToken = await _getIdToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/sync'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (accountId != null) 'accountId': accountId,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        }),
      ).timeout(const Duration(minutes: 5));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to sync transactions');
      }

      final count = data['data']?['transactionCount'] as int? ?? 0;
      Log.i('Synced $count transactions', label: _label);
      return count;
    } catch (e) {
      Log.e('Failed to sync transactions: $e', label: _label);
      rethrow;
    }
  }

  /// Disconnect a linked bank account
  static Future<void> disconnectAccount(String accountId) async {
    Log.i('Disconnecting account: $accountId', label: _label);

    try {
      final idToken = await _getIdToken();

      final response = await http.delete(
        Uri.parse('$_baseUrl/accounts/$accountId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['error']?['message'] ?? 'Failed to disconnect account');
      }

      Log.i('Disconnected account: $accountId', label: _label);
    } catch (e) {
      Log.e('Failed to disconnect account: $e', label: _label);
      rethrow;
    }
  }
}
