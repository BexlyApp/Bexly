import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/features/bank_connections/data/models/linked_account_model.dart';
import 'package:bexly/features/bank_connections/domain/services/bank_connection_service.dart';

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
class BankConnectionNotifier extends StateNotifier<BankConnectionState> {
  BankConnectionNotifier() : super(const BankConnectionState());

  /// Load linked accounts
  Future<void> loadAccounts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final accounts = await BankConnectionService.getLinkedAccounts();
      state = state.copyWith(accounts: accounts, isLoading: false);
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
      state = state.copyWith(
        accounts: state.accounts.where((a) => a.id != accountId).toList(),
      );
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
    StateNotifierProvider<BankConnectionNotifier, BankConnectionState>((ref) {
  return BankConnectionNotifier();
});
