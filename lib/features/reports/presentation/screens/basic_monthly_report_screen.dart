import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
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
import 'package:bexly/core/extensions/currency_extension.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/dashboard_wallet_filter_provider.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/core/services/exchange_rate_service.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/reports/presentation/components/weekly_income_vs_expense_chart.dart';
import 'package:bexly/features/reports/presentation/components/six_months_income_vs_expense_chart.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

part '../components/spending_by_category_chart.dart';
part '../components/income_by_category_chart.dart';
part '../components/report_summary_cards.dart';

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
      title: '${date.toMonthName()} ${context.l10n.monthlyReport}',
      showBalance: false,
      body: Column(
        children: [
          // Wallet filter dropdown
          allWalletsAsync.when(
            data: (wallets) => _buildWalletFilter(context, ref, wallets, selectedWalletId),
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
          ),
          // Charts and Summary
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing20),
              children: [
                // Summary cards
                ReportSummaryCards(date: date),
                const SizedBox(height: AppSpacing.spacing20),

                // Weekly trend chart
                const WeeklyIncomeExpenseChart(),
                const SizedBox(height: AppSpacing.spacing20),

                // 6 months trend chart
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
                  child: SixMonthsIncomeExpenseChart(),
                ),
                const SizedBox(height: AppSpacing.spacing20),

                // Spending chart
                SpendingByCategoryChart(date: date),
                const SizedBox(height: AppSpacing.spacing20),

                // Income chart
                IncomeByCategoryChart(date: date),
              ],
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
    final displayText = selectedWallet?.name ?? context.l10n.allWallets;

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
        label: context.l10n.filterByWallet,
        hint: context.l10n.selectWallet,
        prefixIcon: HugeIcons.strokeRoundedWallet01, // This is List<List>, not IconData
        isRequired: false,
        onTap: () async {
          // Temporarily sync report filter with dashboard filter
          final currentWallet = selectedWalletId == null
              ? null
              : wallets.cast<WalletModel?>().firstWhere(
                  (w) => w?.id == selectedWalletId,
                  orElse: () => null,
                );

          if (currentWallet != null) {
            ref.read(dashboardWalletFilterProvider.notifier).state = currentWallet;
          } else {
            ref.read(dashboardWalletFilterProvider.notifier).state = null;
          }

          await context.openBottomSheet(
            child: const WalletSelectorBottomSheet(),
          );

          // Sync back to report filter
          final selectedDashboardWallet = ref.read(dashboardWalletFilterProvider);
          ref.read(reportWalletFilterProvider.notifier).state = selectedDashboardWallet?.id;
        },
      ),
    );
  }
}
