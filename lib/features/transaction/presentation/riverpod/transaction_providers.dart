import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/transaction/data/model/transaction_filter_model.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart'; // Import activeWalletProvider

/// Emits a new list of transactions for the currently active wallet.
final transactionListProvider =
    StreamProvider.autoDispose<List<TransactionModel>>((ref) {
      final db = ref.watch(databaseProvider);
      final activeWalletAsync = ref.watch(activeWalletProvider);
      final filter = ref.watch(transactionFilterProvider);

      return activeWalletAsync.when(
        data: (activeWallet) {
          if (activeWallet == null || activeWallet.id == null) {
            return Stream.value([]);
          }
          // Use the new filtered DAO method
          return db.transactionDao.watchFilteredTransactionsWithDetails(
            walletId: activeWallet.id!,
            filter: filter,
          );
        },
        loading: () => Stream.value([]),
        error: (e, s) => Stream.error(e, s),
      );
    });

final transactionDetailsProvider = StreamProvider.autoDispose.family<TransactionModel?, int>((
  ref,
  id,
) {
  final db = ref.watch(databaseProvider);
  // This provider fetches a single transaction. It might not need to be wallet-specific,
  // as you're fetching by a unique transaction ID.
  // The DAO's watchTransactionByID returns a Transaction table object.
  // We need a DAO method that returns TransactionModel with details for a specific ID.
  // Let's assume TransactionDao will have watchTransactionDetailsById(id) -> Stream<TransactionModel?>
  // For now, this will likely break or need adjustment in TransactionDao.
  // The current watchTransactionByID in DAO returns `Stream<Transaction>` (table object).
  // It should ideally return `Stream<TransactionModel>` by joining with category/wallet.
  //
  // A quick fix for now might be to use a more general fetch if the DAO isn't updated:
  // return db.transactionDao.watchAllTransactionsWithDetails().map((list) => list.firstWhere((tx) => tx.id == id, orElse: () => null));
  // This is inefficient. The DAO should provide a direct method.
  //
  // Assuming TransactionDao is updated to have:
  // Stream<TransactionModel?> watchTransactionDetailsById(int transactionId)
  // For now, this provider will be left as is, but it highlights a need for DAO improvement.
  // The current `transactionDetailsProvider` in the context uses `watchTransactionByID` which returns `Transaction` (table object)
  // and then tries to map it. This mapping needs category and wallet.
  //
  // The most straightforward way is to make `transactionDetailsProvider` use `watchAllTransactionsWithDetails`
  // and filter, or add a specific DAO method.
  // Let's assume `watchAllTransactionsWithDetails` is efficient enough for now for finding one item.
  return db.transactionDao.watchAllTransactionsWithDetails().map(
    (transactions) => transactions.firstWhere((tx) => tx.id == id),
  );
});

/// Notifier to request switching to a specific tab in TransactionScreen.
class RequestedTransactionTabNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void request(int tab) => state = tab;
  void clear() => state = null;
}

/// Tracks the currently active tab in TransactionScreen (0=ThisMonth, 1=LastMonth, 2=Pending)
class ActiveTransactionTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int tab) => state = tab;
}

final activeTransactionTabProvider = NotifierProvider<ActiveTransactionTabNotifier, int>(
  ActiveTransactionTabNotifier.new,
);

/// Provider to request switching to a specific tab in TransactionScreen.
/// Set to tab index (e.g., 2 for Pending), null means no request.
final requestedTransactionTabProvider =
    NotifierProvider<RequestedTransactionTabNotifier, int?>(
  RequestedTransactionTabNotifier.new,
);

class TransactionFilterNotifier extends Notifier<TransactionFilter?> {
  @override
  TransactionFilter? build() => null;

  void setFilter(TransactionFilter? filter) => state = filter;

  void clearFilter() => state = null;
}

final transactionFilterProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilter?>(
  TransactionFilterNotifier.new,
);

/// Provider for dashboard/transaction screen - returns ALL transactions across all wallets
/// with optional filtering
final allTransactionsProvider = StreamProvider.autoDispose<List<TransactionModel>>((ref) {
  final db = ref.watch(databaseProvider);
  final filter = ref.watch(transactionFilterProvider);

  final allTransactionsStream = db.transactionDao.watchAllTransactionsWithDetails();

  // If no filter, return all transactions
  if (filter == null) {
    return allTransactionsStream;
  }

  // Apply filter manually since DAO doesn't have filtered method for all wallets
  return allTransactionsStream.map((transactions) {
    return transactions.where((transaction) {
      // Filter by transaction type
      if (filter.transactionType != null &&
          transaction.transactionType != filter.transactionType) {
        return false;
      }

      // Filter by category (including subcategories)
      if (filter.category != null) {
        final parentId = filter.category!.id!;
        final subIds = filter.category!.subCategories?.map((e) => e.id!).toList() ?? [];
        final allCategoryIds = [parentId, ...subIds];
        if (!allCategoryIds.contains(transaction.category.id)) {
          return false;
        }
      }

      // Filter by min amount
      if (filter.minAmount != null && transaction.amount < filter.minAmount!) {
        return false;
      }

      // Filter by max amount
      if (filter.maxAmount != null && transaction.amount > filter.maxAmount!) {
        return false;
      }

      // Filter by keyword (search in title/notes)
      if (filter.keyword != null && filter.keyword!.isNotEmpty) {
        final keyword = filter.keyword!.toLowerCase();
        final matchesTitle = transaction.title.toLowerCase().contains(keyword);
        final matchesNotes = transaction.notes?.toLowerCase().contains(keyword) ?? false;
        if (!matchesTitle && !matchesNotes) {
          return false;
        }
      }

      // Filter by date range
      if (filter.dateStart != null) {
        if (transaction.date.isBefore(filter.dateStart!)) {
          return false;
        }
      }
      if (filter.dateEnd != null) {
        if (transaction.date.isAfter(filter.dateEnd!)) {
          return false;
        }
      }

      // Filter by wallet
      if (filter.wallet != null && transaction.wallet.id != filter.wallet!.id) {
        return false;
      }

      return true;
    }).toList();
  });
});
