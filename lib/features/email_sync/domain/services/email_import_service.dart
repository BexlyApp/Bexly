import 'package:drift/drift.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/daos/parsed_email_transaction_dao.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';

/// Service to import approved parsed email transactions into the main transactions table
class EmailImportService {
  static const _label = 'EmailImport';

  final AppDatabase _db;

  EmailImportService(this._db);

  /// Import a single approved transaction into the main transactions table
  /// Returns the ID of the created transaction, or null if import failed
  Future<int?> importTransaction(ParsedEmailTransaction parsedTx) async {
    try {
      // Validate the parsed transaction has required data
      if (parsedTx.targetWalletId == null) {
        Log.e('Cannot import transaction ${parsedTx.id}: no target wallet', label: _label);
        return null;
      }

      // Convert transaction type string to TransactionType enum
      final transactionType = parsedTx.transactionType == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      // Get or create a default category (use selectedCategoryId if available)
      int categoryId;
      if (parsedTx.selectedCategoryId != null) {
        categoryId = parsedTx.selectedCategoryId!;
      } else {
        // Find a default category based on transaction type
        categoryId = await _getDefaultCategoryId(transactionType);
      }

      // Build transaction title from merchant or email subject
      final title = parsedTx.merchant ?? parsedTx.emailSubject;

      // Create the transaction companion for insertion
      final txCompanion = TransactionsCompanion.insert(
        transactionType: transactionType.index,
        amount: parsedTx.amount,
        date: parsedTx.transactionDate,
        title: title.length > 255 ? title.substring(0, 255) : title,
        categoryId: categoryId,
        walletId: parsedTx.targetWalletId!,
        notes: Value(_buildNotes(parsedTx)),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );

      // Insert the transaction
      final txId = await _db.into(_db.transactions).insert(txCompanion);
      Log.i('Imported transaction $txId from parsed email ${parsedTx.id}', label: _label);

      // Mark the parsed transaction as imported
      await _db.parsedEmailTransactionDao.markAsImported(parsedTx.id, txId);

      // Update wallet balance
      await _updateWalletBalance(
        parsedTx.targetWalletId!,
        parsedTx.amount,
        transactionType,
      );

      return txId;
    } catch (e, stack) {
      Log.e('Failed to import transaction ${parsedTx.id}: $e', label: _label);
      Log.e('Stack: $stack', label: _label);
      return null;
    }
  }

  /// Import all approved transactions
  /// Returns ImportResult with counts of successful and failed imports
  Future<ImportResult> importAllApproved() async {
    final approved = await _db.parsedEmailTransactionDao
        .getByStatus(ParsedEmailTransactionStatus.approved);

    Log.i('Importing ${approved.length} approved transactions', label: _label);

    int successCount = 0;
    int failedCount = 0;

    for (final tx in approved) {
      final result = await importTransaction(tx);
      if (result != null) {
        successCount++;
      } else {
        failedCount++;
      }
    }

    Log.i('Import complete: $successCount succeeded, $failedCount failed', label: _label);

    return ImportResult(
      totalProcessed: approved.length,
      successCount: successCount,
      failedCount: failedCount,
    );
  }

  /// Get default category ID based on transaction type
  Future<int> _getDefaultCategoryId(TransactionType type) async {
    // Try to find "Other" or "Uncategorized" category
    final categories = await _db.select(_db.categories).get();

    // Look for common default category names
    final defaultNames = ['Other', 'Khác', 'Uncategorized', 'General', 'Chung'];

    for (final name in defaultNames) {
      final found = categories.where(
        (c) => c.title.toLowerCase() == name.toLowerCase() && c.parentId == null,
      );
      if (found.isNotEmpty) {
        return found.first.id;
      }
    }

    // If no default found, just use the first category of the appropriate type
    // For income, look for categories like "Salary", "Income", etc.
    if (type == TransactionType.income) {
      final incomeNames = ['Salary', 'Lương', 'Income', 'Thu nhập'];
      for (final name in incomeNames) {
        final found = categories.where(
          (c) => c.title.toLowerCase().contains(name.toLowerCase()),
        );
        if (found.isNotEmpty) {
          return found.first.id;
        }
      }
    }

    // Fallback to first category
    if (categories.isNotEmpty) {
      return categories.first.id;
    }

    throw Exception('No categories found in database');
  }

  /// Build notes from parsed transaction data
  String _buildNotes(ParsedEmailTransaction tx) {
    final parts = <String>[];

    parts.add('Imported from email');
    parts.add('Bank: ${tx.bankName}');

    if (tx.accountLast4 != null) {
      parts.add('Account: ****${tx.accountLast4}');
    }

    if (tx.balanceAfter != null) {
      parts.add('Balance after: ${tx.balanceAfter}');
    }

    if (tx.rawAmountText.isNotEmpty) {
      parts.add('Original: ${tx.rawAmountText}');
    }

    if (tx.userNotes != null && tx.userNotes!.isNotEmpty) {
      parts.add('Note: ${tx.userNotes}');
    }

    return parts.join('\n');
  }

  /// Update wallet balance after importing transaction
  Future<void> _updateWalletBalance(
    int walletId,
    double amount,
    TransactionType type,
  ) async {
    final wallet = await _db.walletDao.getWalletById(walletId);
    if (wallet == null) return;

    double newBalance = wallet.balance;
    if (type == TransactionType.income) {
      newBalance += amount;
    } else if (type == TransactionType.expense) {
      newBalance -= amount;
    }

    await (_db.update(_db.wallets)..where((w) => w.id.equals(walletId)))
        .write(WalletsCompanion(balance: Value(newBalance)));

    Log.d('Updated wallet $walletId balance: ${wallet.balance} -> $newBalance', label: _label);
  }
}

/// Result of import operation
class ImportResult {
  final int totalProcessed;
  final int successCount;
  final int failedCount;

  const ImportResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failedCount,
  });
}
