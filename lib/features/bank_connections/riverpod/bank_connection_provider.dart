import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/features/bank_connections/data/models/linked_account_model.dart';
import 'package:bexly/features/bank_connections/domain/services/bank_connection_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// Cache keys for SharedPreferences
class _CacheKeys {
  static const linkedAccounts = 'bank_connections_linked_accounts';
  static const lastFetchTime = 'bank_connections_last_fetch';
}

/// State for bank connections
class BankConnectionState {
  final List<LinkedAccount> accounts;
  final bool isLoading;
  final bool isLinking;
  final bool isSyncing;
  final String? error;

  const BankConnectionState({
    this.accounts = const [],
    this.isLoading = false,
    this.isLinking = false,
    this.isSyncing = false,
    this.error,
  });

  BankConnectionState copyWith({
    List<LinkedAccount>? accounts,
    bool? isLoading,
    bool? isLinking,
    bool? isSyncing,
    String? error,
  }) {
    return BankConnectionState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      isLinking: isLinking ?? this.isLinking,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
    );
  }
}

/// Provider for managing bank connections
class BankConnectionNotifier extends Notifier<BankConnectionState> {
  static const _label = 'BankConnection';

  @override
  BankConnectionState build() {
    // Load cached data immediately on build
    _loadCachedAccounts();
    return const BankConnectionState();
  }

  /// Load cached accounts from SharedPreferences (synchronously on startup)
  Future<void> _loadCachedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_CacheKeys.linkedAccounts);

      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        final accounts = decoded
            .map((json) => LinkedAccount.fromJson(json as Map<String, dynamic>))
            .toList();

        if (accounts.isNotEmpty) {
          Log.d('Loaded ${accounts.length} accounts from cache', label: _label);
          state = state.copyWith(accounts: accounts);
        }
      }
    } catch (e) {
      Log.w('Failed to load cached accounts: $e', label: _label);
    }
  }

  /// Save accounts to cache
  Future<void> _cacheAccounts(List<LinkedAccount> accounts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await prefs.setString(_CacheKeys.linkedAccounts, json);
      await prefs.setInt(
        _CacheKeys.lastFetchTime,
        DateTime.now().millisecondsSinceEpoch,
      );
      Log.d('Cached ${accounts.length} accounts', label: _label);
    } catch (e) {
      Log.w('Failed to cache accounts: $e', label: _label);
    }
  }

  /// Clear cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_CacheKeys.linkedAccounts);
      await prefs.remove(_CacheKeys.lastFetchTime);
    } catch (e) {
      Log.w('Failed to clear cache: $e', label: _label);
    }
  }

  /// Load linked accounts (fetch from API and update cache)
  Future<void> loadAccounts() async {
    // Don't show loading if we have cached data
    if (state.accounts.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final accounts = await BankConnectionService.getLinkedAccounts();
      state = state.copyWith(accounts: accounts, isLoading: false);

      // Cache the fresh data
      await _cacheAccounts(accounts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Link new bank accounts
  Future<bool> linkAccounts() async {
    state = state.copyWith(isLinking: true, error: null);

    try {
      final newAccounts = await BankConnectionService.linkBankAccounts();
      if (newAccounts.isEmpty) {
        // User cancelled
        state = state.copyWith(isLinking: false);
        return false;
      }

      // Merge with existing accounts
      final allAccounts = [...state.accounts];
      for (final account in newAccounts) {
        if (!allAccounts.any((a) => a.id == account.id)) {
          allAccounts.add(account);
        }
      }

      state = state.copyWith(accounts: allAccounts, isLinking: false);

      // Update cache
      await _cacheAccounts(allAccounts);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLinking: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Sync transactions from all linked accounts
  Future<int> syncTransactions({String? accountId}) async {
    state = state.copyWith(isSyncing: true, error: null);

    try {
      final count = await BankConnectionService.syncTransactions(
        accountId: accountId,
      );
      state = state.copyWith(isSyncing: false);
      return count;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
      return 0;
    }
  }

  /// Disconnect a bank account
  Future<bool> disconnectAccount(String accountId) async {
    try {
      await BankConnectionService.disconnectAccount(accountId);
      final updatedAccounts =
          state.accounts.where((a) => a.id != accountId).toList();
      state = state.copyWith(accounts: updatedAccounts);

      // Update cache
      await _cacheAccounts(updatedAccounts);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for bank connection state
final bankConnectionProvider =
    NotifierProvider<BankConnectionNotifier, BankConnectionState>(() {
  return BankConnectionNotifier();
});
