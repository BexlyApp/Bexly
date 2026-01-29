import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/parsed_email_transaction_table.dart';
import 'package:bexly/core/utils/logger.dart';

part 'parsed_email_transaction_dao.g.dart';

/// Status values for parsed email transactions
class ParsedEmailTransactionStatus {
  static const pendingReview = 'pending_review';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const imported = 'imported';
}

@DriftAccessor(tables: [ParsedEmailTransactions])
class ParsedEmailTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$ParsedEmailTransactionDaoMixin {
  ParsedEmailTransactionDao(super.db);

  static const _label = 'ParsedEmailTxDao';

  /// Get all pending review transactions
  Future<List<ParsedEmailTransaction>> getPendingReview() async {
    return (select(parsedEmailTransactions)
          ..where((t) => t.status.equals(ParsedEmailTransactionStatus.pendingReview))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  /// Get all transactions by status
  Future<List<ParsedEmailTransaction>> getByStatus(String status) async {
    return (select(parsedEmailTransactions)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  /// Get transaction by email ID (for deduplication)
  Future<ParsedEmailTransaction?> getByEmailId(String emailId) async {
    return (select(parsedEmailTransactions)
          ..where((t) => t.emailId.equals(emailId)))
        .getSingleOrNull();
  }

  /// Check if email was already processed
  Future<bool> isEmailProcessed(String emailId) async {
    final existing = await getByEmailId(emailId);
    return existing != null;
  }

  /// Insert a new parsed transaction
  Future<int> insertParsedTransaction(ParsedEmailTransactionsCompanion data) async {
    try {
      final id = await into(parsedEmailTransactions).insert(data);
      Log.d('Inserted parsed email transaction: $id', label: _label);
      return id;
    } catch (e) {
      Log.e('Error inserting parsed transaction: $e', label: _label);
      rethrow;
    }
  }

  /// Insert multiple parsed transactions (batch)
  Future<void> insertBatch(List<ParsedEmailTransactionsCompanion> dataList) async {
    await batch((b) {
      b.insertAll(parsedEmailTransactions, dataList, mode: InsertMode.insertOrIgnore);
    });
    Log.d('Batch inserted ${dataList.length} parsed transactions', label: _label);
  }

  /// Update transaction status
  Future<void> updateStatus(int id, String status) async {
    await (update(parsedEmailTransactions)..where((t) => t.id.equals(id))).write(
      ParsedEmailTransactionsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
    Log.d('Updated transaction $id status to: $status', label: _label);
  }

  /// Approve a transaction for import
  Future<void> approve(int id, {int? targetWalletId, int? selectedCategoryId}) async {
    await (update(parsedEmailTransactions)..where((t) => t.id.equals(id))).write(
      ParsedEmailTransactionsCompanion(
        status: Value(ParsedEmailTransactionStatus.approved),
        targetWalletId: targetWalletId != null ? Value(targetWalletId) : const Value.absent(),
        selectedCategoryId: selectedCategoryId != null ? Value(selectedCategoryId) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    Log.d('Approved transaction $id', label: _label);
  }

  /// Reject a transaction
  Future<void> reject(int id) async {
    await updateStatus(id, ParsedEmailTransactionStatus.rejected);
  }

  /// Mark transaction as imported
  Future<void> markAsImported(int id, int importedTransactionId) async {
    await (update(parsedEmailTransactions)..where((t) => t.id.equals(id))).write(
      ParsedEmailTransactionsCompanion(
        status: Value(ParsedEmailTransactionStatus.imported),
        importedTransactionId: Value(importedTransactionId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    Log.d('Marked transaction $id as imported (tx: $importedTransactionId)', label: _label);
  }

  /// Update target wallet
  Future<void> updateTargetWallet(int id, int walletId) async {
    await (update(parsedEmailTransactions)..where((t) => t.id.equals(id))).write(
      ParsedEmailTransactionsCompanion(
        targetWalletId: Value(walletId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update selected category
  Future<void> updateSelectedCategory(int id, int categoryId) async {
    await (update(parsedEmailTransactions)..where((t) => t.id.equals(id))).write(
      ParsedEmailTransactionsCompanion(
        selectedCategoryId: Value(categoryId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update user notes
  Future<void> updateNotes(int id, String? notes) async {
    await (update(parsedEmailTransactions)..where((t) => t.id.equals(id))).write(
      ParsedEmailTransactionsCompanion(
        userNotes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update parsed transaction with user edits
  Future<void> updateParsedTransaction({
    required int id,
    double? amount,
    String? merchant,
    String? transactionType,
    String? categoryHint,
    DateTime? transactionDate,
    int? selectedCategoryId,
  }) async {
    await (update(parsedEmailTransactions)..where((t) => t.id.equals(id))).write(
      ParsedEmailTransactionsCompanion(
        amount: amount != null ? Value(amount) : const Value.absent(),
        merchant: merchant != null ? Value(merchant) : const Value.absent(),
        transactionType: transactionType != null ? Value(transactionType) : const Value.absent(),
        categoryHint: categoryHint != null ? Value(categoryHint) : const Value.absent(),
        transactionDate: transactionDate != null ? Value(transactionDate) : const Value.absent(),
        selectedCategoryId: selectedCategoryId != null ? Value(selectedCategoryId) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
    Log.d('Updated parsed transaction $id', label: _label);
  }

  /// Delete a transaction
  Future<void> deleteParsedTransaction(int id) async {
    await (delete(parsedEmailTransactions)..where((t) => t.id.equals(id))).go();
    Log.d('Deleted parsed transaction $id', label: _label);
  }

  /// Delete all rejected transactions
  Future<int> deleteRejected() async {
    final count = await (delete(parsedEmailTransactions)
          ..where((t) => t.status.equals(ParsedEmailTransactionStatus.rejected)))
        .go();
    Log.d('Deleted $count rejected transactions', label: _label);
    return count;
  }

  /// Get count by status
  Future<int> getCountByStatus(String status) async {
    final query = selectOnly(parsedEmailTransactions)
      ..addColumns([parsedEmailTransactions.id.count()])
      ..where(parsedEmailTransactions.status.equals(status));
    final result = await query.getSingle();
    return result.read(parsedEmailTransactions.id.count()) ?? 0;
  }

  /// Get pending review count
  Future<int> getPendingCount() async {
    return getCountByStatus(ParsedEmailTransactionStatus.pendingReview);
  }

  /// Watch pending transactions stream
  Stream<List<ParsedEmailTransaction>> watchPendingReview() {
    return (select(parsedEmailTransactions)
          ..where((t) => t.status.equals(ParsedEmailTransactionStatus.pendingReview))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  /// Watch pending count stream
  Stream<int> watchPendingCount() {
    final query = selectOnly(parsedEmailTransactions)
      ..addColumns([parsedEmailTransactions.id.count()])
      ..where(parsedEmailTransactions.status.equals(ParsedEmailTransactionStatus.pendingReview));
    return query.watchSingle().map((row) => row.read(parsedEmailTransactions.id.count()) ?? 0);
  }
}
