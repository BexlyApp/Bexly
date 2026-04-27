import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/bank_links/domain/models/linked_bank_account.dart';
import 'package:bexly/features/bank_links/presentation/components/link_bank_bottom_sheet.dart';
import 'package:bexly/features/bank_links/presentation/riverpod/linked_accounts_provider.dart';

/// Lists the user's Tingee-linked virtual accounts. Phase A is read-only:
/// the "Link with Tingee" CTA shows a "coming soon" notice because the
/// link/unlink flow runs through Tingee's web UI which is not wired yet.
class LinkedBankAccountsScreen extends ConsumerWidget {
  const LinkedBankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(linkedAccountsProvider);

    return CustomScaffold(
      context: context,
      title: 'Tài khoản ngân hàng',
      showBackButton: true,
      showBalance: false,
      body: accountsAsync.when(
        data: (accounts) =>
            accounts.isEmpty ? _EmptyState(onLink: () => showLinkBankBottomSheet(context)) : _AccountsList(accounts: accounts),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing24),
            child: Text(
              'Không tải được danh sách: $e',
              textAlign: TextAlign.center,
              style: AppTextStyles.body3.copyWith(color: AppColors.red600),
            ),
          ),
        ),
      ),
    );
  }

}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLink});

  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined,
                size: 64, color: AppColors.neutral500),
            const Gap(AppSpacing.spacing16),
            Text(
              'Chưa có tài khoản nào được liên kết',
              style: AppTextStyles.heading4,
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.spacing8),
            Text(
              'Liên kết tài khoản ngân hàng để giao dịch tự động hiện trong Bexly.',
              style: AppTextStyles.body4.copyWith(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.spacing24),
            ElevatedButton.icon(
              onPressed: onLink,
              icon: const Icon(Icons.add),
              label: const Text('Liên kết tài khoản'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing24,
                  vertical: AppSpacing.spacing12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsList extends StatelessWidget {
  const _AccountsList({required this.accounts});

  final List<LinkedBankAccount> accounts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      itemCount: accounts.length,
      separatorBuilder: (_, _) => const Gap(AppSpacing.spacing12),
      itemBuilder: (_, i) => _AccountCard(account: accounts[i]),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final LinkedBankAccount account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary50,
            child: Icon(Icons.account_balance,
                color: AppColors.primary500, size: 20),
          ),
          const Gap(AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.displayLabel, style: AppTextStyles.body2),
                const Gap(AppSpacing.spacing4),
                Text(
                  '${account.bankCode} · ${account.accountNumberMasked}',
                  style: AppTextStyles.body4
                      .copyWith(color: AppColors.neutral600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
