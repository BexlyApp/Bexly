import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/buttons/custom_icon_button.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/features/main/presentation/components/transaction_options_menu.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:bexly/features/transaction/presentation/components/transaction_grouped_card.dart';
import 'package:bexly/features/transaction/presentation/components/transaction_summary_card.dart';
import 'package:bexly/features/transaction/presentation/components/transaction_tab_bar.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/transaction/presentation/screens/transaction_filter_form_dialog.dart';

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTransactionsAsyncValue = ref.watch(allTransactionsProvider);
    final isFilterActive = ref.watch(transactionFilterProvider);

    return CustomScaffold(
      context: context,
      showBackButton: false,
      showBalance: false,
      title: context.l10n.myTransactions,
      actions: [
        CustomIconButton(
          context,
          onPressed: () {
            final currentFilter = ref.read(transactionFilterProvider);
            context.openBottomSheet(
              child: TransactionFilterFormDialog(initialFilter: currentFilter),
            );
          },
          icon: HugeIcons.strokeRoundedFilter,
          showBadge: isFilterActive != null,
          themeMode: context.themeMode,
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => const TransactionOptionsMenu(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(
          HugeIcons.strokeRoundedPlusSign,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: allTransactionsAsyncValue.when(
              data: (allTransactions) {
                if (allTransactions.isEmpty) {
                  return Center(child: Text(context.l10n.noTransactionsRecorded));
                }

                // 1. Extract unique months from transactions
                final uniqueMonthYears = allTransactions
                    .map((t) => DateTime(t.date.year, t.date.month, 1))
                    .toSet()
                    .toList();

                // 2. Sort months in descending order (most recent first)
                uniqueMonthYears.sort((a, b) => b.compareTo(a));

                if (uniqueMonthYears.isEmpty) {
                  // This case should ideally be covered by allTransactions.isEmpty,
                  // but as a fallback.
                  return Center(
                    child: Text(context.l10n.noTransactionsWithValidDates),
                  );
                }

                // Determine initial index - try to set to current month if available, else most recent
                final now = DateTime.now();
                final currentMonthDate = DateTime(now.year, now.month, 1);
                int initialTabIndex = uniqueMonthYears.indexOf(currentMonthDate);
                if (initialTabIndex == -1) {
                  initialTabIndex =
                      0; // Default to the most recent month if current is not in the list
                }

                return DefaultTabController(
                  length: uniqueMonthYears.length,
                  initialIndex: initialTabIndex,
                  child: Column(
                    children: [
                      const Gap(AppSpacing.spacing20),
                      TransactionTabBar(
                        // TabController is now implicitly handled by DefaultTabController
                        monthsForTabs: uniqueMonthYears,
                      ),
                      const Gap(AppSpacing.spacing20),
                      Expanded(
                        child: TabBarView(
                          children: uniqueMonthYears.map((tabMonthDate) {
                            // Filter transactions for the current tab's month
                            final transactionsForMonth = allTransactions.where((t) {
                              return t.date.year == tabMonthDate.year &&
                                  t.date.month == tabMonthDate.month;
                            }).toList();

                            // CRITICAL FIX: Deduplicate transactions by unique key
                            // This prevents duplicate display when same transaction exists multiple times
                            // (can happen due to sync issues or database conflicts)
                            print('🔍 [DEDUP] Total transactions for month: ${transactionsForMonth.length}');

                            final seenKeys = <String>{};
                            final uniqueTransactions = <TransactionModel>[];
                            for (final transaction in transactionsForMonth) {
                              // CRITICAL FIX: Use cloudId as primary key to detect sync duplicates
                              // cloudId is unique across local and cloud, while local id may differ
                              final key = transaction.cloudId != null
                                  ? 'cloud_${transaction.cloudId}'
                                  : (transaction.id != null
                                      ? 'id_${transaction.id}'
                                      : '${transaction.title}_${transaction.amount}_${transaction.date.millisecondsSinceEpoch}_${transaction.wallet.id}');

                              print('🔍 [DEDUP] Checking transaction: ${transaction.title} (ID: ${transaction.id}, CloudID: ${transaction.cloudId}) - Key: $key - Seen: ${seenKeys.contains(key)}');

                              if (!seenKeys.contains(key)) {
                                seenKeys.add(key);
                                uniqueTransactions.add(transaction);
                                print('✅ [DEDUP] Added transaction: ${transaction.title}');
                              } else {
                                print('❌ [DEDUP] DUPLICATE SKIPPED: ${transaction.title}');
                              }
                            }

                            print('🔍 [DEDUP] After dedup: ${uniqueTransactions.length} transactions');

                            final transactionsToDisplay = uniqueTransactions;

                            if (transactionsToDisplay.isEmpty) {
                              // This should ideally not happen if tabs are generated from existing transaction months,
                              // but good for robustness.
                              return Center(
                                child: Text(
                                  context.l10n.noTransactionsForMonth,
                                ),
                              );
                            }

                            return ListView(
                              padding: const EdgeInsets.only(bottom: 120),
                              children: [
                                TransactionSummaryCard(
                                  transactions: transactionsToDisplay,
                                ),
                                const Gap(AppSpacing.spacing20),
                                TransactionGroupedCard(
                                  transactions: transactionsToDisplay,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
