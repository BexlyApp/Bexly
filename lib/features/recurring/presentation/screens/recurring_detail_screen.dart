import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/features/recurring/data/model/recurring_model.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/transaction/data/model/transaction_model.dart';
import 'package:intl/intl.dart';

class RecurringDetailScreen extends HookConsumerWidget {
  final RecurringModel recurring;

  const RecurringDetailScreen({
    super.key,
    required this.recurring,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    // Watch payment history using the new query method
    final paymentHistoryStream = useMemoized(
      () => db.transactionDao.watchTransactionsByRecurringId(recurring.id!),
      [recurring.id],
    );
    final paymentHistorySnapshot = useStream(paymentHistoryStream);

    final daysUntilDue = recurring.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;
    final isDueToday = daysUntilDue == 0;

    return CustomScaffold(
      context: context,
      title: recurring.name,
      showBackButton: true,
      showBalance: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount',
                          style: AppTextStyles.body3.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${recurring.amount.toPriceFormat()} ${recurring.currency}',
                          style: AppTextStyles.numericLarge.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    const Divider(),
                    const SizedBox(height: AppSpacing.spacing16),

                    // Frequency
                    _InfoRow(
                      icon: Icons.repeat,
                      label: 'Frequency',
                      value: recurring.frequency.displayName,
                    ),
                    const SizedBox(height: AppSpacing.spacing12),

                    // Next Due Date
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Next Due Date',
                      value: DateFormat('MMM dd, yyyy').format(recurring.nextDueDate),
                      valueColor: isOverdue
                          ? Colors.red
                          : isDueToday
                              ? Colors.orange
                              : null,
                      badge: isOverdue
                          ? 'Overdue'
                          : isDueToday
                              ? 'Due Today'
                              : daysUntilDue < 7
                                  ? 'Due in $daysUntilDue days'
                                  : null,
                      badgeColor: isOverdue
                          ? Colors.red
                          : isDueToday
                              ? Colors.orange
                              : Colors.green,
                    ),
                    const SizedBox(height: AppSpacing.spacing12),

                    // Category
                    _InfoRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: recurring.category.title,
                    ),
                    const SizedBox(height: AppSpacing.spacing12),

                    // Wallet
                    _InfoRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Wallet',
                      value: recurring.wallet.name,
                    ),
                    const SizedBox(height: AppSpacing.spacing12),

                    // Auto Charge Status
                    _InfoRow(
                      icon: recurring.autoCharge
                          ? Icons.check_circle
                          : Icons.cancel,
                      label: 'Auto Charge',
                      value: recurring.autoCharge ? 'Enabled' : 'Disabled',
                      valueColor: recurring.autoCharge
                          ? Colors.green
                          : Colors.grey,
                    ),

                    if (recurring.notes != null && recurring.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.spacing12),
                      _InfoRow(
                        icon: Icons.notes,
                        label: 'Notes',
                        value: recurring.notes!,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.spacing24),

            // Payment History Section
            Text(
              'Payment History',
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),

            // Payment History List
            _buildPaymentHistorySection(context, paymentHistorySnapshot),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistorySection(
    BuildContext context,
    AsyncSnapshot<List<TransactionModel>> snapshot,
  ) {
    // Loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (snapshot.hasError) {
      return Card(
        elevation: 0,
        color: Colors.red.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Text(
            'Error loading payment history: ${snapshot.error}',
            style: AppTextStyles.body4.copyWith(
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    // No data or empty data
    final payments = snapshot.data ?? [];
    if (payments.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(127),
              ),
              const SizedBox(height: AppSpacing.spacing12),
              Text(
                'No payment history yet',
                style: AppTextStyles.body3.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                'Payments will appear here when auto-charged',
                style: AppTextStyles.body4.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(178),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Has data - show payment history
    return Column(
      children: [
        // Summary card
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer.withAlpha(76),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${payments.length}',
                      style: AppTextStyles.numericLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Total Payments',
                      style: AppTextStyles.body4.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                Column(
                  children: [
                    Text(
                      (payments.fold<double>(
                        0,
                        (sum, payment) => sum + payment.amount,
                      )).toPriceFormat(),
                      style: AppTextStyles.numericLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Total Spent',
                      style: AppTextStyles.body4.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing16),

        // Payment list
        ...payments.map((payment) => _PaymentHistoryItem(
          payment: payment,
          currency: recurring.currency,
        )),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final String? badge;
  final Color? badgeColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body4.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: AppTextStyles.body3.copyWith(
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? Colors.grey).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.body5.copyWith(
                          color: badgeColor ?? Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final TransactionModel payment;
  final String currency;

  const _PaymentHistoryItem({
    required this.payment,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing16,
          vertical: AppSpacing.spacing8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          DateFormat('MMMM dd, yyyy').format(payment.date),
          style: AppTextStyles.body3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Auto-charged',
          style: AppTextStyles.body4.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '${payment.amount.toPriceFormat()} $currency',
          style: AppTextStyles.numericMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
