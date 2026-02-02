import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/daos/pending_transaction_dao.dart';
import 'package:bexly/core/database/tables/wallet_table.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';

/// Provider for PendingTransactionDao
final pendingTransactionDaoProvider = Provider<PendingTransactionDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.pendingTransactionDao;
});

/// Watch all pending transactions (from all sources)
final allPendingTransactionsProvider = StreamProvider<List<PendingTransactionModel>>((ref) {
  final dao = ref.watch(pendingTransactionDaoProvider);
  return dao.watchAllPending().map((entities) =>
      entities.map((e) => PendingTransactionModel.fromEntity(e)).toList());
});

/// Watch pending transactions count
final pendingTransactionCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(pendingTransactionDaoProvider);
  return dao.watchPendingCount();
});

/// Watch pending transactions by source
final pendingBySourceProvider = StreamProvider.family<List<PendingTransactionModel>, PendingTxSource>((ref, source) {
  final dao = ref.watch(pendingTransactionDaoProvider);
  return dao.watchPendingBySource(source.value).map((entities) =>
      entities.map((e) => PendingTransactionModel.fromEntity(e)).toList());
});

/// State for pending transaction operations
class PendingTransactionState {
  final bool isLoading;
  final bool isApproving;
  final bool isRejecting;
  final String? error;

  const PendingTransactionState({
    this.isLoading = false,
    this.isApproving = false,
    this.isRejecting = false,
    this.error,
  });

  PendingTransactionState copyWith({
    bool? isLoading,
    bool? isApproving,
    bool? isRejecting,
    String? error,
  }) {
    return PendingTransactionState(
      isLoading: isLoading ?? this.isLoading,
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
      error: error,
    );
  }
}

/// Notifier for pending transaction operations
class PendingTransactionNotifier extends Notifier<PendingTransactionState> {
  static const _label = 'PendingTx';

  @override
  PendingTransactionState build() {
    return const PendingTransactionState();
  }

  PendingTransactionDao get _dao => ref.read(pendingTransactionDaoProvider);

  /// Approve a pending transaction and import it
  Future<bool> approveAndImport(
    PendingTransactionModel pending, {
    required int walletId,
    required int categoryId,
  }) async {
    try {
      state = state.copyWith(isApproving: true, error: null);

      final db = ref.read(databaseProvider);
      final transactionDao = db.transactionDao;

      // Get wallet and category entities then convert to models
      final walletEntity = await db.walletDao.getWalletById(walletId);
      if (walletEntity == null) {
        throw Exception('Wallet not found: $walletId');
      }
      final walletModel = walletEntity.toModel();

      final categoryEntity = await db.categoryDao.getCategoryById(categoryId);
      if (categoryEntity == null) {
        throw Exception('Category not found: $categoryId');
      }
      final categoryModel = categoryEntity.toModel();

      // Create TransactionModel
      final transactionModel = TransactionModel(
        transactionType: pending.isIncome ? TransactionType.income : TransactionType.expense,
        amount: pending.amount,
        date: pending.transactionDate,
        title: pending.title,
        category: categoryModel,
        wallet: walletModel,
        notes: pending.userNotes ?? 'Imported from ${pending.source.displayName}',
      );

      // Add the transaction
      final txId = await transactionDao.addTransaction(transactionModel);

      // Mark pending as imported
      await _dao.markAsImported(pending.id!, txId);

      Log.i('Approved and imported pending transaction ${pending.id} -> $txId', label: _label);
      state = state.copyWith(isApproving: false);
      return true;
    } catch (e) {
      Log.e('Failed to approve pending transaction: $e', label: _label);
      state = state.copyWith(isApproving: false, error: e.toString());
      return false;
    }
  }

  /// Reject a pending transaction
  Future<bool> reject(int id) async {
    try {
      state = state.copyWith(isRejecting: true, error: null);
      await _dao.reject(id);
      Log.i('Rejected pending transaction $id', label: _label);
      state = state.copyWith(isRejecting: false);
      return true;
    } catch (e) {
      Log.e('Failed to reject pending transaction: $e', label: _label);
      state = state.copyWith(isRejecting: false, error: e.toString());
      return false;
    }
  }

  /// Update target wallet for a pending transaction
  Future<void> updateTargetWallet(int id, int walletId) async {
    await _dao.updateTargetWallet(id, walletId);
  }

  /// Update selected category for a pending transaction
  Future<void> updateSelectedCategory(int id, int categoryId) async {
    await _dao.updateSelectedCategory(id, categoryId);
  }

  /// Delete all rejected transactions
  Future<int> clearRejected() async {
    return await _dao.deleteRejected();
  }

  /// Delete all imported transactions
  Future<int> clearImported() async {
    return await _dao.deleteImported();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for pending transaction operations
final pendingTransactionNotifierProvider =
    NotifierProvider<PendingTransactionNotifier, PendingTransactionState>(() {
  return PendingTransactionNotifier();
});
