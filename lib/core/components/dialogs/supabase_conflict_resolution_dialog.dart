import 'package:flutter/material.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/services/sync/supabase_conflict_resolution_service.dart';
import 'package:intl/intl.dart';

/// Dialog to resolve sync conflicts between local and cloud data
class SupabaseConflictResolutionDialog extends StatelessWidget {
  final SupabaseSyncConflictInfo conflictInfo;
  final VoidCallback onUseCloudData;
  final VoidCallback onUseLocalData;
  final VoidCallback onCancel;

  const SupabaseConflictResolutionDialog({
    super.key,
    required this.conflictInfo,
    required this.onUseCloudData,
    required this.onUseLocalData,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.spacing16,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Text(
                    'Sync Conflict Detected',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            // Explanation
            Text(
              'Both your device and the cloud have data. Which one would you like to keep?',
              style: AppTextStyles.body2,
            ),

            Divider(),

            // Data comparison
            _DataComparisonSection(
              title: 'Local Data (This Device)',
              walletCount: conflictInfo.localWalletCount,
              transactionCount: conflictInfo.localTransactionCount,
              goalCount: conflictInfo.localGoalCount,
              budgetCount: conflictInfo.localBudgetCount,
              lastUpdate: conflictInfo.localLastUpdate,
              latestTransaction: conflictInfo.latestLocalTransaction,
              dateFormat: dateFormat,
            ),

            _DataComparisonSection(
              title: 'Cloud Data',
              walletCount: conflictInfo.cloudWalletCount,
              transactionCount: conflictInfo.cloudTransactionCount,
              goalCount: conflictInfo.cloudGoalCount,
              budgetCount: conflictInfo.cloudBudgetCount,
              lastUpdate: conflictInfo.cloudLastUpdate,
              latestTransaction: conflictInfo.latestCloudTransaction,
              dateFormat: dateFormat,
            ),

            Divider(),

            // Warning
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: AppSpacing.spacing8),
                  Expanded(
                    child: Text(
                      'Warning: The data you DON\'T choose will be permanently deleted!',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Row(
              spacing: AppSpacing.spacing12,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: PrimaryButton(
                    text: 'Use Cloud',
                    onPressed: onUseCloudData,
                    backgroundColor: AppColors.blue,
                  ),
                ),
                Expanded(
                  child: PrimaryButton(
                    text: 'Use Local',
                    onPressed: onUseLocalData,
                    backgroundColor: AppColors.green,
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

class _DataComparisonSection extends StatelessWidget {
  final String title;
  final int walletCount;
  final int transactionCount;
  final int goalCount;
  final int budgetCount;
  final DateTime? lastUpdate;
  final String? latestTransaction;
  final DateFormat dateFormat;

  const _DataComparisonSection({
    required this.title,
    required this.walletCount,
    required this.transactionCount,
    required this.goalCount,
    required this.budgetCount,
    this.lastUpdate,
    this.latestTransaction,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.spacing8,
      children: [
        Text(
          title,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
        ),
        _DataRow(label: 'Wallets', count: walletCount),
        _DataRow(label: 'Transactions', count: transactionCount),
        _DataRow(label: 'Goals', count: goalCount),
        _DataRow(label: 'Budgets', count: budgetCount),
        if (lastUpdate != null)
          Text(
            'Last updated: ${dateFormat.format(lastUpdate!)}',
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
          ),
        if (latestTransaction != null)
          Text(
            'Latest: $latestTransaction',
            style: AppTextStyles.caption.copyWith(color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final int count;

  const _DataRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:', style: AppTextStyles.body2),
        Text('$count', style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
