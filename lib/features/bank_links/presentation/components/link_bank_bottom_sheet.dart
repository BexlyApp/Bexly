import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/bank_links/data/services/tingee_link_service.dart';
import 'package:bexly/features/bank_links/domain/models/tingee_bank.dart';

/// Bottom sheet that lets the user pick a bank from Tingee's supported list.
/// Phase B stops here — selecting a bank shows a "Sắp ra mắt" snackbar
/// because Phase B.1 is where /v1/create-va wiring lands.
Future<void> showLinkBankBottomSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _LinkBankSheet(),
  );
}

class _LinkBankSheet extends StatefulWidget {
  const _LinkBankSheet();

  @override
  State<_LinkBankSheet> createState() => _LinkBankSheetState();
}

class _LinkBankSheetState extends State<_LinkBankSheet> {
  late final Future<List<TingeeBank>> _banks;

  @override
  void initState() {
    super.initState();
    _banks = TingeeLinkService().listBanks();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: media.size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing20,
                vertical: AppSpacing.spacing12,
              ),
              child: Text('Chọn ngân hàng', style: AppTextStyles.heading4),
            ),
            const Divider(height: 1),
            Flexible(
              child: FutureBuilder<List<TingeeBank>>(
                future: _banks,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.spacing32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacing24),
                      child: Text(
                        '${snap.error}',
                        style: AppTextStyles.body3
                            .copyWith(color: AppColors.red600),
                      ),
                    );
                  }
                  final banks = snap.data ?? const [];
                  if (banks.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacing24),
                      child: Text(
                        'Tingee chưa trả về ngân hàng nào. Thử lại sau.',
                        style: AppTextStyles.body3,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.spacing8,
                    ),
                    itemCount: banks.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _BankRow(
                      bank: banks[i],
                      onTap: () => _onPick(context, banks[i]),
                    ),
                  );
                },
              ),
            ),
            const Gap(AppSpacing.spacing8),
          ],
        ),
      ),
    );
  }

  void _onPick(BuildContext context, TingeeBank bank) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã chọn ${bank.displayName}. Bước nhập số tài khoản đang phát triển.',
        ),
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.bank, required this.onTap});

  final TingeeBank bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: bank.logoUrl != null
          ? CircleAvatar(
              backgroundColor: AppColors.neutral100,
              backgroundImage: NetworkImage(bank.logoUrl!),
            )
          : CircleAvatar(
              backgroundColor: AppColors.primary50,
              child: Text(
                bank.code.isNotEmpty ? bank.code[0] : '?',
                style: TextStyle(
                  color: AppColors.primary500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      title: Text(bank.displayName, style: AppTextStyles.body2),
      subtitle: bank.shortName != null && bank.code.isNotEmpty
          ? Text(bank.code,
              style: AppTextStyles.body4
                  .copyWith(color: AppColors.neutral600))
          : null,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
