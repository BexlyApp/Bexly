import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/reports/presentation/screens/basic_monthly_report_screen.dart';

/// Provider for monthly transactions with optional wallet filter (for reports)
final monthlyTransactionsProvider =
    StreamProvider.family<List<TransactionModel>, DateTime>((ref, date) {
      final db = ref.watch(databaseProvider);
      final selectedWalletId = ref.watch(reportWalletFilterProvider);

      // Watch ALL transactions from ALL wallets with category & wallet details
      return db.transactionDao.watchAllTransactionsWithDetails().map((transactions) {
        // Filter by month
        var filtered = transactions.where((t) {
          return t.date.year == date.year && t.date.month == date.month;
        });

        // Filter by wallet if selected
        if (selectedWalletId != null) {
          filtered = filtered.where((t) => t.wallet.id == selectedWalletId);
        }

        return filtered.toList();
      });
    });
