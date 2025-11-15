import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/extensions/date_time_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/features/reports/presentation/riverpod/filtered_transactions_provider.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_type.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

part '../components/spending_by_category_chart.dart';
part '../components/report_wallet_selector.dart';

/// State provider for selected wallet filter (null = All Wallets)
final reportWalletFilterProvider = StateProvider<int?>((ref) => null);

class BasicMonthlyReportScreen extends ConsumerWidget {
  const BasicMonthlyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = GoRouterState.of(context).extra as DateTime;
    final allWalletsAsync = ref.watch(allWalletsStreamProvider);
    final selectedWalletId = ref.watch(reportWalletFilterProvider);

    return CustomScaffold(
      context: context,
      title: '${date.toMonthName()} Report',
      showBalance: false,
      body: Column(
        children: [
          // Wallet filter dropdown
          allWalletsAsync.when(
            data: (wallets) => _buildWalletFilter(context, ref, wallets, selectedWalletId),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
          ),
          // Chart
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing20),
              children: [SpendingByCategoryChart(date: date)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletFilter(
    BuildContext context,
    WidgetRef ref,
    List wallets,
    int? selectedWalletId,
  ) {
    // Find selected wallet name
    final selectedWallet = selectedWalletId == null
        ? null
        : wallets.cast<WalletModel?>().firstWhere(
            (w) => w?.id == selectedWalletId,
            orElse: () => null,
          );
    final displayText = selectedWallet?.name ?? 'All Wallets';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacing20,
        AppSpacing.spacing16,
        AppSpacing.spacing20,
        0,
      ),
      child: CustomSelectField(
        context: context,
        controller: TextEditingController(text: displayText),
        label: 'Filter by Wallet',
        hint: 'Select wallet',
        prefixIcon: HugeIcons.strokeRoundedWallet01,
        isRequired: false,
        onTap: () {
          context.openBottomSheet(
            child: const _ReportWalletSelector(),
          );
        },
      ),
    );
  }
}
