import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';

import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/string_extension.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/features/category/data/model/icon_type.dart';
import 'package:bexly/features/category_picker/presentation/components/category_icon.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/email_sync/riverpod/email_scan_provider.dart';
import 'package:bexly/features/transaction/presentation/components/form/transaction_type_selector.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

/// Screen for reviewing and approving parsed email transactions
class EmailReviewScreen extends HookConsumerWidget {
  const EmailReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[EmailReview] ===== BUILD METHOD CALLED =====');

    late final AppDatabase db;
    try {
      db = ref.watch(databaseProvider);
      debugPrint('[EmailReview] Database provider OK');
    } catch (e) {
      debugPrint('[EmailReview] ERROR getting database: $e');
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Database error: $e')),
      );
    }

    final walletsAsync = ref.watch(allWalletsStreamProvider);
    final wallets = walletsAsync.when(
      data: (data) => data,
      loading: () => <WalletModel>[],
      error: (_, _) => <WalletModel>[],
    );

    // State for wallet selection per transaction (key: transactionId, value: walletId)
    final walletSelections = useState<Map<int, WalletModel?>>({});

    // State to track which transactions have been initialized
    final initializedTransactions = useState<Set<int>>({});

    return CustomScaffold(
      context: context,
      title: 'Review Transactions',
      showBalance: false,
      actions: [
        IconButton(
          onPressed: () => _approveAll(context, ref, db, walletSelections.value),
          icon: const Icon(Icons.done_all),
          tooltip: 'Approve All',
        ),
      ],
      body: StreamBuilder<List<ParsedEmailTransaction>>(
        stream: db.parsedEmailTransactionDao.watchPendingReview(),
        builder: (context, snapshot) {
          debugPrint('[EmailReview] StreamBuilder - connectionState: ${snapshot.connectionState}');
          debugPrint('[EmailReview] StreamBuilder - hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');

          if (snapshot.hasError) {
            debugPrint('[EmailReview] StreamBuilder ERROR: ${snapshot.error}');
            return Container(
              color: Colors.red,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }

          // Show loading only for initial load
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            debugPrint('[EmailReview] Showing loading indicator...');
            return const Center(child: LoadingIndicator());
          }

          final transactions = snapshot.data ?? [];
          debugPrint('[EmailReview] Got ${transactions.length} transactions');

          if (transactions.isEmpty) {
            return _buildEmptyState(context);
          }

          debugPrint('[EmailReview] Should show ${transactions.length} transactions');

          // Render transactions list
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];

              return _TransactionCard(
                key: ValueKey(tx.id),
                transaction: tx,
                wallets: wallets,
                walletSelections: walletSelections,
                initializedTransactions: initializedTransactions,
                onReject: () => _rejectSingle(context, db, tx),
                onEdit: () => _editTransaction(context, ref, db, tx),
                onApprove: (wallet) => _approveSingle(context, ref, db, tx, wallet),
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacing24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.neutral400,
            ),
          ),
          const Gap(AppSpacing.spacing24),
          Text(
            'No transactions to review',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AppSpacing.spacing8),
          Text(
            'Scan your emails to find banking transactions',
            style: AppTextStyles.body4.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const Gap(AppSpacing.spacing32),
          PrimaryButton(
            label: 'Go Back',
            icon: Icons.arrow_back,
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/settings/email-sync');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _approveAll(
    BuildContext context,
    WidgetRef ref,
    AppDatabase db,
    Map<int, WalletModel?> walletSelections,
  ) async {
    final pending = await db.parsedEmailTransactionDao.getPendingReview();
    if (pending.isEmpty) return;

    // Check if all transactions have wallet selected
    final missingWallet = pending.where(
      (tx) => walletSelections[tx.id] == null,
    );

    if (missingWallet.isNotEmpty) {
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Please select wallets'),
          description: Text('${missingWallet.length} transactions need a wallet selected'),
          type: ToastificationType.warning,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
      return;
    }

    // First approve all with their selected wallets
    for (final tx in pending) {
      final wallet = walletSelections[tx.id];
      if (wallet != null) {
        await db.parsedEmailTransactionDao.approve(
          tx.id,
          targetWalletId: wallet.id,
        );
      }
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
    WalletModel? selectedWallet,
  ) async {
    if (selectedWallet == null) {
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
      targetWalletId: selectedWallet.id,
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

  Future<void> _editTransaction(
    BuildContext context,
    WidgetRef ref,
    AppDatabase db,
    ParsedEmailTransaction tx,
  ) async {
    // Show edit bottom sheet
    final result = await showModalBottomSheet<ParsedEmailTransaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditTransactionBottomSheet(transaction: tx),
    );

    if (result != null && context.mounted) {
      // Update the transaction in database
      await db.parsedEmailTransactionDao.updateParsedTransaction(
        id: result.id,
        amount: result.amount,
        merchant: result.merchant,
        transactionType: result.transactionType,
        categoryHint: result.categoryHint,
        transactionDate: result.transactionDate,
      );

      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Transaction updated'),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    }
  }
}

/// Bottom sheet for editing a parsed email transaction
class _EditTransactionBottomSheet extends HookConsumerWidget {
  final ParsedEmailTransaction transaction;

  const _EditTransactionBottomSheet({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = useTextEditingController(
      text: transaction.amount.toString(),
    );
    final merchantController = useTextEditingController(
      text: transaction.merchant ?? '',
    );
    final categoryController = useTextEditingController(
      text: transaction.categoryHint ?? '',
    );

    final isIncome = useState(transaction.transactionType == 'income');
    final selectedDate = useState(transaction.transactionDate);

    // Get currency info
    final currencies = ref.watch(currenciesStaticProvider);
    final currencyData = currencies.fromIsoCode(transaction.currency);
    final currencySymbol = currencyData?.symbol ?? transaction.currency;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.spacing20),
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedPencilEdit01,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Gap(AppSpacing.spacing8),
                Text(
                  'Edit Transaction',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.spacing20),
            // Transaction type toggle
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => isIncome.value = true,
                    borderRadius: BorderRadius.circular(AppRadius.radius8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing12,
                        vertical: AppSpacing.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: isIncome.value ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.radius8),
                        border: Border.all(
                          color: isIncome.value ? Colors.green : Colors.grey.shade300,
                          width: isIncome.value ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: isIncome.value ? Colors.green : Colors.grey.shade500,
                          ),
                          const Gap(AppSpacing.spacing4),
                          Text(
                            'Income',
                            style: AppTextStyles.body4.copyWith(
                              color: isIncome.value ? Colors.green : Colors.grey.shade500,
                              fontWeight: isIncome.value ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(AppSpacing.spacing8),
                Expanded(
                  child: InkWell(
                    onTap: () => isIncome.value = false,
                    borderRadius: BorderRadius.circular(AppRadius.radius8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing12,
                        vertical: AppSpacing.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: !isIncome.value ? Colors.red.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.radius8),
                        border: Border.all(
                          color: !isIncome.value ? Colors.red : Colors.grey.shade300,
                          width: !isIncome.value ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: !isIncome.value ? Colors.red : Colors.grey.shade500,
                          ),
                          const Gap(AppSpacing.spacing4),
                          Text(
                            'Expense',
                            style: AppTextStyles.body4.copyWith(
                              color: !isIncome.value ? Colors.red : Colors.grey.shade500,
                              fontWeight: !isIncome.value ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Gap(AppSpacing.spacing16),

            // Amount field
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$currencySymbol ',
                border: const OutlineInputBorder(),
              ),
            ),

            const Gap(AppSpacing.spacing12),

            // Merchant field
            TextField(
              controller: merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant / Description',
                border: OutlineInputBorder(),
              ),
            ),

            const Gap(AppSpacing.spacing12),

            // Category hint field
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),

            const Gap(AppSpacing.spacing12),

            // Date picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  // Keep the time from original date
                  selectedDate.value = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    selectedDate.value.hour,
                    selectedDate.value.minute,
                  );
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.radius8),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.spacing12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutralAlpha25),
                  borderRadius: BorderRadius.circular(AppRadius.radius8),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      size: 20,
                      color: AppColors.neutral500,
                    ),
                    const Gap(AppSpacing.spacing8),
                    Text(
                      '${selectedDate.value.day}/${selectedDate.value.month}/${selectedDate.value.year}',
                      style: AppTextStyles.body3,
                    ),
                    const Spacer(),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 16,
                      color: AppColors.neutral400,
                    ),
                  ],
                ),
              ),
            ),
            const Gap(AppSpacing.spacing24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radius8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const Gap(AppSpacing.spacing12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? transaction.amount;
                      // Create updated transaction (using copyWith pattern manually)
                      final updated = ParsedEmailTransaction(
                        id: transaction.id,
                        cloudId: transaction.cloudId,
                        emailId: transaction.emailId,
                        emailSubject: transaction.emailSubject,
                        fromEmail: transaction.fromEmail,
                        amount: amount,
                        currency: transaction.currency,
                        transactionType: isIncome.value ? 'income' : 'expense',
                        merchant: merchantController.text.isEmpty ? null : merchantController.text,
                        accountLast4: transaction.accountLast4,
                        balanceAfter: transaction.balanceAfter,
                        transactionDate: selectedDate.value,
                        emailDate: transaction.emailDate,
                        confidence: transaction.confidence,
                        rawAmountText: transaction.rawAmountText,
                        categoryHint: categoryController.text.isEmpty ? null : categoryController.text,
                        bankName: transaction.bankName,
                        status: transaction.status,
                        importedTransactionId: transaction.importedTransactionId,
                        targetWalletId: transaction.targetWalletId,
                        selectedCategoryId: transaction.selectedCategoryId,
                        userNotes: transaction.userNotes,
                        createdAt: transaction.createdAt,
                        updatedAt: DateTime.now(),
                      );
                      Navigator.of(context).pop(updated);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radius8),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Transaction card widget with proper state management
class _TransactionCard extends HookConsumerWidget {
  final ParsedEmailTransaction transaction;
  final List<WalletModel> wallets;
  final ValueNotifier<Map<int, WalletModel?>> walletSelections;
  final ValueNotifier<Set<int>> initializedTransactions;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final Function(WalletModel) onApprove;

  const _TransactionCard({
    super.key,
    required this.transaction,
    required this.wallets,
    required this.walletSelections,
    required this.initializedTransactions,
    required this.onReject,
    required this.onEdit,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.transactionType == 'income';
    final db = ref.watch(databaseProvider);

    // Auto-initialize wallet selection and category matching using useEffect
    useEffect(() {
      if (!initializedTransactions.value.contains(transaction.id) && wallets.isNotEmpty) {
        // Try to find wallet with matching currency
        final matchingWallet = wallets.firstWhere(
          (w) => w.currency == transaction.currency,
          orElse: () => wallets.first,
        );

        // Update selections and mark as initialized
        WidgetsBinding.instance.addPostFrameCallback((_) {
          walletSelections.value = {
            ...walletSelections.value,
            transaction.id: matchingWallet,
          };
          initializedTransactions.value = {
            ...initializedTransactions.value,
            transaction.id,
          };
        });

        // Auto-match category from categoryHint
        if (transaction.categoryHint != null &&
            transaction.categoryHint!.isNotEmpty &&
            transaction.selectedCategoryId == null) {
          _autoMatchAndSaveCategory(db, transaction);
        }
      }
      return null;
    }, [transaction.id, wallets.length]);

    final selectedWallet = walletSelections.value[transaction.id];
    final currencies = ref.watch(currenciesStaticProvider);
    final currencyData = currencies.fromIsoCode(transaction.currency);

    // Get merchant name for display
    final merchantName = transaction.merchant ?? transaction.bankName;

    // Get matched category for display
    final matchedCategory = useState<Category?>(null);

    // Watch categories and find matching one
    useEffect(() {
      final subscription = db.categoryDao.watchAllCategories().listen((categories) {
        final matched = _findMatchingCategory(categories, transaction);
        debugPrint('[EmailReview] Transaction ${transaction.id}: categoryHint="${transaction.categoryHint}", matched=${matched?.title}');
        matchedCategory.value = matched;
      });
      return subscription.cancel;
    }, [transaction.id]);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: isIncome
            ? (context.isDarkMode ? AppColors.neutralAlpha25 : AppColors.neutral50)
            : (context.isDarkMode ? AppColors.neutralAlpha25 : AppColors.neutral50),
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(
          color: context.isDarkMode ? AppColors.neutralAlpha25 : AppColors.neutralAlpha10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main transaction tile - EXACTLY like TransactionTile
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(AppRadius.radius12),
            child: Container(
              height: 70,
              padding: const EdgeInsets.only(right: AppSpacing.spacing12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon section (70x70) - EXACTLY like TransactionTile
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(AppSpacing.spacing12),
                    decoration: BoxDecoration(
                      color: isIncome ? context.incomeBackground : context.expenseBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.radius12 - 1),
                        bottomLeft: Radius.circular(AppRadius.radius12 - 1),
                      ),
                    ),
                    // Show real category icon or placeholder
                    child: matchedCategory.value != null
                        ? CategoryIcon(
                            iconType: _getIconType(matchedCategory.value!.iconType),
                            icon: matchedCategory.value!.icon ?? '',
                            iconBackground: matchedCategory.value!.iconBackground ?? '',
                          )
                        : Center(
                            child: AutoSizeText(
                              merchantName.isNotEmpty ? merchantName[0].toUpperCase() : '?',
                              minFontSize: 16,
                              maxFontSize: 22,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heading4.copyWith(
                                height: 0.9,
                                fontVariations: [FontVariation.weight(700)],
                                color: isIncome ? AppColors.green200 : AppColors.red,
                              ),
                            ),
                          ),
                  ),
                  const Gap(AppSpacing.spacing12),
                  // Content section - EXACTLY like TransactionTile
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title + Category
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                merchantName,
                                style: AppTextStyles.body3.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(AppSpacing.spacing2),
                              AutoSizeText(
                                transaction.categoryHint ?? transaction.bankName,
                                style: AppTextStyles.body4,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Date + Amount
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${transaction.transactionDate.day}/${transaction.transactionDate.month}',
                              style: AppTextStyles.body5,
                            ),
                            Text(
                              '${isIncome ? '+' : '-'} ${formatCurrency(transaction.amount.toPriceFormat(decimalDigits: currencyData?.decimalDigits ?? 0), currencyData?.symbol ?? '', currencyData?.isoCode ?? 'VND')}',
                              style: AppTextStyles.numericMedium.copyWith(
                                color: isIncome ? AppColors.green200 : AppColors.red700,
                                height: 1.12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Wallet info + Buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing12),
            child: Column(
              children: [
                // Show mapped wallet (compact)
                if (selectedWallet != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary600,
                        size: 14,
                      ),
                      const Gap(AppSpacing.spacing4),
                      Text(
                        selectedWallet.name,
                        style: AppTextStyles.body5.copyWith(
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                const Gap(AppSpacing.spacing8),
                // Action buttons
                Row(
                  children: [
                    // Reject button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red600,
                          side: BorderSide(color: AppColors.red200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radius8),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const Gap(AppSpacing.spacing8),
                    // Approve button
                    Expanded(
                      child: FilledButton(
                        onPressed: selectedWallet != null ? () => onApprove(selectedWallet) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green200,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radius8),
                          ),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Find matching category from categoryHint
  static Category? _findMatchingCategory(
    List<Category> categories,
    ParsedEmailTransaction transaction,
  ) {
    // If already has selectedCategoryId, find that category
    if (transaction.selectedCategoryId != null) {
      try {
        return categories.firstWhere((c) => c.id == transaction.selectedCategoryId);
      } catch (_) {
        // Category not found, continue to categoryHint matching
      }
    }

    // Try to match by categoryHint
    if (transaction.categoryHint == null || transaction.categoryHint!.isEmpty) {
      return null;
    }

    final hint = transaction.categoryHint!.toLowerCase();

    // First try exact match (case-insensitive)
    for (final category in categories) {
      if (category.title.toLowerCase() == hint) {
        return category;
      }
    }

    // Then try contains match
    for (final category in categories) {
      if (category.title.toLowerCase().contains(hint) ||
          hint.contains(category.title.toLowerCase())) {
        return category;
      }
    }

    return null;
  }

  /// Auto-match and save category from categoryHint
  static Future<void> _autoMatchAndSaveCategory(
    AppDatabase db,
    ParsedEmailTransaction transaction,
  ) async {
    try {
      final categories = await db.categoryDao.watchAllCategories().first;
      final matched = _findMatchingCategory(categories, transaction);

      if (matched != null) {
        // Save matched category to database
        await db.parsedEmailTransactionDao.updateParsedTransaction(
          id: transaction.id,
          selectedCategoryId: matched.id,
        );
      }
    } catch (e) {
      // Silently fail - category matching is optional
    }
  }

  /// Convert iconTypeValue string to IconType enum
  static IconType _getIconType(String? iconTypeValue) {
    switch (iconTypeValue) {
      case 'emoji':
        return IconType.emoji;
      case 'initial':
        return IconType.initial;
      case 'asset':
        return IconType.asset;
      default:
        return IconType.asset;
    }
  }
}
