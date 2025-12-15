import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/buttons/circle_button.dart';
import 'package:bexly/core/components/buttons/custom_icon_button.dart';
import 'package:bexly/core/components/progress_indicators/custom_progress_indicator.dart';
import 'package:bexly/core/components/progress_indicators/custom_progress_indicator_legend.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/constants/app_font_weights.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/currency_extension.dart';
import 'package:bexly/core/extensions/date_time_extension.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bexly/core/riverpod/auth_providers.dart' as firebase_auth;
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:bexly/features/main/presentation/components/transaction_options_menu.dart';
import 'package:bexly/core/services/riverpod/exchange_rate_providers.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/goal/presentation/components/goal_pinned_holder.dart';
import 'package:bexly/features/theme_switcher/presentation/components/theme_mode_switcher.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/components/transaction_tile.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/screens/wallet_form_bottom_sheet.dart';
import 'package:bexly/features/wallet_switcher/presentation/screens/wallet_switcher_dropdown.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/dashboard_wallet_filter_provider.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/selected_month_provider.dart';
import 'package:bexly/features/dashboard/presentation/riverpod/cash_flow_providers.dart';
import 'package:bexly/features/notification/presentation/riverpod/notification_providers.dart';

part '../components/action_button.dart';
// part '../components/balance_card.dart'; // Legacy - using balance_card_v2 instead
part '../components/balance_card_v2.dart';
part '../components/wallet_amount_visibility_button.dart';
part '../components/wallet_amount_edit_button.dart';
part '../components/cash_flow_cards.dart';
part '../components/greeting_card.dart';
part '../components/header.dart';
part '../components/month_navigator.dart';
part '../components/recent_transaction_list.dart';
part '../components/spending_progress_chart.dart';
part '../components/transaction_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(114 + MediaQuery.of(context).padding.top),
        child: const Header(),
      ),
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
                icon: HugeIcons.strokeRoundedPlusSign,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 100),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.spacing20,
                    0,
                    AppSpacing.spacing20,
                    AppSpacing.spacing20,
                  ),
                  child: const Column(
                    children: [
                      BalanceCard(),
                      Gap(AppSpacing.spacing12),
                      CashFlowCards(),
                      Gap(AppSpacing.spacing12),
                      SpendingProgressChart(),
                    ],
                  ),
                ),
                const GoalPinnedHolder(),
                const RecentTransactionList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
