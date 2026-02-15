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
import 'package:bexly/features/pending_transactions/presentation/components/pending_transaction_grouped_list.dart';
import 'package:bexly/features/pending_transactions/presentation/screens/approve_transaction_sheet.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTransactionsAsyncValue = ref.watch(allTransactionsProvider);
    final isFilterActive = ref.watch(transactionFilterProvider);
    final pendingCountAsync = ref.watch(pendingTransactionCountProvider);
    final pendingTransactionsAsync = ref.watch(allPendingTransactionsProvider);
    final activeTab = ref.watch(activeTransactionTabProvider);
    final pendingCount = pendingCountAsync.asData?.value ?? 0;
    final isPendingTab = activeTab == 2 && pendingCount > 0;

    return CustomScaffold(
      context: context,
      showBackButton: false,
      showBalance: false,
      title: context.l10n.myTransactions,
      actions: [
        if (isPendingTab)
          CustomIconButton(
            context,
            onPressed: () => _showBulkActionsSheet(
              context, ref, pendingCount, pendingTransactionsAsync,
            ),
            icon: HugeIcons.strokeRoundedCheckList as dynamic,
            themeMode: context.themeMode,
          ),
        if (isPendingTab) const Gap(AppSpacing.spacing8),
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

          // Read initial tab request (no subscription, avoids rebuild)
          final initialTab = ref.read(requestedTransactionTabProvider) ?? 0;

          return DefaultTabController(
            length: 3, // This Month, Last Month, Pending
            initialIndex: initialTab,
            child: _TabRequestHandler(
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
                  context.l10n.allCaughtUp,
                  style: AppTextStyles.heading3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Gap(AppSpacing.spacing8),
                Text(
                  context.l10n.noPendingToReview,
                  style: AppTextStyles.body3.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return PendingTransactionGroupedList(
          pendingTransactions: pending,
          onApprove: (item) => ApproveTransactionSheet.show(context, item),
          onReject: (item) => _rejectTransaction(context, ref, item),
          onTap: (item) => ApproveTransactionSheet.show(context, item),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _showBulkActionsSheet(
    BuildContext context,
    WidgetRef ref,
    int count,
    AsyncValue<List<PendingTransactionModel>> pendingTransactionsAsync,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing24,
          0,
          AppSpacing.spacing24,
          AppSpacing.spacing32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.bulkActions,
              style: AppTextStyles.heading3,
            ),
            const Gap(AppSpacing.spacing8),
            Text(
              context.l10n.countPendingTransactions(count),
              style: AppTextStyles.body2,
            ),
            const Gap(AppSpacing.spacing24),
            // Accept All button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _confirmAcceptAll(context, ref, count, pendingTransactionsAsync);
                },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text(context.l10n.acceptAll),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(sheetContext).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const Gap(AppSpacing.spacing12),
            // Reject All button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _confirmRejectAll(context, ref, count);
                },
                icon: Icon(Icons.cancel_outlined, size: 20, color: AppColors.red400),
                label: Text(context.l10n.rejectAll, style: TextStyle(color: AppColors.red400)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.red400.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAcceptAll(
    BuildContext context,
    WidgetRef ref,
    int count,
    AsyncValue<List<PendingTransactionModel>> pendingTransactionsAsync,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing24, 0, AppSpacing.spacing24, AppSpacing.spacing32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.acceptAllConfirm, style: AppTextStyles.heading3),
            const Gap(AppSpacing.spacing8),
            Text(
              context.l10n.acceptAllDescription,
              style: AppTextStyles.body2,
            ),
            const Gap(AppSpacing.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const Gap(AppSpacing.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.acceptAll),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final pendingItems = pendingTransactionsAsync.asData?.value ?? [];
      final defaultWalletId = ref.read(defaultWalletIdProvider) ?? 1;
      final approved = await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .approveAll(pendingItems, defaultWalletId: defaultWalletId);

      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text(context.l10n.transactionsImportedCount(approved)),
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _confirmRejectAll(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing24, 0, AppSpacing.spacing24, AppSpacing.spacing32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.rejectAllConfirm, style: AppTextStyles.heading3),
            const Gap(AppSpacing.spacing8),
            Text(
              context.l10n.rejectAllDescription,
              style: AppTextStyles.body2,
            ),
            const Gap(AppSpacing.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const Gap(AppSpacing.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red400,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.l10n.rejectAll),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final rejected = await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .rejectAll();

      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.info,
          title: Text(context.l10n.transactionsRejectedCount(rejected)),
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    }
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
        title: Text(context.l10n.transactionRejected),
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }
}

/// Handles tab navigation requests from other screens (e.g., email sync).
/// Must be placed inside a DefaultTabController subtree.
class _TabRequestHandler extends ConsumerStatefulWidget {
  final Widget child;

  const _TabRequestHandler({required this.child});

  @override
  ConsumerState<_TabRequestHandler> createState() => _TabRequestHandlerState();
}

class _TabRequestHandlerState extends ConsumerState<_TabRequestHandler> {
  TabController? _tabController;

  void _onTabChanged() {
    if (_tabController != null) {
      ref.read(activeTransactionTabProvider.notifier).set(_tabController!.index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController?.removeListener(_onTabChanged);
    _tabController = DefaultTabController.of(context);
    _tabController?.addListener(_onTabChanged);
    // Delay to avoid modifying provider during build
    if (_tabController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(activeTransactionTabProvider.notifier).set(_tabController!.index);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for future tab change requests
    ref.listen<int?>(requestedTransactionTabProvider, (prev, next) {
      if (next != null) {
        DefaultTabController.of(context).animateTo(next);
        ref.read(requestedTransactionTabProvider.notifier).clear();
      }
    });

    // Handle initial request when screen first builds
    final initialRequest = ref.read(requestedTransactionTabProvider);
    if (initialRequest != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          DefaultTabController.of(context).animateTo(initialRequest);
        }
        ref.read(requestedTransactionTabProvider.notifier).clear();
      });
    }

    return widget.child;
  }
}
