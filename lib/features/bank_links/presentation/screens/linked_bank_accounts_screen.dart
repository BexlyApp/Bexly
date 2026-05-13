import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/bank_links/data/services/tingee_link_service.dart';
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

class _EmptyState extends ConsumerStatefulWidget {
  const _EmptyState({required this.onLink});

  final VoidCallback onLink;

  @override
  ConsumerState<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends ConsumerState<_EmptyState> {
  bool _syncing = false;

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
              onPressed: widget.onLink,
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
            const Gap(AppSpacing.spacing12),
            TextButton.icon(
              onPressed: _syncing ? null : _openSyncSheet,
              icon: _syncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 18),
              label: Text(_syncing ? 'Đang đồng bộ...' : 'Đồng bộ với Tingee'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSyncSheet() async {
    final accountCtrl = TextEditingController();
    final identityCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.spacing20,
            right: AppSpacing.spacing20,
            top: AppSpacing.spacing8,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom +
                AppSpacing.spacing20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Đồng bộ với Tingee', style: AppTextStyles.heading4),
              const Gap(AppSpacing.spacing4),
              Text(
                'Nhập số TK hoặc CCCD đã dùng khi liên kết để Bexly kéo lại tài khoản từ Tingee.',
                style: AppTextStyles.body4
                    .copyWith(color: AppColors.neutral600),
              ),
              const Gap(AppSpacing.spacing16),
              TextField(
                controller: accountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const Gap(AppSpacing.spacing12),
              TextField(
                controller: identityCtrl,
                decoration: const InputDecoration(
                  labelText: 'CCCD (tuỳ chọn)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const Gap(AppSpacing.spacing16),
              ElevatedButton(
                onPressed: () => Navigator.of(sheetCtx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.spacing12),
                ),
                child: const Text('Đồng bộ'),
              ),
            ],
          ),
        );
      },
    );

    if (result != true || !mounted) return;
    final acc = accountCtrl.text.trim();
    final ident = identityCtrl.text.trim();
    if (acc.isEmpty && ident.isEmpty) return;

    setState(() => _syncing = true);
    try {
      final svc = TingeeLinkService();
      final res = await svc.syncVas(accountNumber: acc, identity: ident);
      if (!mounted) return;
      final data = (res['data'] as Map?) ?? const {};
      final upserted = data['upserted'] ?? 0;
      final matched = data['matched'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đồng bộ xong: matched=$matched, upserted=$upserted',
          ),
        ),
      );
      ref.invalidate(linkedAccountsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

class _AccountsList extends ConsumerWidget {
  const _AccountsList({required this.accounts});

  final List<LinkedBankAccount> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.spacing12),
            itemBuilder: (_, i) => _AccountCard(account: accounts[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.spacing16,
            0,
            AppSpacing.spacing16,
            AppSpacing.spacing16,
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showLinkBankBottomSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Liên kết tài khoản khác'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends ConsumerStatefulWidget {
  const _AccountCard({required this.account});

  final LinkedBankAccount account;

  @override
  ConsumerState<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<_AccountCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
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
          IconButton(
            tooltip: 'Hủy liên kết',
            onPressed: _busy ? null : _confirmUnlink,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.link_off, color: AppColors.red600),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnlink() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hủy liên kết tài khoản?', style: AppTextStyles.heading4),
            const Gap(AppSpacing.spacing8),
            Text(
              'Bexly sẽ ngưng nhận giao dịch tự động từ ${widget.account.displayLabel}.',
              style: AppTextStyles.body4
                  .copyWith(color: AppColors.neutral600),
            ),
            const Gap(AppSpacing.spacing20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Quay lại'),
                  ),
                ),
                const Gap(AppSpacing.spacing12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Hủy liên kết'),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.spacing8),
          ],
        ),
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final svc = TingeeLinkService();
      final delete = await svc.deleteVa(
        bankBin: widget.account.bankCode,
        vaAccountNumber: widget.account.tingeeAccountId,
      );
      if (!delete.isOk || delete.confirmId == null) {
        throw Exception(delete.message ?? 'Yêu cầu hủy thất bại.');
      }
      // No OTP required for unlink in many flows - pass empty otp; if Tingee
      // requires OTP it will return a non-00 code and we surface it.
      final confirmRes = await svc.confirmDeleteVa(
        bankBin: widget.account.bankCode,
        confirmId: delete.confirmId!,
        vaAccountNumber: widget.account.tingeeAccountId,
      );
      if (!confirmRes.isOk) {
        throw Exception(confirmRes.message ?? 'Xác nhận hủy thất bại.');
      }
      ref.invalidate(linkedAccountsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
