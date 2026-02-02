import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';
import 'package:bexly/features/pending_transactions/presentation/components/pending_transaction_tile.dart';
import 'package:bexly/features/pending_transactions/riverpod/pending_transaction_provider.dart';
import 'package:bexly/features/pending_transactions/presentation/screens/approve_transaction_sheet.dart';

/// Bottom sheet showing all pending transactions
class PendingTransactionsSheet extends ConsumerWidget {
  final ScrollController? scrollController;

  const PendingTransactionsSheet({super.key, this.scrollController});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => PendingTransactionsSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(allPendingTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Handle bar
        const Gap(AppSpacing.spacing12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? AppColors.neutral600 : AppColors.neutral300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const Gap(AppSpacing.spacing16),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
          child: Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedInbox,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const Gap(AppSpacing.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Transactions',
                      style: AppTextStyles.heading3.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Review and import transactions',
                      style: AppTextStyles.body4.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        const Gap(AppSpacing.spacing16),
        Divider(
          height: 1,
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),

        // Content
        Expanded(
          child: pendingAsync.when(
            data: (pending) {
              if (pending.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                itemCount: pending.length,
                separatorBuilder: (_, __) => const Gap(AppSpacing.spacing12),
                itemBuilder: (context, index) {
                  final item = pending[index];
                  return PendingTransactionTile(
                    pending: item,
                    onApprove: () => _showApproveSheet(context, ref, item),
                    onReject: () => _rejectTransaction(context, ref, item),
                    onTap: () => _showApproveSheet(context, ref, item),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  void _showApproveSheet(
    BuildContext context,
    WidgetRef ref,
    PendingTransactionModel item,
  ) {
    ApproveTransactionSheet.show(context, item);
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
