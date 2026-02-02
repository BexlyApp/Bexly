import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/daos/pending_transaction_dao.dart';
import 'package:bexly/core/database/daos/parsed_email_transaction_dao.dart';
import 'package:bexly/core/database/app_database.dart';
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

/// Provider for ParsedEmailTransactionDao
final parsedEmailTransactionDaoProvider = Provider<ParsedEmailTransactionDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.parsedEmailTransactionDao;
});

/// Convert ParsedEmailTransaction to PendingTransactionModel
PendingTransactionModel _convertEmailTxToPendingModel(ParsedEmailTransaction email) {
  return PendingTransactionModel(
    id: email.id + 1000000, // Offset to avoid ID collision with pending_transactions
    cloudId: email.cloudId,
    source: PendingTxSource.email,
    sourceId: email.emailId,
    amount: email.amount,
    currency: email.currency,
    transactionType: email.transactionType,
    title: email.merchant ?? email.emailSubject,
    merchant: email.merchant,
    transactionDate: email.transactionDate,
    confidence: email.confidence,
    categoryHint: email.categoryHint,
    sourceDisplayName: email.bankName,
    accountIdentifier: email.accountLast4,
    status: PendingTxStatusExt.fromString(email.status),
    importedTransactionId: email.importedTransactionId,
    targetWalletId: email.targetWalletId,
    selectedCategoryId: email.selectedCategoryId,
    userNotes: email.userNotes,
    rawSourceData: 'email:${email.emailId}',
    createdAt: email.createdAt,
    updatedAt: email.updatedAt,
  );
}

/// Watch all pending transactions (from all sources: pending_transactions + parsed_email_transactions)
final allPendingTransactionsProvider = StreamProvider<List<PendingTransactionModel>>((ref) {
  final pendingDao = ref.watch(pendingTransactionDaoProvider);
  final emailDao = ref.watch(parsedEmailTransactionDaoProvider);

  // Create a combined stream controller
  final controller = StreamController<List<PendingTransactionModel>>();

  List<PendingTransaction> pendingList = [];
  List<ParsedEmailTransaction> emailList = [];

  void emitCombined() {
    final results = <PendingTransactionModel>[];

    // Add from pending_transactions table
    results.addAll(pendingList.map((e) => PendingTransactionModel.fromEntity(e)));

    // Add from parsed_email_transactions table
    results.addAll(emailList.map((e) => _convertEmailTxToPendingModel(e)));

    // Sort by transaction date (newest first)
    results.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    controller.add(results);
  }

  final sub1 = pendingDao.watchAllPending().listen((list) {
    pendingList = list;
    emitCombined();
  });

  final sub2 = emailDao.watchPendingReview().listen((list) {
    emailList = list;
    emitCombined();
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Watch pending transactions count (from all sources)
final pendingTransactionCountProvider = StreamProvider<int>((ref) {
  final pendingDao = ref.watch(pendingTransactionDaoProvider);
  final emailDao = ref.watch(parsedEmailTransactionDaoProvider);

  final controller = StreamController<int>();

  int pendingCount = 0;
  int emailCount = 0;

  void emitCombined() {
    controller.add(pendingCount + emailCount);
  }

  final sub1 = pendingDao.watchPendingCount().listen((count) {
    pendingCount = count;
    emitCombined();
  });

  final sub2 = emailDao.watchPendingCount().listen((count) {
    emailCount = count;
    emitCombined();
  });

  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    controller.close();
  });

  return controller.stream;
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

/// ID offset to distinguish email transactions from pending transactions
const _emailIdOffset = 1000000;

/// Check if ID is from email source (offset applied)
bool _isEmailSourceId(int id) => id >= _emailIdOffset;

/// Get real email transaction ID by removing offset
int _getRealEmailId(int id) => id - _emailIdOffset;

/// Notifier for pending transaction operations
class PendingTransactionNotifier extends Notifier<PendingTransactionState> {
  static const _label = 'PendingTx';

  @override
  PendingTransactionState build() {
    return const PendingTransactionState();
  }

  PendingTransactionDao get _dao => ref.read(pendingTransactionDaoProvider);
  ParsedEmailTransactionDao get _emailDao => ref.read(parsedEmailTransactionDaoProvider);

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

      // Mark pending as imported - handle both sources
      final pendingId = pending.id!;
      if (_isEmailSourceId(pendingId)) {
        // From parsed_email_transactions table
        await _emailDao.markAsImported(_getRealEmailId(pendingId), txId);
        Log.i('Approved email transaction ${_getRealEmailId(pendingId)} -> $txId', label: _label);
      } else {
        // From pending_transactions table
        await _dao.markAsImported(pendingId, txId);
        Log.i('Approved pending transaction $pendingId -> $txId', label: _label);
      }

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

      if (_isEmailSourceId(id)) {
        // From parsed_email_transactions table
        await _emailDao.reject(_getRealEmailId(id));
        Log.i('Rejected email transaction ${_getRealEmailId(id)}', label: _label);
      } else {
        // From pending_transactions table
        await _dao.reject(id);
        Log.i('Rejected pending transaction $id', label: _label);
      }

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
    if (_isEmailSourceId(id)) {
      await _emailDao.updateTargetWallet(_getRealEmailId(id), walletId);
    } else {
      await _dao.updateTargetWallet(id, walletId);
    }
  }

  /// Update selected category for a pending transaction
  Future<void> updateSelectedCategory(int id, int categoryId) async {
    if (_isEmailSourceId(id)) {
      await _emailDao.updateSelectedCategory(_getRealEmailId(id), categoryId);
    } else {
      await _dao.updateSelectedCategory(id, categoryId);
    }
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
