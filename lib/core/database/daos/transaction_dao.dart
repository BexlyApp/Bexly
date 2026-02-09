import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/tables/category_table.dart';
import 'package:bexly/core/database/tables/transaction_table.dart';
import 'package:bexly/core/database/tables/wallet_table.dart'; // Import WalletTable
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/utils/retry_helper.dart';
import 'package:bexly/features/transaction/data/model/transaction_filter_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/core/services/sync/supabase_sync_provider.dart';

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
    // Safely convert transaction type with fallback to expense
    final typeIndex = transactionData.transactionType;
    final transactionType = (typeIndex >= 0 && typeIndex < TransactionType.values.length)
        ? TransactionType.values[typeIndex]
        : TransactionType.expense;

    return TransactionModel(
      id: transactionData.id,
      cloudId: transactionData.cloudId,
      transactionType: transactionType,
      amount: transactionData.amount,
      date: transactionData.date,
      title: transactionData.title,
      category: categoryData.toModel(),
      wallet: walletData.toModel(),
      notes: transactionData.notes,
      imagePath: transactionData.imagePath,
      isRecurring: transactionData.isRecurring,
      recurringId: transactionData.recurringId,
      createdAt: transactionData.createdAt,
      updatedAt: transactionData.updatedAt,
    );
  }

  /// Delete orphaned transactions (transactions with missing category or wallet)
  /// Returns the number of deleted transactions
  Future<int> deleteOrphanedTransactions() async {
    Log.i('🧹 Checking for orphaned transactions...', label: 'transaction');

    // Find transactions with missing categories
    final missingCategoryQuery = customSelect(
      'SELECT id FROM transactions WHERE category_id NOT IN (SELECT id FROM categories)',
      readsFrom: {transactions},
    );
    final missingCategoryRows = await missingCategoryQuery.get();
    final missingCategoryIds =
        missingCategoryRows.map((row) => row.read<int>('id')).toList();

    // Find transactions with missing wallets
    final missingWalletQuery = customSelect(
      'SELECT id FROM transactions WHERE wallet_id NOT IN (SELECT id FROM wallets)',
      readsFrom: {transactions},
    );
    final missingWalletRows = await missingWalletQuery.get();
    final missingWalletIds =
        missingWalletRows.map((row) => row.read<int>('id')).toList();

    // Combine unique IDs
    final orphanedIds = {...missingCategoryIds, ...missingWalletIds}.toList();

    if (orphanedIds.isEmpty) {
      Log.i('✅ No orphaned transactions found', label: 'transaction');
      return 0;
    }

    // Delete orphaned transactions
    Log.w(
      '⚠️ Found ${orphanedIds.length} orphaned transactions, deleting...',
      label: 'transaction',
    );

    final deleted = await (delete(transactions)
          ..where((t) => t.id.isIn(orphanedIds)))
        .go();

    Log.i('✅ Deleted $deleted orphaned transactions', label: 'transaction');
    return deleted;
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
  /// Uses leftOuterJoin to handle cases where category or wallet may be missing.
  Stream<List<TransactionModel>> watchAllTransactionsWithDetails() {
    final query = select(transactions).join([
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      leftOuterJoin(
        db.wallets,
        db.wallets.id.equalsExp(transactions.walletId),
      ),
    ])
      ..orderBy([
        // Sort by date descending (newest first), then by id descending
        OrderingTerm.desc(transactions.date),
        OrderingTerm.desc(transactions.id),
      ]);

    return query.watch().asyncMap((rows) async {
      final result = <TransactionModel>[];
      for (final row in rows) {
        try {
          final transactionData = row.readTable(transactions);
          final categoryData = row.readTableOrNull(categories);
          final walletData = row.readTableOrNull(db.wallets);

          // Skip transactions with missing category or wallet (orphaned data)
          if (categoryData == null || walletData == null) {
            Log.w(
              'Skipping orphaned transaction ID: ${transactionData.id} '
              '(category: ${categoryData != null}, wallet: ${walletData != null})',
              label: 'transaction',
            );
            continue;
          }

          result.add(
            await _mapToTransactionModel(
              transactionData,
              categoryData,
              walletData,
            ),
          );
        } catch (e, stack) {
          Log.e('Error mapping transaction: $e', label: 'transaction');
          Log.e('Stack: $stack', label: 'transaction');
          // Continue processing other transactions
          continue;
        }
      }
      return result;
    });
  }

  /// Watches all transactions for a specific wallet with their associated category and wallet details.
  Stream<List<TransactionModel>> watchTransactionsByWalletIdWithDetails(
    int walletId,
  ) {
    Log.d(
      'Subscribing to watchTransactionsByWalletIdWithDetails($walletId)',
      label: 'transaction',
    );
    final query = select(transactions).join([
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      leftOuterJoin(db.wallets, db.wallets.id.equalsExp(transactions.walletId)),
    ])
      ..where(transactions.walletId.equals(walletId))
      ..orderBy([
        // Sort by date descending (newest first), then by id descending
        OrderingTerm.desc(transactions.date),
        OrderingTerm.desc(transactions.id),
      ]);

    return query.watch().asyncMap((rows) async {
      final result = <TransactionModel>[];
      for (final row in rows) {
        try {
          final transactionData = row.readTable(transactions);
          final categoryData = row.readTableOrNull(categories);
          final walletData = row.readTableOrNull(db.wallets);

          if (categoryData == null || walletData == null) {
            continue;
          }

          result.add(
            await _mapToTransactionModel(
              transactionData,
              categoryData,
              walletData,
            ),
          );
        } catch (e) {
          Log.e('Error mapping transaction: $e', label: 'transaction');
          continue;
        }
      }
      return result;
    });
  }

  /// Watches all transactions created from a specific recurring payment (payment history)
  Stream<List<TransactionModel>> watchTransactionsByRecurringId(int recurringId) {
    Log.d(
      'Subscribing to watchTransactionsByRecurringId($recurringId)',
      label: 'transaction',
    );
    final query = select(transactions).join([
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      leftOuterJoin(db.wallets, db.wallets.id.equalsExp(transactions.walletId)),
    ])
      ..where(transactions.recurringId.equals(recurringId))
      ..orderBy([
        // Sort by date descending (newest first) to show recent payments first
        OrderingTerm.desc(transactions.date),
        OrderingTerm.desc(transactions.id),
      ]);

    return query.watch().asyncMap((rows) async {
      final result = <TransactionModel>[];
      for (final row in rows) {
        try {
          final transactionData = row.readTable(transactions);
          final categoryData = row.readTableOrNull(categories);
          final walletData = row.readTableOrNull(db.wallets);

          if (categoryData == null || walletData == null) {
            continue;
          }

          result.add(
            await _mapToTransactionModel(
              transactionData,
              categoryData,
              walletData,
            ),
          );
        } catch (e) {
          Log.e('Error mapping recurring transaction: $e', label: 'transaction');
          continue;
        }
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
            leftOuterJoin(
              categories,
              categories.id.equalsExp(transactions.categoryId),
            ),
            leftOuterJoin(
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
      final categoryData = row.readTableOrNull(categories);
      final walletData = row.readTableOrNull(db.wallets);

      if (categoryData == null || walletData == null) {
        continue;
      }

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

    // 1. Generate cloudId IMMEDIATELY to prevent race condition with realtime sync
    final cloudId = transactionModel.cloudId ?? const Uuid().v7();
    print('🆔 [TRANSACTION_INSERT] Generated cloudId: $cloudId for transaction: ${transactionModel.title}');

    // 2. Save to local database WITH cloudId
    final companion = TransactionsCompanion(
      cloudId: Value(cloudId), // CRITICAL: Set cloudId at insert time!
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
      recurringId: Value(transactionModel.recurringId), // Link to recurring payment for history tracking
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    final id = await into(transactions).insert(companion);
    print('✅ [TRANSACTION_INSERT] Inserted transaction with ID=$id, cloudId=$cloudId');

    // 2. Adjust wallet balance
    final walletId = transactionModel.wallet.id!;
    final amount = transactionModel.amount;
    final type = transactionModel.transactionType;

    final wallet = await db.walletDao.getWalletById(walletId);
    if (wallet != null) {
      double newBalance = wallet.balance;
      if (type == TransactionType.income) {
        newBalance += amount;
      } else if (type == TransactionType.expense) {
        newBalance -= amount;
      }

      await (db.update(db.wallets)..where((w) => w.id.equals(walletId)))
          .write(WalletsCompanion(balance: Value(newBalance)));

      print('💰 [wallet adjustment] Wallet $walletId balance: ${wallet.balance} -> $newBalance');
    }

    // 3. Upload to cloud with retry (if sync available)
    print('🔍 [SYNC CHECK] _ref is null: ${_ref == null}, cloudId: $cloudId');
    if (_ref != null) {
      print('✅ [SYNC] Starting upload for transaction $id (cloudId: $cloudId)');
      // Fire and forget upload (don't block UI)
      _uploadTransactionWithRetry(id, cloudId).catchError((e) {
        print('❌ [SYNC ERROR] Upload failed: $e');
        Log.e('All upload attempts failed: $e', label: 'sync');
        // TODO: Show toast notification to user
      });
    } else {
      print('⚠️ [SYNC DISABLED] _ref is null - sync not available. DAO was created without Riverpod ref!');
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

    // 2. Upload to cloud with retry (if sync available)
    print('🔍 [UPDATE SYNC CHECK] success: $success, _ref is null: ${_ref == null}, transactionId: ${transactionModel.id}');
    if (success && _ref != null && transactionModel.id != null) {
      print('✅ [UPDATE SYNC] Starting upload for transaction ${transactionModel.id}');
      // Fire and forget upload (don't block UI)
      _uploadTransactionWithRetry(transactionModel.id!, transactionModel.cloudId ?? '').catchError((e) {
        print('❌ [UPDATE SYNC ERROR] Upload failed: $e');
        Log.e('Failed to upload transaction update: $e', label: 'sync');
      });
    } else {
      print('⚠️ [UPDATE SYNC DISABLED] Conditions not met - success: $success, _ref null: ${_ref == null}');
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
        final syncService = _ref.read(supabaseSyncServiceProvider);
        if (syncService.isAuthenticated) {
          await syncService.deleteTransactionFromCloud(transaction.cloudId!);
        }
      } catch (e, stack) {
        Log.e('Failed to delete transaction from cloud: $e', label: 'sync');
        Log.e('Stack: $stack', label: 'sync');
        // Don't rethrow - local delete succeeded
      }
    }

    return count;
  }

  /// Delete a transaction by cloudId (for sync - when cloud soft-deletes)
  /// Does NOT sync back to cloud to avoid infinite loop
  Future<bool> deleteTransactionByCloudId(String cloudId) async {
    Log.d('Deleting local transaction by cloudId: $cloudId', label: 'transaction');
    final count = await (delete(transactions)..where((tbl) => tbl.cloudId.equals(cloudId))).go();
    if (count > 0) {
      Log.d('✅ Deleted local transaction with cloudId: $cloudId', label: 'transaction');
    }
    return count > 0;
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
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      leftOuterJoin(db.wallets, db.wallets.id.equalsExp(transactions.walletId)),
    ])
      ..where(transactions.walletId.equals(walletId))
      ..orderBy([
        // Sort by date descending (newest first), then by id descending
        OrderingTerm.desc(transactions.date),
        OrderingTerm.desc(transactions.id),
      ]);

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
        try {
          final transactionData = row.readTable(transactions);
          final categoryData = row.readTableOrNull(categories);
          final walletData = row.readTableOrNull(db.wallets);

          if (categoryData == null || walletData == null) {
            continue;
          }

          result.add(
            await _mapToTransactionModel(
              transactionData,
              categoryData,
              walletData,
            ),
          );
        } catch (e) {
          Log.e('Error mapping filtered transaction: $e', label: 'transaction');
          continue;
        }
      }
      return result;
    });
  }

  // --- Upload Helpers ---

  /// Upload transaction with retry logic (fire and forget)
  /// CRITICAL: Ensures dependencies (category, wallet) are synced BEFORE transaction
  Future<void> _uploadTransactionWithRetry(int transactionId, String cloudId) async {
    print('📤 [_uploadTransactionWithRetry] Called for transaction $transactionId (cloudId: $cloudId)');
    return RetryHelper.retry(
      operationName: 'Upload transaction $cloudId',
      operation: () async {
        print('🔄 [RetryHelper] Starting upload operation...');
        final syncService = _ref?.read(supabaseSyncServiceProvider);
        print('🔍 [SyncService] syncService is null: ${syncService == null}, authenticated: ${syncService?.isAuthenticated ?? false}');
        if (syncService == null || !syncService.isAuthenticated) {
          print('⚠️ [SyncService] Not available or not authenticated - aborting upload');
          Log.w('Supabase sync not available or not authenticated', label: 'sync');
          return;
        }

        print('📦 [Fetching] Getting transaction data from local DB...');
        // Fetch full transaction model
        final savedTransaction = await (select(transactions)..where((t) => t.id.equals(transactionId))).getSingleOrNull();
        if (savedTransaction == null) {
          print('❌ [Error] Transaction $transactionId not found in local DB');
          throw Exception('Transaction $transactionId not found');
        }

        final category = await (select(categories)..where((c) => c.id.equals(savedTransaction.categoryId))).getSingleOrNull();
        final wallet = await (select(db.wallets)..where((w) => w.id.equals(savedTransaction.walletId))).getSingleOrNull();

        if (category == null || wallet == null) {
          print('❌ [Error] Missing category or wallet - category null: ${category == null}, wallet null: ${wallet == null}');
          throw Exception('Missing category or wallet');
        }

        // CRITICAL FIX: Sync dependencies BEFORE uploading transaction to prevent foreign key errors!
        print('🔍 [DEPENDENCY CHECK] Ensuring category and wallet exist on cloud before uploading transaction...');

        // 1. Sync category first if it has a cloudId
        // IMPORTANT: Use forceUpload=true to ensure category exists even if it's unmodified built-in
        if (category.cloudId != null) {
          try {
            final categoryModel = category.toModel();
            print('📤 [CATEGORY SYNC] Force uploading category: ${categoryModel.title} (${categoryModel.cloudId})');
            await syncService.uploadCategory(categoryModel, forceUpload: true);
            print('✅ [CATEGORY SYNC] Category synced successfully');
          } catch (e) {
            print('⚠️ [CATEGORY SYNC] Failed to sync category (may already exist): $e');
            // Continue - category might already exist on cloud
          }
        } else {
          print('⚠️ [CATEGORY SYNC] Category has no cloudId, skipping sync');
        }

        // 2. Sync wallet second if it has a cloudId
        if (wallet.cloudId != null) {
          try {
            final walletModel = wallet.toModel();
            print('📤 [WALLET SYNC] Uploading wallet: ${walletModel.name} (${walletModel.cloudId})');
            await syncService.uploadWallet(walletModel);
            print('✅ [WALLET SYNC] Wallet synced successfully');
          } catch (e) {
            print('⚠️ [WALLET SYNC] Failed to sync wallet (may already exist): $e');
            // Continue - wallet might already exist on cloud
          }
        } else {
          print('⚠️ [WALLET SYNC] Wallet has no cloudId, skipping sync');
        }

        // 3. Now upload transaction (dependencies are guaranteed to exist)
        print('✅ [Data Ready] Transaction, category, wallet all ready. Mapping to model...');
        final model = await _mapToTransactionModel(savedTransaction, category, wallet);
        print('🚀 [Uploading] Calling syncService.uploadTransaction for ${model.title}...');
        await syncService.uploadTransaction(model);
        print('✅✅✅ [SUCCESS] Transaction uploaded: ${model.title}');
        Log.d('✅ Transaction uploaded: ${model.title}', label: 'sync');
      },
    );
  }

  // --- Sync Operations ---

  /// Create or update transaction (used by sync service to pull from cloud)
  /// Uses cloudId to find existing transaction, or creates new one
  /// NOTE: This method does NOT sync back to cloud (to avoid infinite loop)
  Future<void> createOrUpdateTransaction(TransactionModel transactionModel) async {
    Log.d('Creating or updating transaction from cloud: ${transactionModel.cloudId}', label: 'transaction');

    // 1. Resolve wallet ID from cloudId
    final wallet = transactionModel.wallet.cloudId != null
        ? await db.walletDao.getWalletByCloudId(transactionModel.wallet.cloudId!)
        : null;

    if (wallet == null) {
      Log.w('⚠️ Cannot create/update transaction: wallet not found (cloudId: ${transactionModel.wallet.cloudId})', label: 'transaction');
      return; // Skip this transaction
    }

    // 2. Resolve category ID from cloudId
    final category = transactionModel.category.cloudId != null
        ? await db.categoryDao.getCategoryByCloudId(transactionModel.category.cloudId!)
        : null;

    if (category == null) {
      Log.w('⚠️ Cannot create/update transaction: category not found (cloudId: ${transactionModel.category.cloudId})', label: 'transaction');
      return; // Skip this transaction
    }

    // 3. Check if transaction exists by cloudId
    final existingTransaction = transactionModel.cloudId != null
        ? await getTransactionByCloudId(transactionModel.cloudId!)
        : null;

    if (existingTransaction != null) {
      // CRITICAL: Only update if cloud data is NEWER than local data
      // This prevents overwriting correct local data with stale cloud data
      final cloudUpdatedAt = transactionModel.updatedAt ?? DateTime(2000); // Fallback to old date
      final localUpdatedAt = existingTransaction.updatedAt ?? DateTime(2000);

      if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
        // Cloud data is newer - update local
        final companion = TransactionsCompanion(
          id: Value(existingTransaction.id),
          cloudId: Value(transactionModel.cloudId),
          walletId: Value(wallet.id),
          categoryId: Value(category.id),
          transactionType: Value(transactionModel.transactionType.index),
          amount: Value(transactionModel.amount),
          date: Value(transactionModel.date),
          title: Value(transactionModel.title),
          notes: Value(transactionModel.notes),
          imagePath: Value(transactionModel.imagePath),
          isRecurring: Value(transactionModel.isRecurring ?? false),
          recurringId: Value(transactionModel.recurringId),
          createdAt: transactionModel.createdAt != null
              ? Value(transactionModel.createdAt!)
              : const Value.absent(),
          updatedAt: Value(transactionModel.updatedAt ?? DateTime.now()),
        );
        await update(transactions).replace(companion);
        Log.d('✅ Updated transaction ${existingTransaction.id} from cloud (cloud newer: $cloudUpdatedAt > $localUpdatedAt)', label: 'transaction');
      } else {
        // Local data is newer or same - keep local, skip update
        Log.w('⏭️ Skipping transaction ${existingTransaction.id} update - local data is newer or same (local: $localUpdatedAt >= cloud: $cloudUpdatedAt)', label: 'transaction');
      }
    } else {
      // Create new transaction (local only, no cloud sync)
      final companion = TransactionsCompanion.insert(
        cloudId: Value(transactionModel.cloudId),
        walletId: wallet.id,
        categoryId: category.id,
        transactionType: transactionModel.transactionType.index,
        amount: transactionModel.amount,
        date: transactionModel.date,
        title: transactionModel.title,
        notes: Value(transactionModel.notes),
        imagePath: Value(transactionModel.imagePath),
        isRecurring: Value(transactionModel.isRecurring ?? false),
        recurringId: Value(transactionModel.recurringId),
        createdAt: transactionModel.createdAt != null
            ? Value(transactionModel.createdAt!)
            : Value(DateTime.now()),
        updatedAt: Value(transactionModel.updatedAt ?? DateTime.now()),
      );
      final id = await into(transactions).insert(companion);
      Log.d('Created new transaction $id from cloud', label: 'transaction');
    }
  }

  /// Get recent transactions with details for recurring pattern detection.
  /// Returns non-deleted transactions from the last [days] days.
  Future<List<TransactionModel>> getRecentTransactionsForDetection({int days = 90}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final query = select(transactions).join([
      leftOuterJoin(categories, categories.id.equalsExp(transactions.categoryId)),
      leftOuterJoin(db.wallets, db.wallets.id.equalsExp(transactions.walletId)),
    ])
      ..where(transactions.date.isBiggerOrEqualValue(cutoff))
      ..where(transactions.isDeleted.equals(false))
      ..orderBy([OrderingTerm.desc(transactions.date)]);

    final rows = await query.get();
    final results = <TransactionModel>[];

    for (final row in rows) {
      final txn = row.readTable(transactions);
      final cat = row.readTableOrNull(categories);
      final wal = row.readTableOrNull(db.wallets);
      if (cat != null && wal != null) {
        results.add(await _mapToTransactionModel(txn, cat, wal));
      }
    }

    return results;
  }
}
