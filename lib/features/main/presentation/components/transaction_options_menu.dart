import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:pockaw/core/constants/app_colors.dart';
import 'package:pockaw/core/constants/app_radius.dart';
import 'package:pockaw/core/constants/app_spacing.dart';
import 'package:pockaw/core/router/routes.dart';

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
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.scanReceipt);
            },
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radius8),
              ),
              child: Icon(
                HugeIcons.strokeRoundedScanQrCode,
                color: AppColors.success,
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