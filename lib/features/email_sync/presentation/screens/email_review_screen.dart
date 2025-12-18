import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/email_sync/riverpod/email_scan_provider.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

/// Screen for reviewing and approving parsed email transactions
class EmailReviewScreen extends HookConsumerWidget {
  const EmailReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _approveAll(context, ref, db),
            icon: const Icon(Icons.done_all),
            label: const Text('Approve All'),
          ),
        ],
      ),
      body: StreamBuilder<List<ParsedEmailTransaction>>(
        stream: db.parsedEmailTransactionDao.watchPendingReview(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _TransactionReviewCard(
                transaction: tx,
                onApprove: () => _approveSingle(context, ref, db, tx),
                onReject: () => _rejectSingle(context, db, tx),
                onEdit: () => _editTransaction(context, tx),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.neutral400,
          ),
          const Gap(AppSpacing.spacing16),
          Text(
            'No transactions to review',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const Gap(AppSpacing.spacing8),
          Text(
            'Scan your emails to find banking transactions',
            style: AppTextStyles.body4.copyWith(
              color: AppColors.neutral400,
            ),
          ),
          const Gap(AppSpacing.spacing24),
          FilledButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAll(BuildContext context, WidgetRef ref, AppDatabase db) async {
    final pending = await db.parsedEmailTransactionDao.getPendingReview();
    if (pending.isEmpty) return;

    // Get active wallet from AsyncValue
    final walletAsync = ref.read(activeWalletProvider);
    final activeWallet = walletAsync.when(
      data: (data) => data,
      loading: () => null,
      error: (_, _) => null,
    );

    if (activeWallet == null) {
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('No wallet selected'),
          description: const Text('Please select a wallet first'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
      return;
    }

    // First approve all
    for (final tx in pending) {
      await db.parsedEmailTransactionDao.approve(
        tx.id,
        targetWalletId: activeWallet.id,
      );
    }

    // Then import all approved
    final importService = ref.read(emailImportServiceProvider);
    final result = await importService.importAllApproved();

    if (context.mounted) {
      toastification.show(
        context: context,
        title: Text('Imported ${result.successCount} transactions'),
        description: result.failedCount > 0
            ? Text('${result.failedCount} failed')
            : null,
        type: result.failedCount > 0
            ? ToastificationType.warning
            : ToastificationType.success,
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _approveSingle(
    BuildContext context,
    WidgetRef ref,
    AppDatabase db,
    ParsedEmailTransaction tx,
  ) async {
    // Get active wallet from AsyncValue
    final walletAsync = ref.read(activeWalletProvider);
    final activeWallet = walletAsync.when(
      data: (data) => data,
      loading: () => null,
      error: (_, _) => null,
    );

    if (activeWallet == null) {
      toastification.show(
        context: context,
        title: const Text('No wallet selected'),
        description: const Text('Please select a wallet first'),
        type: ToastificationType.warning,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    // Approve the transaction
    await db.parsedEmailTransactionDao.approve(
      tx.id,
      targetWalletId: activeWallet.id,
    );

    // Import to main transactions table
    final importService = ref.read(emailImportServiceProvider);
    final updatedTx = await db.parsedEmailTransactionDao.getByEmailId(tx.emailId);
    if (updatedTx != null) {
      final result = await importService.importTransaction(updatedTx);
      if (context.mounted) {
        if (result != null) {
          toastification.show(
            context: context,
            title: const Text('Transaction imported'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 2),
          );
        } else {
          toastification.show(
            context: context,
            title: const Text('Approved but import failed'),
            type: ToastificationType.warning,
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      }
    }
  }

  Future<void> _rejectSingle(
    BuildContext context,
    AppDatabase db,
    ParsedEmailTransaction tx,
  ) async {
    await db.parsedEmailTransactionDao.reject(tx.id);

    if (context.mounted) {
      toastification.show(
        context: context,
        title: const Text('Transaction rejected'),
        type: ToastificationType.info,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  void _editTransaction(BuildContext context, ParsedEmailTransaction tx) {
    // TODO: Open edit dialog
    toastification.show(
      context: context,
      title: const Text('Edit coming soon'),
      type: ToastificationType.info,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }
}

/// Card for reviewing a single transaction
class _TransactionReviewCard extends StatelessWidget {
  final ParsedEmailTransaction transaction;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  const _TransactionReviewCard({
    required this.transaction,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.transactionType == 'income';
    final amountColor = isIncome ? AppColors.green200 : AppColors.red600;
    final amountSign = isIncome ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Bank + Confidence
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAlpha10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.bankName,
                    style: AppTextStyles.body4.copyWith(
                      color: AppColors.primary700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${(transaction.confidence * 100).toInt()}% confident',
                  style: AppTextStyles.body4.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),

            const Gap(AppSpacing.spacing12),

            // Amount + Type
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$amountSign${_formatAmount(transaction.amount)} ${transaction.currency}',
                        style: AppTextStyles.body1.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        transaction.merchant ?? transaction.emailSubject,
                        style: AppTextStyles.body2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(AppSpacing.spacing12),

            // Date + Category hint
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.neutral500,
                ),
                const Gap(4),
                Text(
                  _formatDate(transaction.transactionDate),
                  style: AppTextStyles.body4.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                if (transaction.categoryHint != null) ...[
                  const Gap(AppSpacing.spacing16),
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: AppColors.neutral500,
                  ),
                  const Gap(4),
                  Text(
                    transaction.categoryHint!,
                    style: AppTextStyles.body4.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ],
            ),

            if (transaction.accountLast4 != null) ...[
              const Gap(AppSpacing.spacing8),
              Row(
                children: [
                  Icon(
                    Icons.credit_card_outlined,
                    size: 14,
                    color: AppColors.neutral500,
                  ),
                  const Gap(4),
                  Text(
                    '****${transaction.accountLast4}',
                    style: AppTextStyles.body4.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ],

            const Gap(AppSpacing.spacing16),
            const Divider(height: 1),
            const Gap(AppSpacing.spacing12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red600,
                    ),
                  ),
                ),
                const Gap(AppSpacing.spacing12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const Gap(AppSpacing.spacing12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
