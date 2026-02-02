import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/daos/chat_message_dao.dart';
import 'package:bexly/core/database/tables/wallet_table.dart'; // For WalletTableExtensions
import 'package:bexly/core/database/tables/category_table.dart'; // For CategoryTableExtensions
import 'package:bexly/core/database/tables/budgets_table.dart'; // For BudgetTableExtensions
import 'package:bexly/core/database/tables/goal_table.dart'; // For GoalTableExtensions
import 'package:bexly/core/database/tables/checklist_item_table.dart'; // For ChecklistItemTableExtensions
import 'package:bexly/core/database/tables/recurrings_table.dart'; // For RecurringTableExtensions
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/goal/data/model/goal_model.dart';
import 'package:bexly/features/goal/data/model/checklist_item_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';

/// Provider for Supabase sync service
final supabaseSyncServiceProvider = Provider<SupabaseSyncService>((ref) {
  return SupabaseSyncService(ref);
});

/// Service to sync local Drift database with Supabase PostgreSQL.
///
/// Architecture:
/// - Local: Drift/SQLite (source of truth for offline)
/// - Cloud: Supabase PostgreSQL bexly schema
/// - Sync: Bidirectional sync with conflict resolution
class SupabaseSyncService {
  static const _label = 'SupabaseSync';
  final Ref _ref;

  /// Supabase client instance
  SupabaseClient get _supabase => SupabaseInitService.client;

  /// Current user ID (Supabase auth)
  String? get _userId => SupabaseInitService.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => _userId != null;

  SupabaseSyncService(this._ref);

  // ======================================
  // WALLET SYNC
  // ======================================

