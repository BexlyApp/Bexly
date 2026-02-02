import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/pending_transaction_table.dart';
import 'package:bexly/core/utils/logger.dart';

part 'pending_transaction_dao.g.dart';

/// Status constants for pending transactions
class PendingStatus {
  static const pendingReview = 'pending_review';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const imported = 'imported';
}

/// Source constants for pending transactions
class PendingSource {
  static const email = 'email';
  static const bank = 'bank';
  static const sms = 'sms';
  static const notification = 'notification';
}

@DriftAccessor(tables: [PendingTransactions])
class PendingTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$PendingTransactionDaoMixin {
  PendingTransactionDao(super.db);

  static const _label = 'PendingTxDao';

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get all pending review transactions from all sources
  Future<List<PendingTransaction>> getAllPendingReview() async {
    return (select(pendingTransactions)
          ..where((t) => t.status.equals(PendingStatus.pendingReview))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  /// Get pending review transactions by source
  Future<List<PendingTransaction>> getPendingBySource(String source) async {
    return (select(pendingTransactions)
          ..where((t) =>
              t.status.equals(PendingStatus.pendingReview) &
              t.source.equals(source))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  /// Get transaction by source and sourceId (for deduplication)
  Future<PendingTransaction?> getBySourceId(String source, String sourceId) async {
    return (select(pendingTransactions)
          ..where((t) => t.source.equals(source) & t.sourceId.equals(sourceId)))
        .getSingleOrNull();
  }

  /// Check if a transaction from this source was already processed
  Future<bool> isAlreadyProcessed(String source, String sourceId) async {
    final existing = await getBySourceId(source, sourceId);
    return existing != null;
  }

  /// Get all transactions by status
  Future<List<PendingTransaction>> getByStatus(String status) async {
    return (select(pendingTransactions)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  // ============================================================================
  // Insert Methods
  // ============================================================================

  /// Insert a new pending transaction
  Future<int> insertPending(PendingTransactionsCompanion data) async {
    try {
      final id = await into(pendingTransactions).insert(data);
      Log.d('Inserted pending transaction: $id', label: _label);
      return id;
    } catch (e) {
      Log.e('Error inserting pending transaction: $e', label: _label);
      rethrow;
    }
  }

  /// Insert or ignore if already exists (for deduplication)
  Future<int> insertOrIgnore(PendingTransactionsCompanion data) async {
    try {
      final id = await into(pendingTransactions).insert(
        data,
        mode: InsertMode.insertOrIgnore,
      );
      if (id > 0) {
        Log.d('Inserted pending transaction: $id', label: _label);
      }
      return id;
    } catch (e) {
      Log.e('Error inserting pending transaction: $e', label: _label);
      rethrow;
    }
  }

  /// Batch insert pending transactions
  Future<void> insertBatch(List<PendingTransactionsCompanion> dataList) async {
    await batch((b) {
      b.insertAll(pendingTransactions, dataList, mode: InsertMode.insertOrIgnore);
    });
    Log.d('Batch inserted ${dataList.length} pending transactions', label: _label);
  }

  // ============================================================================
  // Update Methods
  // ============================================================================

  /// Update transaction status
  Future<void> updateStatus(int id, String status) async {
    await (update(pendingTransactions)..where((t) => t.id.equals(id))).write(
      PendingTransactionsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
    Log.d('Updated pending transaction $id status to: $status', label: _label);
  }

  /// Approve a transaction for import
  Future<void> approve(int id, {int? targetWalletId, int? selectedCategoryId}) async {
    await (update(pendingTransactions)..where((t) => t.id.equals(id))).write(
      PendingTransactionsCompanion(
        status: Value(PendingStatus.approved),
        targetWalletId: targetWalletId != null ? Value(targetWalletId) : const Value.absent(),
        selectedCategoryId: selectedCategoryId != null ? Value(selectedCategoryId) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    Log.d('Approved pending transaction $id', label: _label);
  }

  /// Reject a transaction
  Future<void> reject(int id) async {
    await updateStatus(id, PendingStatus.rejected);
  }

  /// Mark transaction as imported
  Future<void> markAsImported(int id, int importedTransactionId) async {
    await (update(pendingTransactions)..where((t) => t.id.equals(id))).write(
      PendingTransactionsCompanion(
        status: Value(PendingStatus.imported),
        importedTransactionId: Value(importedTransactionId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    Log.d('Marked pending transaction $id as imported (tx: $importedTransactionId)', label: _label);
  }

  /// Update target wallet
  Future<void> updateTargetWallet(int id, int walletId) async {
    await (update(pendingTransactions)..where((t) => t.id.equals(id))).write(
      PendingTransactionsCompanion(
        targetWalletId: Value(walletId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update selected category
  Future<void> updateSelectedCategory(int id, int categoryId) async {
    await (update(pendingTransactions)..where((t) => t.id.equals(id))).write(
      PendingTransactionsCompanion(
        selectedCategoryId: Value(categoryId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update user notes
  Future<void> updateNotes(int id, String? notes) async {
    await (update(pendingTransactions)..where((t) => t.id.equals(id))).write(
      PendingTransactionsCompanion(
        userNotes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ============================================================================
  // Delete Methods
  // ============================================================================

  /// Delete a pending transaction
  Future<void> deletePending(int id) async {
    await (delete(pendingTransactions)..where((t) => t.id.equals(id))).go();
    Log.d('Deleted pending transaction $id', label: _label);
  }

  /// Delete all rejected transactions
  Future<int> deleteRejected() async {
    final count = await (delete(pendingTransactions)
          ..where((t) => t.status.equals(PendingStatus.rejected)))
        .go();
    Log.d('Deleted $count rejected transactions', label: _label);
    return count;
  }

  /// Delete all imported transactions
  Future<int> deleteImported() async {
    final count = await (delete(pendingTransactions)
          ..where((t) => t.status.equals(PendingStatus.imported)))
        .go();
    Log.d('Deleted $count imported transactions', label: _label);
    return count;
  }

  // ============================================================================
  // Count Methods
  // ============================================================================

  /// Get count by status
  Future<int> getCountByStatus(String status) async {
    final query = selectOnly(pendingTransactions)
      ..addColumns([pendingTransactions.id.count()])
      ..where(pendingTransactions.status.equals(status));
    final result = await query.getSingle();
    return result.read(pendingTransactions.id.count()) ?? 0;
  }

  /// Get pending review count (all sources)
  Future<int> getPendingCount() async {
    return getCountByStatus(PendingStatus.pendingReview);
  }

  /// Get pending count by source
  Future<int> getPendingCountBySource(String source) async {
    final query = selectOnly(pendingTransactions)
      ..addColumns([pendingTransactions.id.count()])
      ..where(pendingTransactions.status.equals(PendingStatus.pendingReview) &
          pendingTransactions.source.equals(source));
    final result = await query.getSingle();
    return result.read(pendingTransactions.id.count()) ?? 0;
  }

  // ============================================================================
  // Stream/Watch Methods
  // ============================================================================

  /// Watch all pending transactions stream
  Stream<List<PendingTransaction>> watchAllPending() {
    return (select(pendingTransactions)
          ..where((t) => t.status.equals(PendingStatus.pendingReview))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  /// Watch pending count stream
  Stream<int> watchPendingCount() {
    final query = selectOnly(pendingTransactions)
      ..addColumns([pendingTransactions.id.count()])
      ..where(pendingTransactions.status.equals(PendingStatus.pendingReview));
    return query.watchSingle().map((row) => row.read(pendingTransactions.id.count()) ?? 0);
  }

  /// Watch pending transactions by source
  Stream<List<PendingTransaction>> watchPendingBySource(String source) {
    return (select(pendingTransactions)
          ..where((t) =>
              t.status.equals(PendingStatus.pendingReview) &
              t.source.equals(source))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }
}
