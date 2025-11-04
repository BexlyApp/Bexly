import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/transaction_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart'; // Import WalletTable
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_filter_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/core/services/sync/realtime_sync_provider.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(
  tables: [Transactions, Categories, Wallets], // Add Wallets table
)
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  final Ref? _ref;

  TransactionDao(super.db, [this._ref]);

  /// Helper to convert a database row (Transaction, Category, Wallet) to a TransactionModel.
  Future<TransactionModel> _mapToTransactionModel(
    Transaction transactionData,
    Category categoryData,
    Wallet walletData,
  ) async {
    return TransactionModel(
      id: transactionData.id,
      cloudId: transactionData.cloudId,
      // Use the actual enum value from the database integer
      // This is safer than relying on index directly if enum order changes
      transactionType: TransactionType.values.firstWhere(
        (e) => e.index == transactionData.transactionType,
      ),
      amount: transactionData.amount,
      date: transactionData.date,
      title: transactionData.title,
      category: categoryData.toModel(), // Using CategoryTableExtensions
      wallet: walletData.toModel(), // Replace with actual fetched WalletModel
      notes: transactionData.notes,
      imagePath: transactionData.imagePath,
      isRecurring: transactionData.isRecurring,
      createdAt: transactionData.createdAt,
      updatedAt: transactionData.updatedAt,
    );
  }

  /// Streams all transactions; logs each emission
  Future<List<Transaction>> getAllTransactions() {
    Log.d('Subscribing to getAllTransactions()', label: 'transaction');
    return select(transactions).get();
  }

  /// Streams all transactions; logs each emission
  Stream<List<Transaction>> watchAllTransactions() {
    Log.d('Subscribing to watchAllTransactions()', label: 'transaction');
    return select(transactions).watch().map((list) {
      Log.d(
        'watchAllTransactions emitted ${list.length} rows',
        label: 'transaction',
      );
      return list;
    });
  }

  /// Streams single transaction;
  Stream<Transaction> watchTransactionByID(int id) {
    Log.d('Subscribing to watchTransactionByID($id)', label: 'transaction');
    return (select(transactions)..where((g) => g.id.equals(id))).watchSingle();
  }

  /// Get transaction by cloud ID (for sync operations)
  Future<Transaction?> getTransactionByCloudId(String cloudId) {
    return (select(transactions)..where((t) => t.cloudId.equals(cloudId)))
        .getSingleOrNull();
  }

  /// Watches all transactions with their associated category and wallet details.
  Stream<List<TransactionModel>> watchAllTransactionsWithDetails() {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      innerJoin(
        db.wallets,
        db.wallets.id.equalsExp(transactions.walletId),
      ), // Use db.wallets
    ]);

    return query.watch().asyncMap((rows) async {
      final result = <TransactionModel>[];
      for (final row in rows) {
        final transactionData = row.readTable(transactions);
        final categoryData = row.readTable(categories);
        final walletData = row.readTable(db.wallets); // Use db.wallets
        result.add(
          await _mapToTransactionModel(
            transactionData,
            categoryData,
            walletData,
          ),
        );
      }
      return result;
    });
  }

  /// Watches all transactions for a specific wallet with their associated category and wallet details.
  Stream<List<TransactionModel>> watchTransactionsByWalletIdWithDetails(
    int walletId,
  ) {
    Log.d(
      'ubscribing to watchTransactionsByWalletIdWithDetails($walletId)',
      label: 'transaction',
    );
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      innerJoin(db.wallets, db.wallets.id.equalsExp(transactions.walletId)),
    ])..where(transactions.walletId.equals(walletId)); // Filter by walletId

    return query.watch().asyncMap((rows) async {
      final result = <TransactionModel>[];
      for (final row in rows) {
        final transactionData = row.readTable(transactions);
        final categoryData = row.readTable(categories);
        final walletData = row.readTable(db.wallets);
        result.add(
          await _mapToTransactionModel(
            transactionData,
            categoryData,
            walletData,
          ),
        );
      }
      return result;
    });
  }

  // Get transactions for a specific budget period, category, and wallet
  Future<List<TransactionModel>> getTransactionsForBudget({
    required List<int> categoryIds,
    required DateTime startDate,
    required DateTime endDate,
    required int walletId,
  }) async {
    // We need to join with Categories and Wallets to get the full TransactionModel
    final query =
        select(transactions).join([
            innerJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
            innerJoin(
              db.wallets,
              db.wallets.id.equalsExp(transactions.walletId),
            ),
          ])
          ..where(transactions.categoryId.isIn(categoryIds))
          ..where(transactions.date.isBetweenValues(startDate, endDate))
          ..where(transactions.walletId.equals(walletId))
          ..where(
            transactions.transactionType.equals(TransactionType.expense.index),
          ); // Only expenses

    final rows = await query.get();
    final result = <TransactionModel>[];
    for (final row in rows) {
      final transactionData = row.readTable(transactions);
      final categoryData = row.readTable(categories);
      final walletData = row.readTable(db.wallets);
      result.add(
        await _mapToTransactionModel(transactionData, categoryData, walletData),
      );
    }

    Log.d(result, label: 'transactions by budget');

    return result;
  }

  /// Inserts a new transaction.
  Future<int> addTransaction(TransactionModel transactionModel) async {
    Log.d(
      'Saving New Transaction: ${transactionModel.toJson()}',
      label: 'transaction',
    );

    // 1. Save to local database
    final companion = TransactionsCompanion(
      transactionType: Value(transactionModel.transactionType.toDbValue()),
      amount: Value(transactionModel.amount),
      date: Value(transactionModel.date),
      title: Value(transactionModel.title.trim()),
      categoryId: Value(transactionModel.category.id!),
      walletId: Value(
        transactionModel.wallet.id!,
      ), // Assuming wallet.id will not be null here
      notes: Value(transactionModel.notes?.trim()),
      imagePath: Value(transactionModel.imagePath),
      isRecurring: Value(transactionModel.isRecurring),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    final id = await into(transactions).insert(companion);

    // 2. Upload to cloud (if sync available)
    print('🔄 [UPLOAD_DEBUG] Checking if can upload to cloud: _ref != null = ${_ref != null}');
    if (_ref != null) {
      try {
        print('🔄 [UPLOAD_DEBUG] Reading realtimeSyncServiceProvider...');
        final syncService = _ref.read(realtimeSyncServiceProvider);
        print('🔄 [UPLOAD_DEBUG] Getting saved transaction with id=$id...');
        final savedTransaction = await (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (savedTransaction != null) {
          print('🔄 [UPLOAD_DEBUG] Fetching category and wallet...');
          // Fetch category and wallet for complete model
          final category = await (select(categories)..where((c) => c.id.equals(savedTransaction.categoryId))).getSingleOrNull();
          final wallet = await (select(db.wallets)..where((w) => w.id.equals(savedTransaction.walletId))).getSingleOrNull();
          print('🔄 [UPLOAD_DEBUG] Category: ${category?.title}, Wallet: ${wallet?.name}');
          if (category != null && wallet != null) {
            final model = await _mapToTransactionModel(savedTransaction, category, wallet);
            print('🚀 [UPLOAD_DEBUG] UPLOADING transaction to cloud: ${model.title} - ${model.amount}');
            await syncService.uploadTransaction(model);
            print('✅ [UPLOAD_DEBUG] Transaction uploaded successfully!');
          } else {
            print('❌ [UPLOAD_DEBUG] Cannot upload: category=$category, wallet=$wallet');
          }
        } else {
          print('❌ [UPLOAD_DEBUG] Cannot upload: savedTransaction is null');
        }
      } catch (e, stack) {
        print('❌ [UPLOAD_DEBUG] Failed to upload transaction to cloud: $e');
        print('❌ [UPLOAD_DEBUG] Stack: $stack');
        Log.e('Failed to upload transaction to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local save succeeded
      }
    } else {
      print('❌ [UPLOAD_DEBUG] Cannot upload: _ref is null');
    }

    return id;
  }

  /// Updates an existing transaction.
  Future<bool> updateTransaction(TransactionModel transactionModel) async {
    Log.d(
      'Updating Transaction: ${transactionModel.toJson()}',
      label: 'transaction',
    );

    // 1. Update local database
    final companion = TransactionsCompanion(
      // For `update(table).replace(companion)`, the companion must include the primary key.
      // transactionModel.id is expected to be non-null for an update operation.
      // The TransactionFormState includes a check to ensure transactionToSave.id is not null before calling update.
      id: Value(transactionModel.id!),
      transactionType: Value(transactionModel.transactionType.toDbValue()),
      amount: Value(transactionModel.amount),
      date: Value(transactionModel.date),
      title: Value(transactionModel.title.trim()),
      categoryId: Value(transactionModel.category.id!),
      walletId: Value(
        transactionModel.wallet.id!,
      ), // Assuming wallet.id will not be null here
      notes: Value(transactionModel.notes?.trim()),
      imagePath: Value(transactionModel.imagePath),
      isRecurring: Value(transactionModel.isRecurring),
      updatedAt: Value(DateTime.now()),
    );
    final success = await update(transactions).replace(companion);

    // 2. Upload to cloud (if sync available)
    if (success && _ref != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.uploadTransaction(transactionModel);
      } catch (e, stack) {
        Log.e('Failed to upload transaction update to cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local update succeeded
      }
    }

    return success;
  }

  /// Deletes a transaction by its ID.
  Future<int> deleteTransaction(int id) async {
    Log.d('Deleting transaction with ID: $id', label: 'transaction');

    // 1. Get transaction to retrieve cloudId
    final transaction = await (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

    // 2. Delete from local database
    final count = await (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();

    // 3. Delete from cloud (if sync available and has cloudId)
    if (count > 0 && _ref != null && transaction != null && transaction.cloudId != null) {
      try {
        final syncService = _ref.read(realtimeSyncServiceProvider);
        await syncService.deleteTransactionFromCloud(transaction.cloudId!);
      } catch (e, stack) {
        Log.e('Failed to delete transaction from cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local delete succeeded
      }
    }

    return count;
  }

  /// Upserts a transaction: inserts if new, updates if exists by ID.
  Future<void> upsertTransaction(TransactionModel transactionModel) {
    final companion = TransactionsCompanion(
      id: Value(transactionModel.id ?? 0),
      transactionType: Value(transactionModel.transactionType.toDbValue()),
      amount: Value(transactionModel.amount),
      date: Value(transactionModel.date),
      title: Value(transactionModel.title.trim()),
      categoryId: Value(transactionModel.category.id!),
      walletId: Value(
        transactionModel.wallet.id!,
      ), // Assuming wallet.id will not be null here
      notes: Value(transactionModel.notes?.trim()),
      imagePath: Value(transactionModel.imagePath),
      isRecurring: Value(transactionModel.isRecurring),
      // Let createdAt be handled by DB default on insert, updatedAt always changes
      updatedAt: Value(DateTime.now()),
    );
    return into(transactions).insertOnConflictUpdate(companion);
  }

  /// Watches filtered transactions for a specific wallet with their associated category and wallet details.
  Stream<List<TransactionModel>> watchFilteredTransactionsWithDetails({
    required int walletId,
    TransactionFilter? filter,
  }) {
    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      innerJoin(db.wallets, db.wallets.id.equalsExp(transactions.walletId)),
    ])..where(transactions.walletId.equals(walletId));

    if (filter != null) {
      if (filter.transactionType != null) {
        query.where(
          transactions.transactionType.equals(filter.transactionType!.index),
        );
      }
      if (filter.category != null) {
        // Collect parent and all subcategory IDs for filtering
        final parentId = filter.category!.id!;
        final subIds =
            filter.category!.subCategories?.map((e) => e.id!).toList() ?? [];
        final allCategoryIds = [parentId, ...subIds];
        query.where(transactions.categoryId.isIn(allCategoryIds));
      }
      if (filter.minAmount != null) {
        query.where(
          transactions.amount.isBiggerOrEqualValue(filter.minAmount!),
        );
      }
      if (filter.maxAmount != null) {
        query.where(
          transactions.amount.isSmallerOrEqualValue(filter.maxAmount!),
        );
      }
      if (filter.keyword != null && filter.keyword!.isNotEmpty) {
        query.where(transactions.title.like('%${filter.keyword!}%'));
        query.where(transactions.notes.like('%${filter.keyword!}%'));
      }
      if (filter.dateStart != null && filter.dateEnd != null) {
        query.where(
          transactions.date.isBetweenValues(filter.dateStart!, filter.dateEnd!),
        );
      }
    }

    return query.watch().asyncMap((rows) async {
      final result = <TransactionModel>[];
      for (final row in rows) {
        final transactionData = row.readTable(transactions);
        final categoryData = row.readTable(categories);
        final walletData = row.readTable(db.wallets);
        result.add(
          await _mapToTransactionModel(
            transactionData,
            categoryData,
            walletData,
          ),
        );
      }
      return result;
    });
  }
}
