import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/components/buttons/custom_icon_button.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/main/presentation/components/transaction_options_menu.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/components/transaction_grouped_card.dart';
import 'package:bexly/features/transaction/presentation/components/transaction_summary_card.dart';
import 'package:bexly/features/transaction/presentation/components/transaction_tab_bar.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/transaction/presentation/screens/transaction_filter_form_dialog.dart';
import 'package:bexly/features/pending_transactions/riverpod/pending_transaction_provider.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';
import 'package:bexly/features/pending_transactions/presentation/components/pending_transaction_tile.dart';
import 'package:bexly/features/pending_transactions/presentation/screens/approve_transaction_sheet.dart';

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTransactionsAsyncValue = ref.watch(allTransactionsProvider);
    final isFilterActive = ref.watch(transactionFilterProvider);
    final pendingCountAsync = ref.watch(pendingTransactionCountProvider);
    final pendingTransactionsAsync = ref.watch(allPendingTransactionsProvider);

    return CustomScaffold(
      context: context,
      showBackButton: false,
      showBalance: false,
      title: context.l10n.myTransactions,
      actions: [
        CustomIconButton(
          context,
          onPressed: () {
            final currentFilter = ref.read(transactionFilterProvider);
            context.openBottomSheet(
              child: TransactionFilterFormDialog(initialFilter: currentFilter),
            );
          },
          icon: HugeIcons.strokeRoundedFilter as dynamic,
          showBadge: isFilterActive != null,
          themeMode: context.themeMode,
        ),
      ],
      // Hide FAB on desktop - use sidebar button instead
      floatingActionButton: context.isDesktopLayout
          ? null
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const TransactionOptionsMenu(),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedPlusSign as dynamic,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
      body: allTransactionsAsyncValue.when(
        data: (allTransactions) {
          // Get pending count for tab badge
          final pendingCount = pendingCountAsync.asData?.value ?? 0;

          // Define this month and last month dates
          final now = DateTime.now();
          final thisMonthDate = DateTime(now.year, now.month, 1);
          final lastMonthDate = DateTime(now.year, now.month - 1, 1);

          // Filter transactions for this month
          final thisMonthTransactions = _filterAndDeduplicateTransactions(
            allTransactions,
            thisMonthDate,
          );

          // Filter transactions for last month
          final lastMonthTransactions = _filterAndDeduplicateTransactions(
            allTransactions,
            lastMonthDate,
          );

          return DefaultTabController(
            length: 3, // This Month, Last Month, Pending
            initialIndex: 0, // Start on This Month
            child: Column(
              children: [
                TransactionTabBar(pendingCount: pendingCount),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: This Month
                      _buildMonthTab(context, thisMonthTransactions),
                      // Tab 2: Last Month
                      _buildMonthTab(context, lastMonthTransactions),
                      // Tab 3: Pending
                      _buildPendingTabContent(context, ref, pendingTransactionsAsync),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }

  /// Filter transactions for a specific month and deduplicate
  List<TransactionModel> _filterAndDeduplicateTransactions(
    List<TransactionModel> allTransactions,
    DateTime monthDate,
  ) {
    final transactionsForMonth = allTransactions.where((t) {
      return t.date.year == monthDate.year && t.date.month == monthDate.month;
    }).toList();

    // Deduplicate by cloudId or id
    final seenKeys = <String>{};
    final uniqueTransactions = <TransactionModel>[];
    for (final transaction in transactionsForMonth) {
      final key = transaction.cloudId != null
          ? 'cloud_${transaction.cloudId}'
          : (transaction.id != null
              ? 'id_${transaction.id}'
              : '${transaction.title}_${transaction.amount}_${transaction.date.millisecondsSinceEpoch}_${transaction.wallet.id}');

      if (!seenKeys.contains(key)) {
        seenKeys.add(key);
        uniqueTransactions.add(transaction);
      }
    }

    return uniqueTransactions;
  }

  /// Build month tab content
  Widget _buildMonthTab(BuildContext context, List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Center(child: Text(context.l10n.noTransactionsForMonth));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        TransactionSummaryCard(transactions: transactions),
        const Gap(AppSpacing.spacing20),
        TransactionGroupedCard(transactions: transactions),
      ],
    );
  }

  Widget _buildPendingTabContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<PendingTransactionModel>> pendingAsync,
  ) {
    return pendingAsync.when(
      data: (pending) {
        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: AppColors.green200,
                  size: 64,
                ),
                const Gap(AppSpacing.spacing16),
                Text(
                  'All caught up!',
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Gap(AppSpacing.spacing8),
                Text(
                  'No pending transactions to review',
                  style: AppTextStyles.body3.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          itemCount: pending.length,
          separatorBuilder: (_, __) => const Gap(AppSpacing.spacing12),
          itemBuilder: (context, index) {
            final item = pending[index];
            return PendingTransactionTile(
              pending: item,
              onApprove: () => ApproveTransactionSheet.show(context, item),
              onReject: () => _rejectTransaction(context, ref, item),
              onTap: () => ApproveTransactionSheet.show(context, item),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Future<void> _rejectTransaction(
    BuildContext context,
    WidgetRef ref,
    PendingTransactionModel item,
  ) async {
    final success = await ref
        .read(pendingTransactionNotifierProvider.notifier)
        .reject(item.id!);

    if (context.mounted && success) {
      toastification.show(
        context: context,
        type: ToastificationType.info,
        title: const Text('Transaction rejected'),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }
}
