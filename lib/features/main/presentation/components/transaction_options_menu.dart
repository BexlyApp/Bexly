import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/receipt_scanner/data/models/receipt_scan_result.dart';
import 'package:bexly/features/transaction/presentation/screens/transaction_form.dart';

class TransactionOptionsMenu extends StatelessWidget {
  const TransactionOptionsMenu({super.key});

  /// Shows transaction form as dialog on desktop, or navigates to full page on mobile
  static void showTransactionForm(
    BuildContext context, {
    int? transactionId,
    ReceiptScanResult? receiptData,
  }) {
    if (context.isDesktopLayout) {
      // On desktop, show as dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 80,
            vertical: 40,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radius16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TransactionForm(
                transactionId: transactionId,
                receiptData: receiptData,
              ),
            ),
          ),
        ),
      );
    } else {
      // On mobile, navigate to full page
      if (transactionId != null) {
        context.push('/transaction/$transactionId');
      } else {
        context.push(Routes.transactionForm, extra: receiptData);
      }
    }
  }

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
              showTransactionForm(context);
            },
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.radius8),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedEdit02,
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
              if (kIsWeb) {
                // On web, use image picker to upload receipt
                Log.d('🔵 Opening image picker for receipt upload', label: 'TransactionOptions');
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null && context.mounted) {
                  Log.d('🔵 Image selected: ${image.path}', label: 'TransactionOptions');
                  // Navigate to receipt scanner with uploaded image
                  context.push(Routes.scanReceipt, extra: image.path);
                }
              } else {
                // On mobile, use camera scanner
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
              }
            },
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.spacing8),
              decoration: BoxDecoration(
                color: AppColors.greenAlpha10,
                borderRadius: BorderRadius.circular(AppRadius.radius8),
              ),
              child: Icon(
                kIsWeb ? Icons.upload_file_outlined : Icons.camera_alt_outlined,
                color: AppColors.green200,
              ),
            ),
            title: Text(
              kIsWeb ? 'Upload Receipt' : 'Scan Receipt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              kIsWeb ? 'Upload receipt image from device' : 'Capture receipt with camera',
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