  /// Sync all wallets to Supabase
  Future<void> syncWalletsToCloud() async {
    if (_userId == null) {
      Log.w('Cannot sync wallets: user not authenticated', label: _label);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      final wallets = await db.walletDao.watchAllWallets().first;

      Log.d('Syncing ${wallets.length} wallets to Supabase...', label: _label);

      for (final wallet in wallets) {
        await _upsertWallet(wallet);
      }

      Log.i('Wallets synced successfully', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error syncing wallets: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Upsert a single wallet to Supabase bexly.wallets table
  Future<void> _upsertWallet(WalletModel wallet) async {
    try {
      // Convert WalletModel to Supabase schema
      final data = {
        'cloud_id': wallet.cloudId, // UUID v7
        'user_id': _userId,
        'name': wallet.name,
        'balance': wallet.balance,
        'currency': wallet.currency,
        'wallet_type': _mapWalletType(wallet.walletType.name), // Convert enum to string
        'credit_limit': wallet.creditLimit,
        'billing_date': wallet.billingDay,
        'interest_rate': wallet.interestRate,
        'is_shared': wallet.isShared,
        'is_active': true, // Wallets in app are always active
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('wallets')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      Log.d('Wallet ${wallet.name} synced (${wallet.cloudId})', label: _label);
    } catch (e) {
      Log.e('Error upserting wallet ${wallet.name}: $e', label: _label);
      rethrow;
    }
  }

  /// Map WalletType to string for Supabase
  String _mapWalletType(String walletType) {
    switch (walletType.toLowerCase()) {
      case 'cash':
        return 'cash';
      case 'bank_account':
      case 'bankaccount':
        return 'bank_account';
      case 'credit_card':
      case 'creditcard':
        return 'credit_card';
      default:
        return 'cash';
    }
  }

  /// Upload a single wallet to Supabase (public method for DAO)
  Future<void> uploadWallet(WalletModel wallet) async {
    Log.d('🔍 uploadWallet called for: ${wallet.name}', label: _label);
    Log.d('   → _userId: $_userId', label: _label);
    Log.d('   → isAuthenticated: $isAuthenticated', label: _label);
    Log.d('   → currentUser: ${SupabaseInitService.currentUser?.email}', label: _label);
    Log.d('   → currentSession: ${SupabaseInitService.currentSession != null ? "exists" : "null"}', label: _label);

    if (_userId == null) {
      Log.e('❌ Cannot upload wallet: _userId is NULL!', label: _label);
      Log.e('   → Supabase.instance.client.auth.currentUser: ${_supabase.auth.currentUser?.email}', label: _label);
      throw Exception('Cannot upload wallet: user not authenticated (_userId is null)');
    }

    return _upsertWallet(wallet);
  }

  /// Delete wallet from Supabase
  Future<void> deleteWalletFromCloud(String cloudId) async {
    if (_userId == null) {
      Log.w('Cannot delete wallet: user not authenticated', label: _label);
      return;
    }

    try {
      await _supabase
          .schema('bexly')
          .from('wallets')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('cloud_id', cloudId)
          .eq('user_id', _userId!);

      Log.d('Wallet $cloudId marked as inactive', label: _label);
    } catch (e) {
      Log.e('Error deleting wallet $cloudId: $e', label: _label);
      rethrow;
    }
  }

  /// Fetch wallets from Supabase and update local database
  Future<void> pullWalletsFromCloud() async {
    if (_userId == null) {
      Log.w('Cannot pull wallets: user not authenticated', label: _label);
      return;
    }

    try {
      final response = await _supabase
          .schema('bexly')
          .from('wallets')
          .select()
          .eq('user_id', _userId!)
          .eq('is_active', true);

      final wallets = (response as List)
          .map((data) => _mapSupabaseToWalletModel(data))
          .toList();

      final db = _ref.read(databaseProvider);
      for (final wallet in wallets) {
        await db.walletDao.createOrUpdateWallet(wallet);
      }

      Log.i('Pulled ${wallets.length} wallets from Supabase', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error pulling wallets: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Map Supabase data to WalletModel
  WalletModel _mapSupabaseToWalletModel(Map<String, dynamic> walletData) {
    return WalletModel(
      cloudId: walletData['cloud_id'],
      name: walletData['name'] ?? 'Unnamed Wallet',
      balance: (walletData['balance'] as num?)?.toDouble() ?? 0.0,
      currency: walletData['currency'] ?? 'IDR',
      creditLimit: (walletData['credit_limit'] as num?)?.toDouble(),
      billingDay: walletData['billing_date'] as int?,
      interestRate: (walletData['interest_rate'] as num?)?.toDouble(),
      isShared: walletData['is_shared'] ?? false,
      createdAt: walletData['created_at'] != null
          ? DateTime.parse(walletData['created_at'])
          : null,
      updatedAt: walletData['updated_at'] != null
          ? DateTime.parse(walletData['updated_at'])
          : null,
    );
  }

  // ======================================
  // TRANSACTION SYNC
  // ======================================

  /// Sync all transactions to Supabase
  Future<void> syncTransactionsToCloud() async {
    if (_userId == null) {
      Log.w('Cannot sync transactions: user not authenticated', label: _label);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      final transactions = await db.transactionDao.getAllTransactions();

      Log.d('Syncing ${transactions.length} transactions to Supabase...', label: _label);

      for (final transaction in transactions) {
        await _upsertTransaction(transaction);
      }

      Log.i('Transactions synced successfully', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error syncing transactions: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Upsert transaction to Supabase (from Drift Transaction entity)
  Future<void> _upsertTransaction(dynamic transaction) async {
    try {
      // Resolve wallet and category cloudIds
      final db = _ref.read(databaseProvider);
      final wallet = await db.walletDao.getWalletById(transaction.walletId);
      final category = await db.categoryDao.getCategoryById(transaction.categoryId);

      if (wallet == null || category == null) {
        Log.w('⚠️ Cannot sync transaction: wallet or category not found', label: _label);
        return;
      }

      final data = {
        'cloud_id': transaction.cloudId,
        'user_id': _userId,
        'wallet_id': wallet.cloudId,
        'category_id': category.cloudId,
        'transaction_type': _mapTransactionType(transaction.transactionType),
        'amount': transaction.amount,
        'currency': wallet.currency,
        'transaction_date': transaction.date.toIso8601String(),
        'title': transaction.title,
        'notes': transaction.notes,
        'parsed_from_email': false,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('transactions')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      Log.d('Transaction ${transaction.title} synced', label: _label);
    } catch (e) {
      Log.e('Error upserting transaction: $e', label: _label);
      rethrow;
    }
  }

  /// Map TransactionType int to string
  String _mapTransactionType(int type) {
    switch (type) {
      case 0:
        return 'income';
      case 1:
        return 'expense';
      case 2:
        return 'transfer';
      default:
        return 'expense';
    }
  }

  /// Map TransactionType string to enum
  TransactionType _mapStringToTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  /// Upload a single transaction to Supabase (public method for DAO)
  Future<void> uploadTransaction(TransactionModel transaction) async {
    if (_userId == null) {
      Log.w('Cannot upload transaction: user not authenticated', label: _label);
      return;
    }

    try {
      // Ensure wallet has cloudId
      String? walletCloudId = transaction.wallet.cloudId;
      if (walletCloudId == null) {
        Log.w('⚠️ Wallet has no cloudId, auto-assigning...', label: _label);
        walletCloudId = Uuid().v7();
        final db = _ref.read(databaseProvider);

        // transaction.wallet.id might be null, check first
        if (transaction.wallet.id != null) {
          await (db.update(db.wallets)..where((t) => t.id.equals(transaction.wallet.id!)))
              .write(WalletsCompanion(cloudId: Value(walletCloudId)));

          // Upload wallet to cloud (getWalletById returns Wallet, need to convert to WalletModel)
          final updatedWallet = await db.walletDao.getWalletById(transaction.wallet.id!);
          if (updatedWallet != null) {
            await uploadWallet(updatedWallet.toModel());
          }
        }
      }

      // Ensure category has cloudId
      String? categoryCloudId = transaction.category.cloudId;
      if (categoryCloudId == null) {
        Log.w('⚠️ Category has no cloudId, auto-assigning...', label: _label);
        categoryCloudId = Uuid().v7();
        final db = _ref.read(databaseProvider);

        // transaction.category.id might be null, check first
        if (transaction.category.id != null) {
          await (db.update(db.categories)..where((t) => t.id.equals(transaction.category.id!)))
              .write(CategoriesCompanion(cloudId: Value(categoryCloudId)));

          // Upload category to cloud (getCategoryById returns Category, need to convert to CategoryModel)
          final updatedCategory = await db.categoryDao.getCategoryById(transaction.category.id!);
          if (updatedCategory != null) {
            await uploadCategory(updatedCategory.toModel());
          }
        }
      }

      // CRITICAL: Check if cloud has newer version before overwriting
      // This prevents old local data from overwriting newer cloud data
      if (transaction.cloudId != null) {
        try {
          final existingCloud = await _supabase
              .schema('bexly')
              .from('transactions')
              .select('updated_at')
              .eq('cloud_id', transaction.cloudId!)
              .maybeSingle();

          if (existingCloud != null) {
            final cloudUpdatedAt = DateTime.parse(existingCloud['updated_at']);
            final localUpdatedAt = transaction.updatedAt ?? DateTime(2000);

            if (cloudUpdatedAt.isAfter(localUpdatedAt)) {
              // Cloud data is newer - skip upload to prevent overwriting
              Log.w('⏭️ Skipping transaction upload - cloud data is newer (cloud: $cloudUpdatedAt > local: $localUpdatedAt)', label: _label);
              return;
            }
          }
        } catch (e) {
          Log.d('Could not check cloud timestamp (transaction may not exist yet): $e', label: _label);
          // Continue with upload if transaction doesn't exist on cloud
        }
      }

      final data = {
        'cloud_id': transaction.cloudId,
        'user_id': _userId,
        'wallet_id': walletCloudId,
        'category_id': categoryCloudId,
        'transaction_type': _mapTransactionType(transaction.transactionType.index),
        'amount': transaction.amount,
        'currency': transaction.wallet.currency,
        'transaction_date': transaction.date.toIso8601String(),
        'title': transaction.title,  // Now matches both Drift and Supabase field name
        'notes': transaction.notes,
        'parsed_from_email': false,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('transactions')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      Log.d('✅ Transaction ${transaction.title} uploaded (${transaction.cloudId})', label: _label);
    } catch (e) {
      Log.e('Error uploading transaction ${transaction.title}: $e', label: _label);
      rethrow;
    }
  }

  /// Delete transaction from Supabase
  Future<void> deleteTransactionFromCloud(String cloudId) async {
    if (_userId == null) {
      Log.w('Cannot delete transaction: user not authenticated', label: _label);
      return;
    }

    try {
      await _supabase
          .schema('bexly')
          .from('transactions')
          .delete()
          .eq('cloud_id', cloudId)
          .eq('user_id', _userId!);

      Log.d('Transaction $cloudId deleted from cloud', label: _label);
    } catch (e) {
      Log.e('Error deleting transaction $cloudId: $e', label: _label);
      rethrow;
    }
  }

  /// Fetch transactions from Supabase and update local database
  Future<void> pullTransactionsFromCloud() async {
    if (_userId == null) {
      Log.w('Cannot pull transactions: user not authenticated', label: _label);
      return;
    }

    try {
      final response = await _supabase
          .schema('bexly')
          .from('transactions')
          .select()
          .eq('user_id', _userId!);

      final db = _ref.read(databaseProvider);
      final transactionData = (response as List);

      Log.d('Found ${transactionData.length} transactions on Supabase', label: _label);

      int processedCount = 0;
      int skippedCount = 0;

      for (final data in transactionData) {
        try {
          // Resolve wallet from cloudId
          final walletCloudId = data['wallet_id'];  // Fixed: wallet_id not wallet_cloud_id
          if (walletCloudId == null) {
            Log.w('⚠️ Transaction has no wallet_id, skipping', label: _label);
            skippedCount++;
            continue;
          }

          final wallet = await db.walletDao.getWalletByCloudId(walletCloudId);
          if (wallet == null) {
            Log.w('⚠️ Wallet not found for cloudId $walletCloudId, skipping transaction', label: _label);
            skippedCount++;
            continue;
          }

          // Resolve category from cloudId
          final categoryCloudId = data['category_id'];  // Fixed: category_id not category_cloud_id
          if (categoryCloudId == null) {
            Log.w('⚠️ Transaction has no category_id, skipping', label: _label);
            skippedCount++;
            continue;
          }

          final category = await db.categoryDao.getCategoryByCloudId(categoryCloudId);
          if (category == null) {
            Log.w('⚠️ Category not found for cloudId $categoryCloudId, skipping transaction', label: _label);
            skippedCount++;
            continue;
          }

          // Create TransactionModel
          final transactionModel = TransactionModel(
            cloudId: data['cloud_id'],
            transactionType: _mapStringToTransactionType(data['transaction_type']),
            amount: (data['amount'] as num).toDouble(),
            date: DateTime.parse(data['transaction_date']),  // Fixed: transaction_date not date
            title: data['title'] ?? 'Unnamed Transaction',  // Now matches Supabase schema
            notes: data['notes'],
            wallet: wallet.toModel(),
            category: category.toModel(),
            createdAt: data['created_at'] != null
                ? DateTime.parse(data['created_at'])
                : null,
            updatedAt: data['updated_at'] != null
                ? DateTime.parse(data['updated_at'])
                : null,
          );

          await db.transactionDao.createOrUpdateTransaction(transactionModel);
          processedCount++;
        } catch (e) {
          Log.e('Failed to process transaction: $e', label: _label);
          skippedCount++;
        }
      }

      Log.i('Pulled transactions: $processedCount processed, $skippedCount skipped', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error pulling transactions: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  // ======================================
  // CATEGORY SYNC
  // ======================================

  /// Sync categories to Supabase (Modified Hybrid Sync)
  /// Only syncs:
  /// - Custom categories (source = 'custom')
  /// - Modified built-in categories (source = 'built-in' AND has_been_modified = true)
  /// - Soft-deleted categories (is_deleted = true) to sync deletion across devices
  Future<void> syncCategoriesToCloud() async {
    if (_userId == null) {
      Log.w('Cannot sync categories: user not authenticated', label: _label);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      final allCategories = await db.categoryDao.getAllCategories();

      // Check if cloud has any categories (initial sync check)
      final cloudCategoriesResponse = await _supabase
          .schema('bexly')
          .from('categories')
          .select('cloud_id')
          .eq('user_id', _userId!)
          .limit(1);

      final hasCloudCategories = (cloudCategoriesResponse as List).isNotEmpty;

      List<dynamic> categoriesToSync;

      if (!hasCloudCategories) {
        // Initial sync: sync ALL categories once
        categoriesToSync = allCategories;
        Log.d('Initial sync: Syncing ALL ${allCategories.length} categories to Supabase...', label: _label);
      } else {
        // Modified Hybrid Sync: only sync custom categories OR modified built-ins
        categoriesToSync = allCategories.where((category) {
          return category.source == 'custom' ||
                 (category.source == 'built-in' && category.hasBeenModified == true);
        }).toList();

        Log.d('Syncing ${categoriesToSync.length}/${allCategories.length} categories to Supabase (Modified Hybrid Sync)...', label: _label);
        Log.d('  → Custom: ${categoriesToSync.where((c) => c.source == 'custom').length}', label: _label);
        Log.d('  → Modified Built-in: ${categoriesToSync.where((c) => c.source == 'built-in' && c.hasBeenModified == true).length}', label: _label);
      }

      for (final category in categoriesToSync) {
        await _upsertCategory(category);
      }

      final savedCount = allCategories.length - categoriesToSync.length;
      Log.i('Categories synced successfully${savedCount > 0 ? " (saved $savedCount unmodified built-ins)" : ""}', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error syncing categories: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Upsert category to Supabase (from Drift Category entity)
  Future<void> _upsertCategory(dynamic category) async {
    try {
      final data = {
        'cloud_id': category.cloudId,
        'user_id': _userId,
        'name': category.title, // Drift Category has 'title'
        'icon': category.icon,
        'icon_background': category.iconBackground,  // Match Supabase schema
        'icon_type': category.iconType,  // Match Supabase schema
        'parent_id': null,  // TODO: Support parent categories
        'description': category.description,
        'localized_titles': category.localizedTitles,
        'is_system_default': category.isSystemDefault ?? false,
        'source': category.source ?? 'built-in',  // Modified Hybrid Sync
        'built_in_id': category.builtInId,  // Modified Hybrid Sync
        'has_been_modified': category.hasBeenModified ?? false,  // Modified Hybrid Sync
        'is_deleted': category.isDeleted ?? false,  // Soft delete support
        'category_type': category.transactionType, // 'income' or 'expense' (string)
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('categories')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      final syncType = category.source == 'custom' ? 'custom' : 'modified built-in';
      Log.d('Category ${category.title} synced as $syncType (${category.cloudId})', label: _label);
    } catch (e) {
      Log.e('Error upserting category ${category.title}: $e', label: _label);
      rethrow;
    }
  }

  /// Upload a single category to Supabase (public method for DAO)
  /// Modified Hybrid Sync: Only upload if custom OR modified built-in
  /// Upload category to Supabase
  ///
  /// [forceUpload] - If true, uploads even unmodified built-in categories.
  ///                 Use this when ensuring category exists (e.g., auto-sync transaction dependencies).
  Future<void> uploadCategory(CategoryModel category, {bool forceUpload = false}) async {
    if (_userId == null) {
      Log.w('Cannot upload category: user not authenticated', label: _label);
      return;
    }

    // Modified Hybrid Sync: Skip unmodified built-ins (unless forced)
    final shouldSync = forceUpload ||
                      category.source == 'custom' ||
                      (category.source == 'built-in' && category.hasBeenModified == true);

    if (!shouldSync) {
      Log.d('Skipping unmodified built-in category: ${category.title}', label: _label);
      return;
    }

    try {
      final data = {
        'cloud_id': category.cloudId,
        'user_id': _userId,
        'name': category.title,
        'icon': category.icon,
        'icon_background': category.iconBackground,  // Match Supabase schema
        'icon_type': category.iconTypeValue,  // Match Supabase schema
        'parent_id': null,  // TODO: Support parent categories
        'description': category.description,
        'localized_titles': category.localizedTitles,
        'is_system_default': category.isSystemDefault,
        'source': category.source ?? 'built-in',  // Modified Hybrid Sync
        'built_in_id': category.builtInId,  // Modified Hybrid Sync
        'has_been_modified': category.hasBeenModified ?? false,  // Modified Hybrid Sync
        'is_deleted': category.isDeleted ?? false,  // Soft delete support
        'category_type': category.transactionType,  // 'income' or 'expense' (string)
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('categories')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      final syncType = category.source == 'custom' ? 'custom' : 'modified built-in';
      Log.d('Category ${category.title} uploaded as $syncType (${category.cloudId})', label: _label);
    } catch (e) {
      Log.e('Error uploading category ${category.title}: $e', label: _label);
      rethrow;
    }
  }

  /// Soft delete category from Supabase
  /// Sets is_deleted = true to sync deletion across devices
  Future<void> deleteCategoryFromCloud(String cloudId) async {
    if (_userId == null) {
      Log.w('Cannot delete category: user not authenticated', label: _label);
      return;
    }

    try {
      // Soft delete: set is_deleted = true instead of hard delete
      await _supabase
          .schema('bexly')
          .from('categories')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('cloud_id', cloudId)
          .eq('user_id', _userId!);

      Log.d('Category $cloudId soft deleted from cloud', label: _label);
    } catch (e) {
      Log.e('Error deleting category $cloudId: $e', label: _label);
      rethrow;
    }
  }

  /// Fetch categories from Supabase and update local database
  /// Modified Hybrid Sync: Pull only custom and modified built-in categories
  /// Also syncs soft-deleted categories to ensure consistent deletion across devices
  Future<void> pullCategoriesFromCloud() async {
    if (_userId == null) {
      Log.w('Cannot pull categories: user not authenticated', label: _label);
      return;
    }

    try {
      // Pull ALL categories (including soft-deleted) to sync deletions
      final response = await _supabase
          .schema('bexly')
          .from('categories')
          .select()
          .eq('user_id', _userId!);

      final categories = (response as List)
          .map((data) => _mapSupabaseToCategoryModel(data))
          .toList();

      Log.d('Pulled ${categories.length} categories from Supabase', label: _label);
      Log.d('  → Custom: ${categories.where((c) => c.source == 'custom').length}', label: _label);
      Log.d('  → Modified Built-in: ${categories.where((c) => c.source == 'built-in' && c.hasBeenModified == true).length}', label: _label);
      Log.d('  → Soft-deleted: ${categories.where((c) => c.isDeleted == true).length}', label: _label);

      final db = _ref.read(databaseProvider);
      for (final category in categories) {
        await db.categoryDao.createOrUpdateCategory(category);
      }

      Log.i('Categories synced from cloud successfully', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error pulling categories: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Map Supabase data to CategoryModel
  CategoryModel _mapSupabaseToCategoryModel(Map<String, dynamic> categoryData) {
    return CategoryModel(
      cloudId: categoryData['cloud_id'],
      title: categoryData['name'] ?? 'Unnamed Category',
      icon: categoryData['icon'] ?? '',
      iconBackground: categoryData['icon_background'] ?? '',
      iconTypeValue: categoryData['icon_type'] ?? '',
      source: categoryData['source'] ?? 'built-in',  // Modified Hybrid Sync
      builtInId: categoryData['built_in_id'],  // Modified Hybrid Sync
      hasBeenModified: categoryData['has_been_modified'] ?? false,  // Modified Hybrid Sync
      isDeleted: categoryData['is_deleted'] ?? false,  // Soft delete support
      transactionType: categoryData['category_type'] == 0 ? 'expense' : 'income',
      createdAt: categoryData['created_at'] != null
          ? DateTime.parse(categoryData['created_at'])
          : null,
      updatedAt: categoryData['updated_at'] != null
          ? DateTime.parse(categoryData['updated_at'])
          : null,
    );
  }

  /// Get list of modified built-in IDs from cloud
  /// Used when initializing categories on a new device to skip modified built-ins
  /// Returns Set<String> of built_in_ids that should NOT be populated locally
  Future<Set<String>> getModifiedBuiltInIds() async {
    if (_userId == null) {
      Log.w('Cannot get modified built-in IDs: user not authenticated', label: _label);
      return {};
    }

    try {
      final response = await _supabase
          .schema('bexly')
          .from('categories')
          .select('built_in_id')
          .eq('user_id', _userId!)
          .eq('source', 'built-in')
          .eq('has_been_modified', true)
          .not('built_in_id', 'is', null);

      final modifiedIds = (response as List)
          .map((data) => data['built_in_id'] as String)
          .toSet();

      Log.d('Found ${modifiedIds.length} modified built-in categories on cloud', label: _label);
      return modifiedIds;
    } catch (e) {
      Log.e('Error getting modified built-in IDs: $e', label: _label);
      return {};
    }
  }

  // ======================================
  // FULL SYNC
  // ======================================

  /// Perform full bidirectional sync
  Future<void> performFullSync({bool pushFirst = true}) async {
    if (_userId == null) {
      Log.w('Cannot perform sync: user not authenticated', label: _label);
      return;
    }

    try {
      Log.i('Starting full sync (push first: $pushFirst)...', label: _label);

      final db = _ref.read(databaseProvider);

      if (pushFirst) {
        // Push local changes to cloud first
        await syncWalletsToCloud();
        await syncCategoriesToCloud();
        await syncTransactionsToCloud();
        await syncBudgetsToCloud();
        await syncGoalsToCloud();
        await syncChecklistItemsToCloud(); // Push checklist items (depends on goals)
        await syncRecurringToCloud();

        // Then pull updates from cloud (in dependency order)
        await pullWalletsFromCloud();
        await pullCategoriesFromCloud();
        await pullTransactionsFromCloud(); // Pull transactions (depends on wallets and categories)
        await pullBudgetsFromCloud(); // Pull budgets (depends on wallets and categories)
        await pullRecurringFromCloud(); // Pull recurring (depends on wallets and categories)
        await pullGoalsFromCloud(); // Pull goals (no dependencies)
        await pullChecklistItemsFromCloud(); // Pull checklist items (depends on goals)
        await pullChatMessagesFromCloud(db.chatMessageDao); // Pull chat messages
      } else {
        // Pull from cloud first (in dependency order)
        await pullWalletsFromCloud();
        await pullCategoriesFromCloud();
        await pullTransactionsFromCloud(); // Pull transactions (depends on wallets and categories)
        await pullBudgetsFromCloud(); // Pull budgets (depends on wallets and categories)
        await pullRecurringFromCloud(); // Pull recurring (depends on wallets and categories)
        await pullGoalsFromCloud(); // Pull goals (no dependencies)
        await pullChecklistItemsFromCloud(); // Pull checklist items (depends on goals)
        await pullChatMessagesFromCloud(db.chatMessageDao); // Pull chat messages

        // Then push local changes
        await syncWalletsToCloud();
        await syncCategoriesToCloud();
        await syncTransactionsToCloud();
        await syncBudgetsToCloud();
        await syncGoalsToCloud();
        await syncChecklistItemsToCloud(); // Push checklist items (depends on goals)
        await syncRecurringToCloud();
      }

      Log.i('Full sync completed successfully', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error during full sync: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  // ======================================
  // REALTIME SUBSCRIPTIONS
  // ======================================

  /// Subscribe to wallet changes from Supabase
  RealtimeChannel subscribeToWallets(Function(Map<String, dynamic>) onUpdate) {
    final channel = _supabase
        .channel('wallets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'bexly',
          table: 'wallets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            Log.d('Wallet changed: ${payload.eventType}', label: _label);
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// ========================================
  /// CHAT MESSAGES SYNC
  /// ========================================

  /// Upload single chat message to Supabase
  Future<void> uploadChatMessage(ChatMessage message) async {
    if (!isAuthenticated) {
      Log.w('Cannot sync chat message: Not authenticated', label: _label);
      return;
    }

    try {
      final data = {
        'message_id': message.messageId,
        'user_id': _userId,
        'content': message.content,
        'is_from_user': message.isFromUser,
        'timestamp': message.timestamp.toIso8601String(),
        'error': message.error,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('chat_messages')
          .upsert(data, onConflict: 'message_id')
          .select()
          .single();

      Log.d('Chat message synced: ${message.messageId}', label: _label);
    } catch (e) {
      Log.e('Error uploading chat message: $e', label: _label);
      rethrow;
    }
  }

  /// Sync all chat messages to Supabase
  Future<void> syncChatMessagesToCloud(List<ChatMessage> messages) async {
    if (!isAuthenticated) {
      Log.w('Cannot sync chat messages: Not authenticated', label: _label);
      return;
    }

    Log.i('Syncing ${messages.length} chat messages...', label: _label);

    int successCount = 0;
    int errorCount = 0;

    for (final message in messages) {
      try {
        await uploadChatMessage(message);
        successCount++;
      } catch (e) {
        errorCount++;
        Log.e('Failed to sync message ${message.messageId}: $e', label: _label);
      }
    }

    Log.i('Chat sync complete: $successCount success, $errorCount errors', label: _label);
  }

  /// Pull chat messages from Supabase and insert into local DB
  Future<void> pullChatMessagesFromCloud(ChatMessageDao dao) async {
    if (!isAuthenticated) {
      Log.w('Cannot pull chat messages: Not authenticated', label: _label);
      return;
    }

    try {
      Log.i('Pulling chat messages from Supabase...', label: _label);

      if (_userId == null) {
        throw Exception('User ID is null - cannot pull chat messages');
      }

      final response = await _supabase
          .schema('bexly')
          .from('chat_messages')
          .select()
          .eq('user_id', _userId!)
          .order('timestamp', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      Log.d('Found ${data.length} chat messages on Supabase', label: _label);

      int insertedCount = 0;
      for (final item in data) {
        try {
          final companion = ChatMessagesCompanion.insert(
            messageId: item['message_id'] as String,
            content: item['content'] as String,
            isFromUser: item['is_from_user'] as bool,
            timestamp: DateTime.parse(item['timestamp'] as String),
            error: Value(item['error'] as String?),
          );

          // Use addMessageIfNotExists to avoid duplicates
          final inserted = await dao.addMessageIfNotExists(companion);
          if (inserted > 0) insertedCount++;
        } catch (e) {
          Log.e('Failed to insert chat message: $e', label: _label);
        }
      }

      Log.i('Pulled $insertedCount new chat messages', label: _label);
    } catch (e) {
      Log.e('Error pulling chat messages: $e', label: _label);
      rethrow;
    }
  }

  /// Pull budgets from Supabase
  Future<void> pullBudgetsFromCloud() async {
    if (_userId == null) {
      Log.w('Cannot pull budgets: user not authenticated', label: _label);
      return;
    }

    try {
      final response = await _supabase
          .schema('bexly')
          .from('budgets')
          .select()
          .eq('user_id', _userId!);

      final db = _ref.read(databaseProvider);
      final budgetData = (response as List);

      Log.d('Found ${budgetData.length} budgets on Supabase', label: _label);

      int processedCount = 0;

      for (final data in budgetData) {
        try {
          // Resolve wallet and category from cloudId
          final walletCloudId = data['wallet_id'];
          final categoryCloudId = data['category_id'];

          if (walletCloudId == null || categoryCloudId == null) {
            Log.w('Budget missing wallet_id or category_id, skipping', label: _label);
            continue;
          }

          final wallet = await db.walletDao.getWalletByCloudId(walletCloudId);
          final category = await db.categoryDao.getCategoryByCloudId(categoryCloudId);

          if (wallet == null || category == null) {
            Log.w('Wallet or category not found for budget, skipping', label: _label);
            continue;
          }

          final budgetModel = BudgetModel(
            cloudId: data['cloud_id'],
            wallet: wallet.toModel(),
            category: category.toModel(),
            amount: (data['amount'] as num).toDouble(),
            startDate: DateTime.parse(data['start_date']),
            endDate: DateTime.parse(data['end_date']),
            isRoutine: data['is_routine'] ?? false,
            createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
            updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
          );

          // Check if budget already exists by cloudId
          final existingBudgets = await db.budgetDao.getAllBudgets();
          final existingBudget = existingBudgets.where((b) => b.cloudId == budgetModel.cloudId).firstOrNull;

          if (existingBudget == null) {
            // Budget doesn't exist → INSERT using insertFromCloud (preserves cloudId, no re-upload)
            await db.budgetDao.insertFromCloud(budgetModel);
            processedCount++;
          } else {
            // Budget exists → UPDATE if cloud data is newer (using updateFromCloud, no re-upload)
            if (budgetModel.updatedAt != null &&
                (existingBudget.updatedAt == null || budgetModel.updatedAt!.isAfter(existingBudget.updatedAt!))) {
              Log.d('Updating existing budget with newer cloud data', label: _label);
              await db.budgetDao.updateFromCloud(budgetModel);
              processedCount++;
            } else {
              Log.d('Budget already exists and local data is newer, skipping', label: _label);
            }
          }
        } catch (e) {
          Log.e('Failed to process budget: $e', label: _label);
        }
      }

      Log.i('Pulled $processedCount new budgets', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error pulling budgets: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Pull goals from Supabase
  Future<void> pullGoalsFromCloud() async {
    if (_userId == null) {
      Log.w('Cannot pull goals: user not authenticated', label: _label);
      return;
    }

    try {
      Log.i('🔄 Starting to pull goals from Supabase...', label: _label);

      final response = await _supabase
          .schema('bexly')
          .from('goals')
          .select()
          .eq('user_id', _userId!)
          .eq('is_deleted', false); // Filter out soft-deleted goals

      final db = _ref.read(databaseProvider);
      final goalData = (response as List);

      Log.i('✅ Found ${goalData.length} goals on Supabase', label: _label);

      int processedCount = 0;

      for (final data in goalData) {
        try {
          Log.d('Processing goal: ${data['title']} (cloud_id: ${data['cloud_id']})', label: _label);

          final goalCompanion = GoalsCompanion.insert(
            cloudId: Value(data['cloud_id']),
            title: data['title'],
            description: Value(data['description'] as String?),
            targetAmount: (data['target_amount'] as num).toDouble(),
            currentAmount: Value((data['current_amount'] as num?)?.toDouble() ?? 0.0),
            startDate: Value(data['start_date'] != null ? DateTime.parse(data['start_date']) : null),
            endDate: DateTime.parse(data['end_date']),
            createdAt: Value(data['created_at'] != null ? DateTime.parse(data['created_at']) : null),
            updatedAt: Value(data['updated_at'] != null ? DateTime.parse(data['updated_at']) : DateTime.now()),
            iconName: Value(data['icon_name'] as String?),
            associatedAccountId: Value(data['associated_account_id'] as int?),
            pinned: Value(data['pinned'] as bool? ?? false),
            isDeleted: Value(data['is_deleted'] as bool? ?? false),
            deletedAt: Value(data['deleted_at'] != null ? DateTime.parse(data['deleted_at']) : null),
          );

          // Check if goal already exists by cloudId (including soft-deleted goals)
          final existingGoal = await db.goalDao.getGoalByCloudId(data['cloud_id']);

          if (existingGoal == null) {
            // Goal doesn't exist → INSERT
            Log.d('Adding new goal to local DB: ${data['title']}', label: _label);
            await db.goalDao.addGoal(goalCompanion);
            processedCount++;
          } else {
            // Goal exists → UPDATE if cloud data is newer
            final cloudUpdatedAt = data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null;

            if (cloudUpdatedAt != null && cloudUpdatedAt.isAfter(existingGoal.updatedAt)) {
              Log.d('Updating existing goal with newer cloud data: ${data['title']}', label: _label);

              // Create updated goal with existing ID
              final updatedGoal = existingGoal.copyWith(
                title: data['title'],
                description: Value(data['description'] as String?),
                targetAmount: (data['target_amount'] as num).toDouble(),
                currentAmount: (data['current_amount'] as num?)?.toDouble() ?? 0.0,
                startDate: Value(data['start_date'] != null ? DateTime.parse(data['start_date']) : null),
                endDate: DateTime.parse(data['end_date']),
                updatedAt: cloudUpdatedAt,
                iconName: Value(data['icon_name'] as String?),
                associatedAccountId: Value(data['associated_account_id'] as int?),
                pinned: Value(data['pinned'] as bool?),
                isDeleted: data['is_deleted'] as bool? ?? false,
                deletedAt: Value(data['deleted_at'] != null ? DateTime.parse(data['deleted_at']) : null),
              );

              await db.goalDao.updateGoal(updatedGoal);
              processedCount++;
            } else {
              Log.d('Goal already exists and local data is newer, skipping: ${data['title']}', label: _label);
            }
          }
        } catch (e) {
          Log.e('Failed to process goal: $e', label: _label);
        }
      }

      Log.i('✅ Pulled $processedCount new goals from Supabase', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error pulling goals: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Pull checklist items from Supabase
  Future<void> pullChecklistItemsFromCloud() async {
    if (_userId == null) {
      Log.w('Cannot pull checklist items: user not authenticated', label: _label);
      return;
    }

    try {
      Log.i('🔄 Starting to pull checklist items from Supabase...', label: _label);

      final response = await _supabase
          .schema('bexly')
          .from('checklist_items')
          .select()
          .eq('user_id', _userId!);

      final db = _ref.read(databaseProvider);
      final checklistData = (response as List);

      Log.i('✅ Found ${checklistData.length} checklist items on Supabase', label: _label);

      int processedCount = 0;

      for (final data in checklistData) {
        try {
          // Resolve goal from cloudId
          final goalCloudId = data['goal_id'];

          if (goalCloudId == null) {
            Log.w('Checklist item missing goal_id, skipping', label: _label);
            continue;
          }

          final goal = await db.goalDao.getGoalByCloudId(goalCloudId);

          if (goal == null) {
            Log.w('Goal not found for checklist item, skipping', label: _label);
            continue;
          }

          final checklistCompanion = ChecklistItemsCompanion.insert(
            cloudId: Value(data['cloud_id']),
            goalId: goal.id,
            title: data['title'],
            amount: Value(data['amount'] != null ? (data['amount'] as num).toDouble() : null),
            link: Value(data['link'] as String?),
            completed: Value(data['completed'] as bool? ?? false),
          );

          // Check if checklist item already exists by cloudId
          final existingItems = await db.checklistItemDao.getChecklistItemsForGoal(goal.id);
          final exists = existingItems.any((item) => item.cloudId == data['cloud_id']);

          if (!exists) {
            Log.d('Adding new checklist item to local DB: ${data['title']}', label: _label);
            await db.checklistItemDao.addChecklistItem(checklistCompanion);
            processedCount++;
          } else {
            Log.d('Checklist item already exists locally, skipping: ${data['title']}', label: _label);
          }
        } catch (e) {
          Log.e('Failed to process checklist item: $e', label: _label);
        }
      }

      Log.i('✅ Pulled $processedCount new checklist items from Supabase', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error pulling checklist items: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Pull recurring payments from Supabase
  Future<void> pullRecurringFromCloud() async {
    if (_userId == null) {
      Log.w('Cannot pull recurring: user not authenticated', label: _label);
      return;
    }

    try {
      final response = await _supabase
          .schema('bexly')
          .from('recurring_transactions')
          .select()
          .eq('user_id', _userId!);

      final db = _ref.read(databaseProvider);
      final recurringData = (response as List);

      Log.d('Found ${recurringData.length} recurring payments on Supabase', label: _label);

      int processedCount = 0;

      for (final data in recurringData) {
        try {
          // Resolve wallet and category from cloudId
          final walletCloudId = data['wallet_id'];
          final categoryCloudId = data['category_id'];

          if (walletCloudId == null || categoryCloudId == null) {
            Log.w('Recurring missing wallet_id or category_id, skipping', label: _label);
            continue;
          }

          final wallet = await db.walletDao.getWalletByCloudId(walletCloudId);
          final category = await db.categoryDao.getCategoryByCloudId(categoryCloudId);

          if (wallet == null || category == null) {
            Log.w('Wallet or category not found for recurring, skipping', label: _label);
            continue;
          }

          // Parse frequency and status from TEXT (not INT)
          final frequencyText = data['frequency'] as String;
          final statusText = data['status'] as String;

          final frequency = RecurringFrequency.values.firstWhere(
            (e) => e.name == frequencyText,
            orElse: () => RecurringFrequency.monthly,
          );

          final status = RecurringStatus.values.firstWhere(
            (e) => e.name == statusText,
            orElse: () => RecurringStatus.active,
          );

          final recurringModel = RecurringModel(
            cloudId: data['cloud_id'],
            name: data['title'], // Supabase uses 'title' field
            description: data['description'],
            wallet: wallet.toModel(),
            category: category.toModel(),
            amount: (data['amount'] as num).toDouble(),
            currency: data['currency'],
            startDate: DateTime.parse(data['start_date']),
            nextDueDate: DateTime.parse(data['next_due_date']),
            frequency: frequency,
            customInterval: data['custom_interval'] as int?,
            customUnit: data['custom_unit'] as String?,
            billingDay: data['billing_day'] as int?,
            endDate: data['end_date'] != null ? DateTime.parse(data['end_date']) : null,
            status: status,
            autoCreate: data['auto_create'] ?? false,
            enableReminder: data['enable_reminder'] ?? true,
            reminderDaysBefore: data['reminder_days_before'] ?? 3,
            notes: data['notes'],
            vendorName: data['vendor_name'],
            iconName: data['icon_name'],
            colorHex: data['color_hex'],
            lastChargedDate: data['last_charged_date'] != null ? DateTime.parse(data['last_charged_date']) : null,
            totalPayments: data['total_payments'] ?? 0,
            createdAt: data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
            updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
          );

          // Check if recurring already exists by cloudId
          final existingRecurrings = await db.recurringDao.getAllRecurrings();
          final existingRecurring = existingRecurrings.where((r) => r.cloudId == recurringModel.cloudId).firstOrNull;

          if (existingRecurring == null) {
            // Recurring doesn't exist → INSERT using insertFromCloud (preserves cloudId, no re-upload)
            await db.recurringDao.insertFromCloud(recurringModel);
            processedCount++;
          } else {
            // Recurring exists → ALWAYS UPDATE to fix foreign keys (wallet/category may have changed)
            // Using updateFromCloud which updates walletId/categoryId without re-uploading
            Log.d('Updating existing recurring to fix foreign keys: ${recurringModel.name}', label: _label);
            await db.recurringDao.updateFromCloud(recurringModel);
            processedCount++;
          }
        } catch (e) {
          Log.e('Failed to process recurring: $e', label: _label);
        }
      }

      Log.i('Pulled $processedCount new recurring payments', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error pulling recurring: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Subscribe to chat message changes (realtime)
  RealtimeChannel subscribeToChatMessages(Function(Map<String, dynamic>) onUpdate) {
    final channel = _supabase
        .channel('chat_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'bexly',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            Log.d('Chat message changed: ${payload.eventType}', label: _label);
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// ========================================
  /// BUDGETS SYNC
  /// ========================================

  /// Upload a single budget to Supabase (public method for DAO)
  Future<void> uploadBudget(BudgetModel budget) async {
    if (_userId == null) {
      Log.w('Cannot upload budget: user not authenticated', label: _label);
      return;
    }

    try {
      // Note: Budgets in this app are always monthly by convention
      // Users set flexible date ranges but the intent is monthly tracking
      // This matches industry standard budget apps (YNAB, Mint, etc.)
      final data = {
        'cloud_id': budget.cloudId,
        'user_id': _userId,
        'wallet_id': budget.wallet.cloudId,
        'category_id': budget.category.cloudId,
        'amount': budget.amount,
        'period': 'monthly',  // Always monthly by app convention
        'start_date': budget.startDate.toIso8601String(),
        'end_date': budget.endDate.toIso8601String(),
        'is_routine': budget.isRoutine,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('budgets')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      Log.d('Budget uploaded (${budget.cloudId})', label: _label);
    } catch (e) {
      Log.e('Error uploading budget: $e', label: _label);
      rethrow;
    }
  }

  /// Delete budget from Supabase by cloudId
  Future<void> deleteBudgetFromCloud(String cloudId) async {
    if (_userId == null) {
      Log.w('Cannot delete budget: user not authenticated', label: _label);
      return;
    }

    try {
      await _supabase
          .schema('bexly')
          .from('budgets')
          .delete()
          .eq('cloud_id', cloudId)
          .eq('user_id', _userId!);

      Log.d('Budget deleted from cloud: $cloudId', label: _label);
    } catch (e) {
      Log.e('Error deleting budget from cloud: $e', label: _label);
      rethrow;
    }
  }

  /// Delete budget from Supabase by matching fields (for budgets without cloudId)
  Future<bool> deleteBudgetFromCloudByMatch({
    required String categoryCloudId,
    required String walletCloudId,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_userId == null) {
      Log.w('Cannot delete budget: user not authenticated', label: _label);
      return false;
    }

    try {
      // Find matching budget
      final response = await _supabase
          .schema('bexly')
          .from('budgets')
          .select()
          .eq('user_id', _userId!)
          .eq('category_id', categoryCloudId)
          .eq('wallet_id', walletCloudId)
          .eq('amount', amount)
          .eq('start_date', startDate.toIso8601String())
          .eq('end_date', endDate.toIso8601String());

      if (response is List && response.isNotEmpty) {
        final cloudId = response.first['cloud_id'] as String;
        await deleteBudgetFromCloud(cloudId);
        return true;
      }

      return false;
    } catch (e) {
      Log.e('Error deleting budget by match: $e', label: _label);
      return false;
    }
  }

  /// Sync all budgets to Supabase (for manual sync button)
  Future<void> syncBudgetsToCloud() async {
    if (_userId == null) {
      Log.w('Cannot sync budgets: user not authenticated', label: _label);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      final budgets = await db.budgetDao.getAllBudgets();

      Log.d('Syncing ${budgets.length} budgets to Supabase...', label: _label);

      for (final budget in budgets) {
        try {
          // Convert Budget entity to BudgetModel
          final wallet = await db.walletDao.getWalletById(budget.walletId);
          final category = await db.categoryDao.getCategoryById(budget.categoryId);

          if (wallet == null || category == null) {
            Log.w('Skipping budget ${budget.id}: wallet or category not found', label: _label);
            continue;
          }

          final budgetModel = budget.toModel(
            category: category.toModel(),
            wallet: wallet.toModel(),
          );

          // Ensure category exists on cloud before syncing budget
          if (category.cloudId != null) {
            try {
              await uploadCategory(category.toModel(), forceUpload: true);
            } catch (e) {
              Log.w('Failed to sync category (may already exist): $e', label: _label);
            }
          }

          // Upload budget
          await uploadBudget(budgetModel);
        } catch (e) {
          Log.e('Failed to sync budget ${budget.id}: $e', label: _label);
          // Continue with next budget instead of failing entire sync
        }
      }

      Log.i('Budgets synced successfully', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error syncing budgets: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Sync all goals to Supabase
  Future<void> syncGoalsToCloud() async {
    if (_userId == null) {
      Log.w('Cannot sync goals: user not authenticated', label: _label);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      final goals = await db.goalDao.getAllGoals();

      Log.d('Syncing ${goals.length} goals to Supabase...', label: _label);

      for (final goal in goals) {
        try {
          // Convert Goal entity to GoalModel
          final goalModel = goal.toModel();

          // Upload goal
          await uploadGoal(goalModel);
        } catch (e) {
          Log.e('Failed to sync goal ${goal.id}: $e', label: _label);
          // Continue with next goal instead of failing entire sync
        }
      }

      Log.i('Goals synced successfully', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error syncing goals: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Sync all checklist items to Supabase
  Future<void> syncChecklistItemsToCloud() async {
    if (_userId == null) {
      Log.w('Cannot sync checklist items: user not authenticated', label: _label);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      final goals = await db.goalDao.getAllGoals();

      Log.d('Syncing checklist items for ${goals.length} goals to Supabase...', label: _label);

      int totalSynced = 0;

      for (final goal in goals) {
        try {
          if (goal.cloudId == null) {
            Log.w('Skipping checklist items for goal ${goal.id}: goal has no cloudId', label: _label);
            continue;
          }

          final checklistItems = await db.checklistItemDao.getChecklistItemsForGoal(goal.id);

          for (final item in checklistItems) {
            try {
              final itemModel = item.toModel();
              await uploadChecklistItem(itemModel, goal.cloudId!);
              totalSynced++;
            } catch (e) {
              Log.e('Failed to sync checklist item ${item.id}: $e', label: _label);
            }
          }
        } catch (e) {
          Log.e('Failed to sync checklist items for goal ${goal.id}: $e', label: _label);
        }
      }

      Log.i('Checklist items synced successfully: $totalSynced items', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error syncing checklist items: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// Sync all recurring payments to Supabase
  Future<void> syncRecurringToCloud() async {
    if (_userId == null) {
      Log.w('Cannot sync recurring: user not authenticated', label: _label);
      return;
    }

    try {
      final db = _ref.read(databaseProvider);
      final recurrings = await db.recurringDao.getAllRecurrings();

      Log.d('Syncing ${recurrings.length} recurring payments to Supabase...', label: _label);

      for (final recurring in recurrings) {
        try {
          // Convert Recurring entity to RecurringModel
          final wallet = await db.walletDao.getWalletById(recurring.walletId);
          final category = await db.categoryDao.getCategoryById(recurring.categoryId);

          if (wallet == null || category == null) {
            Log.w('Skipping recurring ${recurring.id}: wallet or category not found', label: _label);
            continue;
          }

          final recurringModel = recurring.toModel(
            category: category.toModel(),
            wallet: wallet.toModel(),
          );

          // Ensure category exists on cloud before syncing recurring
          if (category.cloudId != null) {
            try {
              await uploadCategory(category.toModel(), forceUpload: true);
            } catch (e) {
              Log.w('Failed to sync category (may already exist): $e', label: _label);
            }
          }

          // Upload recurring
          await uploadRecurring(recurringModel);
        } catch (e) {
          Log.e('Failed to sync recurring ${recurring.id}: $e', label: _label);
          // Continue with next recurring instead of failing entire sync
        }
      }

      Log.i('Recurring payments synced successfully', label: _label);
    } catch (e, stackTrace) {
      Log.e('Error syncing recurring: $e', label: _label);
      Log.e('Stack trace: $stackTrace', label: _label);
      rethrow;
    }
  }

  /// ========================================
  /// CHAT MESSAGE DELETE METHODS
  /// ========================================

  /// Delete chat message from Supabase by messageId
  Future<void> deleteChatMessageFromCloud(String messageId) async {
    if (_userId == null) {
      Log.w('Cannot delete chat message: user not authenticated', label: _label);
      return;
    }

    try {
      await _supabase
          .schema('bexly')
          .from('chat_messages')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', _userId!);

      Log.d('Chat message deleted from cloud: $messageId', label: _label);
    } catch (e) {
      Log.e('Error deleting chat message from cloud: $e', label: _label);
      rethrow;
    }
  }

  /// Clear all chat messages for current user
  Future<void> clearAllChatMessagesFromCloud() async {
    if (_userId == null) {
      Log.w('Cannot clear chat messages: user not authenticated', label: _label);
      return;
    }

    try {
      await _supabase
          .schema('bexly')
          .from('chat_messages')
          .delete()
          .eq('user_id', _userId!);

      Log.d('All chat messages cleared from cloud', label: _label);
    } catch (e) {
      Log.e('Error clearing chat messages from cloud: $e', label: _label);
      rethrow;
    }
  }

  /// ========================================
  /// GOAL SYNC METHODS
  /// ========================================

  /// Upload a single goal to Supabase (public method for DAO)
  Future<void> uploadGoal(GoalModel goal) async {
    if (_userId == null) {
      Log.w('Cannot upload goal: user not authenticated', label: _label);
      return;
    }

    try {
      final data = {
        'cloud_id': goal.cloudId,
        'user_id': _userId,
        'title': goal.title,
        'description': goal.description,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'start_date': goal.startDate?.toIso8601String(),
        'end_date': goal.endDate.toIso8601String(),
        'created_at': goal.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'icon_name': goal.iconName,
        'associated_account_id': goal.associatedAccountId,
        'pinned': goal.pinned,
        'is_deleted': goal.isDeleted,
        'deleted_at': goal.deletedAt?.toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('goals')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      Log.d('Goal uploaded (${goal.cloudId})', label: _label);
    } catch (e) {
      Log.e('Error uploading goal: $e', label: _label);
      rethrow;
    }
  }

  /// Delete a goal from Supabase by cloud ID
  Future<void> deleteGoalFromCloud(String cloudId) async {
    if (_userId == null) {
      Log.w('Cannot delete goal: user not authenticated', label: _label);
      return;
    }

    try {
      // HARD DELETE - completely remove from cloud
      // Local uses soft delete (Tombstone) for instant UX, cloud uses hard delete
      await _supabase
          .schema('bexly')
          .from('goals')
          .delete()
          .eq('cloud_id', cloudId)
          .eq('user_id', _userId!);

      Log.d('Goal HARD deleted from cloud: $cloudId', label: _label);
    } catch (e) {
      Log.e('Error deleting goal from cloud: $e', label: _label);
      rethrow;
    }
  }

  /// ========================================
  /// CHECKLIST ITEM SYNC METHODS
  /// ========================================

  /// Upload a single checklist item to Supabase
  Future<void> uploadChecklistItem(ChecklistItemModel item, String goalCloudId) async {
    if (_userId == null) {
      Log.w('Cannot upload checklist item: user not authenticated', label: _label);
      return;
    }

    try {
      final data = {
        'cloud_id': item.cloudId,
        'user_id': _userId,
        'goal_id': goalCloudId,
        'title': item.title,
        'amount': item.amount,
        'link': item.link,
        'completed': item.completed,
      };

      await _supabase
          .schema('bexly')
          .from('checklist_items')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      Log.d('Checklist item uploaded (${item.cloudId})', label: _label);
    } catch (e) {
      Log.e('Error uploading checklist item: $e', label: _label);
      rethrow;
    }
  }

  /// Delete a checklist item from Supabase by cloud ID
  Future<void> deleteChecklistItemFromCloud(String cloudId) async {
    if (_userId == null) {
      Log.w('Cannot delete checklist item: user not authenticated', label: _label);
      return;
    }

    try {
      await _supabase
          .schema('bexly')
          .from('checklist_items')
          .delete()
          .eq('cloud_id', cloudId)
          .eq('user_id', _userId!);

      Log.d('Checklist item deleted from cloud: $cloudId', label: _label);
    } catch (e) {
      Log.e('Error deleting checklist item from cloud: $e', label: _label);
      rethrow;
    }
  }

  // ======================================
  // RECURRING PAYMENT SYNC
  // ======================================

  /// Upload recurring payment to Supabase
  Future<void> uploadRecurring(dynamic recurring) async {
    if (_userId == null) {
      Log.w('Cannot upload recurring: user not authenticated', label: _label);
      return;
    }

    try {
      // Ensure wallet has cloudId
      String? walletCloudId = recurring.wallet.cloudId;
      if (walletCloudId == null) {
        Log.w('⚠️ Wallet has no cloudId, auto-assigning...', label: _label);
        walletCloudId = const Uuid().v7();
        final db = _ref.read(databaseProvider);

        if (recurring.wallet.id != null) {
          await (db.update(db.wallets)..where((t) => t.id.equals(recurring.wallet.id!)))
              .write(WalletsCompanion(cloudId: Value(walletCloudId)));

          final updatedWallet = await db.walletDao.getWalletById(recurring.wallet.id!);
          if (updatedWallet != null) {
            await uploadWallet(updatedWallet.toModel());
          }
        }
      }

      // Ensure recurring has cloudId
      String? recurringCloudId = recurring.cloudId;
      if (recurringCloudId == null) {
        Log.w('⚠️ Recurring has no cloudId, auto-assigning...', label: _label);
        recurringCloudId = const Uuid().v7();
        final db = _ref.read(databaseProvider);

        if (recurring.id != null) {
          await (db.update(db.recurrings)..where((t) => t.id.equals(recurring.id!)))
              .write(RecurringsCompanion(cloudId: Value(recurringCloudId)));
        }
      }

      // Ensure category has cloudId
      String? categoryCloudId = recurring.category.cloudId;
      if (categoryCloudId == null) {
        Log.w('⚠️ Category has no cloudId, auto-assigning...', label: _label);
        categoryCloudId = const Uuid().v7();
        final db = _ref.read(databaseProvider);

        if (recurring.category.id != null) {
          await (db.update(db.categories)..where((t) => t.id.equals(recurring.category.id!)))
              .write(CategoriesCompanion(cloudId: Value(categoryCloudId)));

          // Force upload category directly (bypass skip logic for built-in categories)
          // Match exact schema from uploadCategory() function
          final categoryData = {
            'cloud_id': categoryCloudId,
            'user_id': _userId,
            'name': recurring.category.title,  // Supabase uses 'name' column, not 'title'
            'icon': recurring.category.icon,
            'icon_background': recurring.category.iconBackground,
            'icon_type': recurring.category.iconTypeValue,
            'parent_id': null,  // TODO: Parent categories not supported yet in Supabase
            'description': recurring.category.description,
            'localized_titles': recurring.category.localizedTitles,
            'is_system_default': recurring.category.isSystemDefault,
            'source': recurring.category.source ?? 'built-in',
            'built_in_id': recurring.category.builtInId,
            'has_been_modified': recurring.category.hasBeenModified ?? false,
            'is_deleted': recurring.category.isDeleted ?? false,
            'category_type': recurring.category.transactionType,
            'updated_at': DateTime.now().toIso8601String(),
          };

          await _supabase
              .schema('bexly')
              .from('categories')
              .upsert(categoryData, onConflict: 'cloud_id')
              .select()
              .single();

          Log.d('Category ${recurring.category.title} force-uploaded for recurring', label: _label);
        }
      }

      final data = {
        'cloud_id': recurringCloudId,  // Use the generated or existing cloudId
        'user_id': _userId,
        'wallet_id': walletCloudId,
        'category_id': categoryCloudId,
        'title': recurring.name,  // Supabase uses 'title' instead of 'name'
        'description': recurring.description,
        'amount': recurring.amount,
        'currency': recurring.currency,
        'transaction_type': 'expense',  // Recurring payments are always expenses
        'start_date': recurring.startDate.toIso8601String(),
        'next_due_date': recurring.nextDueDate.toIso8601String(),
        'frequency': recurring.frequency.toString().split('.').last, // enum to string
        'custom_interval': recurring.customInterval,
        'custom_unit': recurring.customUnit,
        'billing_day': recurring.billingDay,
        'end_date': recurring.endDate?.toIso8601String(),
        'status': recurring.status.toString().split('.').last, // enum to string
        'auto_create': recurring.autoCreate,
        'enable_reminder': recurring.enableReminder,
        'reminder_days_before': recurring.reminderDaysBefore,
        'notes': recurring.notes,
        'vendor_name': recurring.vendorName,
        'icon_name': recurring.iconName,
        'color_hex': recurring.colorHex,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .schema('bexly')
          .from('recurring_transactions')
          .upsert(data, onConflict: 'cloud_id')
          .select()
          .single();

      Log.d('Recurring ${recurring.name} uploaded (${recurring.cloudId})', label: _label);
    } catch (e) {
      Log.e('Error uploading recurring ${recurring.name}: $e', label: _label);
      rethrow;
    }
  }

  /// Delete a recurring payment from Supabase by cloud ID
  Future<void> deleteRecurringFromCloud(String cloudId) async {
    if (_userId == null) {
      Log.w('Cannot delete recurring: user not authenticated', label: _label);
      return;
    }

    try {
      await _supabase
          .schema('bexly')
          .from('recurring_transactions')
          .delete()
          .eq('cloud_id', cloudId)
          .eq('user_id', _userId!);

      Log.d('Recurring deleted from cloud: $cloudId', label: _label);
    } catch (e) {
      Log.e('Error deleting recurring from cloud: $e', label: _label);
      rethrow;
    }
  }
}
