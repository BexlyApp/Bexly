import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/bottom_sheets/alert_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/custom_icon_button.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/dialogs/toast.dart';
// custom_confirm_checkbox no longer needed — replaced by period selector
import 'package:bexly/core/components/form_fields/custom_numeric_field.dart';
import 'package:bexly/core/components/form_fields/custom_select_field.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/core/extensions/string_extension.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/budget/data/model/budget_model.dart';
import 'package:bexly/features/budget/presentation/components/budget_date_range_picker.dart';
import 'package:bexly/features/budget/presentation/riverpod/budget_providers.dart';
import 'package:bexly/features/budget/presentation/riverpod/date_picker_provider.dart'
    as budget_date_provider; // Alias to avoid conflict
import 'package:bexly/features/category/data/model/category_model.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet_switcher/presentation/components/wallet_selector_bottom_sheet.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/services/subscription/subscription.dart';
import 'package:toastification/toastification.dart';

String _monthLabel(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final lastDay = DateTime(date.year, date.month + 1, 0).day;
  return '1 ${months[date.month - 1]} ${date.year} - $lastDay ${months[date.month - 1]} ${date.year}';
}

String _weekLabel(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  // Monday of current week
  final monday = date.subtract(Duration(days: date.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  return '${monday.day} ${months[monday.month - 1]} - ${sunday.day} ${months[sunday.month - 1]} ${sunday.year}';
}

class BudgetFormScreen extends HookConsumerWidget {
  final int? budgetId; // For editing
  const BudgetFormScreen({super.key, this.budgetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.read(activeWalletProvider);
    final defaultCurrency = wallet.value?.currencyByIsoCode(ref).symbol;
    final isEditing = budgetId != null;
    final budgetDetails = isEditing
        ? ref.watch(budgetDetailsProvider(budgetId!))
        : null;

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final amountController = useTextEditingController();
    final walletController = useTextEditingController();
    final categoryController = useTextEditingController(); // For display text

    final selectedCategory = useState<CategoryModel?>(null);
    final selectedWallet = useState<WalletModel?>(null); // For fund source
    // null = one-time, 'weekly', 'monthly'
    final selectedPeriod = useState<String?>(null);

    final activeWalletsAsync = ref.watch(activeWalletProvider);
    final allBudgetsAsync = ref.watch(budgetListProvider);

    useEffect(() {
      // Set default wallet to active wallet if not editing
      if (!isEditing && selectedWallet.value == null && activeWalletsAsync.value != null) {
        selectedWallet.value = activeWalletsAsync.value;
        walletController.text =
            formatCurrency(activeWalletsAsync.value?.balance.toPriceFormat() ?? '0', activeWalletsAsync.value?.currencyByIsoCode(ref).symbol ?? '', activeWalletsAsync.value?.currency ?? 'VND');
      }

      if (isEditing && budgetDetails is AsyncData<BudgetModel?>) {
        final budget = budgetDetails.value;
        if (budget != null) {
          amountController.text =
              formatCurrency(budget.amount.toPriceFormat(), defaultCurrency ?? 'đ', wallet.value?.currency ?? 'VND');
          selectedCategory.value = budget.category;
          categoryController.text = budget.category.title; // Simplified display
          selectedWallet.value = budget.wallet;
          walletController.text =
              formatCurrency(budget.wallet.balance.toPriceFormat(), budget.wallet.currencyByIsoCode(ref).symbol, budget.wallet.currency);
          selectedPeriod.value = budget.routinePeriod;
        }
      }
      return null;
    }, [isEditing, budgetDetails, activeWalletsAsync]);

    final remainingBudgetForEntry = useMemoized<double?>(() {
      final wallet = selectedWallet.value;
      final budgets = allBudgetsAsync.value;

      // Don't calculate if essential data is missing
      if (wallet == null || budgets == null) {
        return null;
      }
      // If editing, we also need the original budget details to be loaded
      if (isEditing && budgetDetails?.hasValue != true) {
        return null;
      }

      double totalExistingBudgetsAmount = budgets.fold(
        0.0,
        (sum, budget) => sum + budget.amount,
      );

      if (isEditing) {
        // budgetDetails is guaranteed to have value here because of the check above
        final originalAmount = budgetDetails!.value!.amount;
        totalExistingBudgetsAmount -= originalAmount;
      }

      final availableAmount = wallet.balance - totalExistingBudgetsAmount;
      return availableAmount;
    }, [selectedWallet, allBudgetsAsync, budgetDetails]);

    final amountLabel = remainingBudgetForEntry != null
        ? 'Amount (Available: ${remainingBudgetForEntry.toPriceFormat()})'
        : 'Amount';

    void saveBudget() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (selectedCategory.value == null) {
        Toast.show(
          'Please select a category.',
          type: ToastificationType.warning,
        );
        return;
      }
      if (selectedWallet.value == null) {
        Toast.show(
          'Please select a fund source (wallet).',
          type: ToastificationType.warning,
        );
        return;
      }

      final dateRange = ref.read(budget_date_provider.datePickerProvider);
      if (dateRange.length < 2 ||
          dateRange[0] == null ||
          dateRange[1] == null) {
        Toast.show(
          'Please select a valid date range.',
          type: ToastificationType.warning,
        );
        return;
      }

      final allBudgets = ref.read(budgetListProvider).value ?? [];

      final budgetToSave = BudgetModel(
        id: isEditing ? budgetId : null,
        wallet: selectedWallet.value!,
        category: selectedCategory.value!,
        amount: amountController.text.takeNumericAsDouble(),
        startDate: dateRange[0]!,
        endDate: dateRange[1]!,
        isRoutine: selectedPeriod.value != null,
        routinePeriod: selectedPeriod.value,
      );

      final budgetDao = ref.read(budgetDaoProvider);
      try {
        if (isEditing) {
          await budgetDao.updateBudget(budgetToSave);
          Toast.show('Budget updated!', type: ToastificationType.success);
        } else {
          // Check subscription limit before creating new budget
          final limits = ref.read(subscriptionLimitsProvider);
          if (!limits.isWithinLimit(allBudgets.length, limits.maxBudgets)) {
            Toast.show(
              'You have reached the maximum of ${limits.maxBudgets} budgets. Upgrade to Plus for unlimited budgets.',
              type: ToastificationType.warning,
            );
            return;
          }

          await budgetDao.addBudget(budgetToSave);
          Toast.show('Budget created!', type: ToastificationType.success);
        }
        if (context.mounted) context.pop();
      } catch (e) {
        Log.e('Failed to save budget: $e');
        Toast.show('Failed to save budget: $e', type: ToastificationType.error);
      }
    }

    return CustomScaffold(
      context: context,
      title: isEditing ? 'Edit Budget' : 'Create Budget',
      showBackButton: true,
      showBalance: false,
      actions: [
        if (isEditing)
          CustomIconButton(
            context,
            onPressed: () async {
              // Show confirmation dialog
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (dialogContext) => AlertBottomSheet(
                  title: context.l10n.deleteBudget,
                  content: Text(
                    context.l10n.deleteBudgetConfirm,
                    style: AppTextStyles.body2,
                  ),
                  onConfirm: () async {
                    context.pop(); // close dialog
                    context.pop(); // close form
                    context.pop(); // close detail screen

                    ref.read(budgetDaoProvider).deleteBudget(budgetId!);
                    Toast.show('Budget deleted!');
                  },
                ),
              );
            },
            icon: HugeIcons.strokeRoundedDelete02,
            themeMode: context.themeMode,
          ),
      ],
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isEditing && budgetDetails == null ||
              budgetDetails is AsyncLoading)
            const Center(child: CircularProgressIndicator())
          else if (isEditing && budgetDetails is AsyncError)
            Center(child: Text('Error loading budget: ${budgetDetails?.error}'))
          else
            Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spacing20,
                  AppSpacing.spacing20,
                  AppSpacing.spacing20,
                  100,
                ),
                child: Column(
                  spacing: AppSpacing.spacing16,
                  children: [
                    CustomSelectField(
                      context: context,
                      controller: walletController,
                      label: 'Wallet',
                      hint: 'Select Wallet',
                      isRequired: true,
                      prefixIcon: HugeIcons.strokeRoundedWallet01,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) => WalletSelectorBottomSheet(
                            onWalletSelected: (WalletModel wallet) {
                              selectedWallet.value = wallet;
                              walletController.text =
                                formatCurrency(wallet.balance.toPriceFormat(), wallet.currencyByIsoCode(ref).symbol, wallet.currency);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                    CustomSelectField(
                      context: context,
                      controller: categoryController,
                      label: 'Category',
                      hint: 'Select Category',
                      isRequired: true,
                      prefixIcon: HugeIcons.strokeRoundedPackage,
                      onTap: () async {
                        final CategoryModel? result = await context.push(
                          Routes.categoryList,
                        );
                        if (result != null) {
                          selectedCategory.value = result;
                          categoryController.text =
                              result.title; // Or more detailed text
                        }
                      },
                    ),
                    CustomNumericField(
                      controller: amountController,
                      label: amountLabel,
                      hint: '1,000.00',
                      icon: HugeIcons.strokeRoundedCoins01,
                      appendCurrencySymbolToHint: true,
                      isRequired: true,
                    ),
                    // Period selector: One-time | Weekly | Monthly
                    _BudgetPeriodSelector(
                      selectedPeriod: selectedPeriod.value,
                      onChanged: (period) {
                        selectedPeriod.value = period;
                        final now = DateTime.now();
                        if (period == 'weekly') {
                          final monday = now.subtract(Duration(days: now.weekday - 1));
                          final sunday = monday.add(const Duration(days: 6));
                          ref.read(budget_date_provider.datePickerProvider.notifier).state =
                              [monday, sunday];
                        } else if (period == 'monthly') {
                          final monthStart = DateTime(now.year, now.month, 1);
                          final monthEnd = DateTime(now.year, now.month + 1, 0);
                          ref.read(budget_date_provider.datePickerProvider.notifier).state =
                              [monthStart, monthEnd];
                        }
                      },
                    ),
                    if (selectedPeriod.value == null)
                      const BudgetDateRangePicker()
                    else
                      CustomSelectField(
                        context: context,
                        controller: useTextEditingController(
                          text: selectedPeriod.value == 'weekly'
                              ? _weekLabel(ref.watch(budget_date_provider.datePickerProvider).first ?? DateTime.now())
                              : _monthLabel(ref.watch(budget_date_provider.datePickerProvider).first ?? DateTime.now()),
                        ),
                        label: 'Budget period (auto-renews ${selectedPeriod.value})',
                        hint: selectedPeriod.value == 'weekly' ? 'This week' : 'This month',
                        prefixIcon: HugeIcons.strokeRoundedCalendar01,
                        isRequired: true,
                        onTap: null,
                      ),
                  ],
                ),
              ),
            ),
          PrimaryButton(
            label: 'Save Budget',
            onPressed: saveBudget,
          ).floatingBottomContained,
        ],
      ),
    );
  }
}

class _BudgetPeriodSelector extends StatelessWidget {
  final String? selectedPeriod;
  final ValueChanged<String?> onChanged;

  const _BudgetPeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget chip(String label, String? value) {
      final isSelected = selectedPeriod == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? null
                  : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.body3.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat', style: AppTextStyles.body3.copyWith(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          spacing: 8,
          children: [
            chip('One-time', null),
            chip('Weekly', 'weekly'),
            chip('Monthly', 'monthly'),
          ],
        ),
      ],
    );
  }
}
