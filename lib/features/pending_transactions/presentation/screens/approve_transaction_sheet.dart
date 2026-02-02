import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';
import 'package:bexly/features/pending_transactions/riverpod/pending_transaction_provider.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/category/presentation/riverpod/category_providers.dart';
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/category_picker/presentation/components/category_icon.dart';
import 'package:intl/intl.dart';

/// Bottom sheet for approving and importing a pending transaction
class ApproveTransactionSheet extends HookConsumerWidget {
  final PendingTransactionModel pending;

  const ApproveTransactionSheet({
    super.key,
    required this.pending,
  });

  static Future<void> show(BuildContext context, PendingTransactionModel pending) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ApproveTransactionSheet(pending: pending),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(allWalletsStreamProvider);
    final categoriesAsync = ref.watch(hierarchicalCategoriesProvider);
    final state = ref.watch(pendingTransactionNotifierProvider);

    // State
    final selectedWalletId = useState<int?>(pending.targetWalletId);
    final selectedCategoryId = useState<int?>(pending.selectedCategoryId);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral600 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(AppSpacing.spacing20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pending.isIncome
                        ? AppColors.green100
                        : AppColors.red100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pending.isIncome ? 'INCOME' : 'EXPENSE',
                    style: AppTextStyles.body5.copyWith(
                      color: pending.isIncome
                          ? AppColors.green200
                          : AppColors.red600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Gap(AppSpacing.spacing8),
                _buildSourceTag(context),
                const Spacer(),
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

            const Gap(AppSpacing.spacing16),

            // Transaction details
            Text(
              pending.title,
              style: AppTextStyles.heading2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Gap(AppSpacing.spacing8),
            Text(
              '${pending.isIncome ? '+' : '-'} ${pending.amount.toPriceFormat()} ${pending.currency}',
              style: AppTextStyles.heading1.copyWith(
                color: pending.isIncome
                    ? AppColors.green200
                    : AppColors.red600,
              ),
            ),
            const Gap(AppSpacing.spacing8),
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar01,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                const Gap(4),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(pending.transactionDate),
                  style: AppTextStyles.body4.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (pending.merchant != null) ...[
              const Gap(4),
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedStore01,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const Gap(4),
                  Text(
                    pending.merchant!,
                    style: AppTextStyles.body4.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            const Gap(AppSpacing.spacing24),

            // Wallet selector
            Text(
              'Select Wallet',
              style: AppTextStyles.body2.bold.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Gap(AppSpacing.spacing8),
            walletsAsync.when(
              data: (wallets) {
                // Auto-select first wallet if none selected
                if (selectedWalletId.value == null && wallets.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    selectedWalletId.value = wallets.first.id;
                  });
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: wallets.map((wallet) {
                    final isSelected = selectedWalletId.value == wallet.id;
                    return ChoiceChip(
                      label: Text(wallet.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          selectedWalletId.value = wallet.id;
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      labelStyle: AppTextStyles.body4.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Text('Error: $e'),
            ),

            const Gap(AppSpacing.spacing20),

            // Category selector
            Text(
              'Select Category',
              style: AppTextStyles.body2.bold.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Gap(AppSpacing.spacing8),
            categoriesAsync.when(
              data: (categories) {
                // Filter by transaction type
                final filteredCategories = categories
                    .where((c) => pending.isExpense
                        ? c.transactionType == 'expense'
                        : c.transactionType == 'income')
                    .toList();

                // Auto-select first category if none selected
                if (selectedCategoryId.value == null && filteredCategories.isNotEmpty) {
                  // Try to match by categoryHint first
                  if (pending.categoryHint != null) {
                    final hintLower = pending.categoryHint!.toLowerCase();
                    final matchedCategory = filteredCategories.firstWhere(
                      (c) => c.title.toLowerCase().contains(hintLower) ||
                          hintLower.contains(c.title.toLowerCase()),
                      orElse: () => filteredCategories.first,
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      selectedCategoryId.value = matchedCategory.id;
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      selectedCategoryId.value = filteredCategories.first.id;
                    });
                  }
                }

                return SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredCategories.length,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      final isSelected = selectedCategoryId.value == category.id;

                      return InkWell(
                        onTap: () => selectedCategoryId.value = category.id,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                : (isDark ? AppColors.neutral800 : AppColors.neutral50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : (isDark ? AppColors.neutral700 : AppColors.neutral200),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CategoryIcon(
                                  iconType: category.iconType,
                                  icon: category.icon,
                                  iconBackground: category.iconBackground,
                                ),
                              ),
                              const Gap(4),
                              Text(
                                category.title,
                                style: AppTextStyles.body5.copyWith(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Text('Error: $e'),
            ),

            const Gap(AppSpacing.spacing24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.spacing12),
                Expanded(
                  child: FilledButton(
                    onPressed: selectedWalletId.value != null &&
                            selectedCategoryId.value != null &&
                            !state.isApproving
                        ? () => _approve(context, ref, selectedWalletId.value!, selectedCategoryId.value!)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green200,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isApproving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Import Transaction',
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const Gap(AppSpacing.spacing16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTag(BuildContext context) {
    final (color, bgColor) = _getSourceColors(pending.source);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: _getSourceIconData(pending.source),
            size: 14,
            color: color,
          ),
          const Gap(4),
          Text(
            pending.source.displayName,
            style: AppTextStyles.body5.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  dynamic _getSourceIconData(PendingTxSource source) {
    switch (source) {
      case PendingTxSource.email:
        return HugeIcons.strokeRoundedMail01;
      case PendingTxSource.bank:
        return HugeIcons.strokeRoundedBank;
      case PendingTxSource.sms:
        return HugeIcons.strokeRoundedMessage01;
      case PendingTxSource.notification:
        return HugeIcons.strokeRoundedNotification02;
    }
  }

  (Color, Color) _getSourceColors(PendingTxSource source) {
    switch (source) {
      case PendingTxSource.email:
        return (const Color(0xFFEA4335), const Color(0xFFEA4335).withValues(alpha: 0.1));
      case PendingTxSource.bank:
        return (const Color(0xFF635BFF), const Color(0xFF635BFF).withValues(alpha: 0.1));
      case PendingTxSource.sms:
        return (const Color(0xFF34A853), const Color(0xFF34A853).withValues(alpha: 0.1));
      case PendingTxSource.notification:
        return (const Color(0xFFFBBC04), const Color(0xFFFBBC04).withValues(alpha: 0.1));
    }
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    int walletId,
    int categoryId,
  ) async {
    final success = await ref
        .read(pendingTransactionNotifierProvider.notifier)
        .approveAndImport(
          pending,
          walletId: walletId,
          categoryId: categoryId,
        );

    if (context.mounted) {
      if (success) {
        Navigator.pop(context);
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Transaction imported!'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      } else {
        final error = ref.read(pendingTransactionNotifierProvider).error;
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text('Failed: ${error ?? 'Unknown error'}'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }
}
