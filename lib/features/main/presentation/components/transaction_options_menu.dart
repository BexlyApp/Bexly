import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';

class TransactionOptionsMenu extends StatelessWidget {
  const TransactionOptionsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.transactionForm);
            },
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radius8),
              ),
              child: Icon(
                HugeIcons.strokeRoundedEdit02,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              'Add Manually',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Enter transaction details manually',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            onTap: () async {
              Navigator.pop(context);
              Log.d('🔵 Opening receipt scanner', label: 'TransactionOptions');
              final result = await context.push<ReceiptScanResult>(Routes.scanReceipt);
              Log.d('🔵 Received result from scanner: $result', label: 'TransactionOptions');
              Log.d('🔵 Result is null: ${result == null}', label: 'TransactionOptions');
              Log.d('🔵 Context mounted: ${context.mounted}', label: 'TransactionOptions');
              if (result != null && context.mounted) {
                Log.d('🔵 Navigating to transaction form with result', label: 'TransactionOptions');
                context.push(Routes.transactionForm, extra: result);
              } else {
                Log.d('🔵 FAILED: Result is null=${result == null} or context not mounted=${!context.mounted}', label: 'TransactionOptions');
              }
            },
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              decoration: BoxDecoration(
                color: AppColors.greenAlpha10,
                borderRadius: BorderRadius.circular(AppRadius.radius8),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                color: AppColors.green200,
              ),
            ),
            title: Text(
              'Scan Receipt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Capture receipt with camera',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}