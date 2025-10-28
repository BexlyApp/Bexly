import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:bexly/core/services/sync/conflict_resolution_service.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';

/// Dialog to resolve sync conflicts between local and cloud data
class ConflictResolutionDialog extends StatelessWidget {
  final SyncConflictInfo conflictInfo;

  const ConflictResolutionDialog({
    super.key,
    required this.conflictInfo,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spacing20,
        AppSpacing.spacing12,
        AppSpacing.spacing20,
        AppSpacing.spacing32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with warning icon
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Sync Conflict Detected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.spacing16),

            // Description
            Text(
              'You have data on both this device and in the cloud. Please choose which data to keep:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(AppSpacing.spacing24),

            // Local Data Card
            _DataCard(
              title: '📱 This Device (Local)',
              itemCount: conflictInfo.localItemCount,
              walletCount: conflictInfo.localWalletCount,
              transactionCount: conflictInfo.localTransactionCount,
              lastUpdate: conflictInfo.localLastUpdate,
              latestTransaction: conflictInfo.latestLocalTransaction,
              dateFormat: dateFormat,
              color: Colors.blue,
            ),
            const Gap(AppSpacing.spacing16),

            // Cloud Data Card
            _DataCard(
              title: '☁️ Cloud Data',
              itemCount: conflictInfo.cloudItemCount,
              walletCount: conflictInfo.cloudWalletCount,
              transactionCount: conflictInfo.cloudTransactionCount,
              lastUpdate: conflictInfo.cloudLastUpdate,
              latestTransaction: conflictInfo.latestCloudTransaction,
              dateFormat: dateFormat,
              color: Colors.green,
            ),
            const Gap(AppSpacing.spacing16),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'The data you don\'t choose will be permanently deleted and cannot be recovered.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.spacing24),

            // Buttons - 3 buttons vertical stacking
            Column(
              spacing: AppSpacing.spacing12,
              children: [
                // Use Cloud Data button (primary action)
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Use Cloud Data',
                    onPressed: () => Navigator.pop(context, ConflictResolution.useCloud),
                  ),
                ),

                // Use Local Data button (secondary action)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context, ConflictResolution.useLocal),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Use Local Data'),
                  ),
                ),

                // Cancel button (tertiary action)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
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

class _DataCard extends StatelessWidget {
  final String title;
  final int itemCount;
  final int walletCount;
  final int transactionCount;
  final DateTime? lastUpdate;
  final String? latestTransaction;
  final DateFormat dateFormat;
  final Color color;

  const _DataCard({
    required this.title,
    required this.itemCount,
    required this.walletCount,
    required this.transactionCount,
    required this.lastUpdate,
    required this.latestTransaction,
    required this.dateFormat,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(12),
          _InfoRow(
            icon: Icons.receipt_long,
            label: 'Total items:',
            value: '$itemCount',
          ),
          const Gap(8),
          _InfoRow(
            icon: Icons.account_balance_wallet,
            label: 'Wallets:',
            value: '$walletCount',
          ),
          const Gap(8),
          _InfoRow(
            icon: Icons.receipt,
            label: 'Transactions:',
            value: '$transactionCount',
          ),
          const Gap(8),
          if (lastUpdate != null)
            _InfoRow(
              icon: Icons.access_time,
              label: 'Last updated:',
              value: dateFormat.format(lastUpdate!),
            )
          else
            _InfoRow(
              icon: Icons.access_time,
              label: 'Last updated:',
              value: 'No transaction data',
            ),
          const Gap(8),
          if (latestTransaction != null)
            _InfoRow(
              icon: Icons.receipt,
              label: 'Latest transaction:',
              value: latestTransaction!,
            )
          else
            _InfoRow(
              icon: Icons.receipt,
              label: 'Latest transaction:',
              value: 'None',
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const Gap(8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const Gap(4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// Result of conflict resolution
enum ConflictResolution {
  useLocal,
  useCloud,
}
