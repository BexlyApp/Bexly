part of '../screens/dashboard_screen.dart';

class RecentTransactionList extends ConsumerWidget {
  // Changed to ConsumerWidget
  const RecentTransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef
    final asyncTransactions = ref.watch(allTransactionsProvider);

    return asyncTransactions.when(
      data: (allTransactions) {
        if (allTransactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.recentTransactions,
                  style: AppTextStyles.heading6,
                ),
                const Gap(AppSpacing.spacing16),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.spacing20,
                    ),
                    child: Text(
                      context.l10n.noTransactionsYet,
                      style: AppTextStyles.body3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        // Sort transactions by date to get the most recent ones, then take the top 5 (or fewer if not enough)
        final List<TransactionModel> recentTransactions = List.from(
          allTransactions,
        )..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
        final List<TransactionModel> displayTransactions = recentTransactions
            .take(5)
            .toList();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.recentTransactions, style: AppTextStyles.heading6),
              const Gap(AppSpacing.spacing16),
              ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.spacing20,
                ), // Adjusted bottom padding
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = displayTransactions[index];
                  return TransactionTile(transaction: transaction);
                },
                separatorBuilder: (context, index) =>
                    const Gap(AppSpacing.spacing12),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Consumer(
        builder: (context, ref, child) {
          return Center(child: Text(context.l10n.errorLoading));
        },
      ),
    );
  }
}
