import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:bexly/core/services/sync/conflict_resolution_service.dart';

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

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 28,
          ),
          const Gap(12),
          Expanded(
            child: Text(
              'Sync Conflict Detected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have data on both this device and in the cloud. Please choose which data to keep:',
              style: TextStyle(fontSize: 14),
            ),
            const Gap(24),

            // Local Data Card
            _DataCard(
              title: '📱 This Device (Local)',
              itemCount: conflictInfo.localItemCount,
              lastUpdate: conflictInfo.localLastUpdate,
              latestTransaction: conflictInfo.latestLocalTransaction,
              dateFormat: dateFormat,
              color: Colors.blue,
            ),
            const Gap(16),

            // Cloud Data Card
            _DataCard(
              title: '☁️ Cloud Data',
              itemCount: conflictInfo.cloudItemCount,
              lastUpdate: conflictInfo.cloudLastUpdate,
              latestTransaction: conflictInfo.latestCloudTransaction,
              dateFormat: dateFormat,
              color: Colors.green,
            ),
            const Gap(16),

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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, ConflictResolution.useLocal),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue.shade100,
            foregroundColor: Colors.blue.shade900,
          ),
          child: Text('Use Local Data'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ConflictResolution.useCloud),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade600,
          ),
          child: Text('Use Cloud Data'),
        ),
      ],
    );
  }
}

class _DataCard extends StatelessWidget {
  final String title;
  final int itemCount;
  final DateTime? lastUpdate;
  final String? latestTransaction;
  final DateFormat dateFormat;
  final Color color;

  const _DataCard({
    required this.title,
    required this.itemCount,
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
          if (lastUpdate != null)
            _InfoRow(
              icon: Icons.access_time,
              label: 'Last updated:',
              value: dateFormat.format(lastUpdate!),
            ),
          if (latestTransaction != null) ...[
            const Gap(8),
            _InfoRow(
              icon: Icons.receipt,
              label: 'Latest transaction:',
              value: latestTransaction!,
            ),
          ],
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
