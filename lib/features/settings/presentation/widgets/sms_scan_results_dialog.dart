import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/services/auto_transaction/bank_wallet_mapping.dart';
import 'package:bexly/core/services/auto_transaction/auto_transaction_service.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

/// Result of user selection from scan results bottom sheet
class ScanSelectionResult {
  final List<SmsScanResult> selectedSenders;
  final Map<String, int?> mergeWalletMap; // bankCode -> existing walletId (null = create new)

  ScanSelectionResult({
    required this.selectedSenders,
    required this.mergeWalletMap,
  });
}

/// Bottom sheet to show SMS scan results and let user select which banks to create wallets for
class SmsScanResultsBottomSheet extends ConsumerStatefulWidget {
  final List<SmsScanResult> scanResults;
  final List<WalletModel> existingWallets;

  const SmsScanResultsBottomSheet({
    super.key,
    required this.scanResults,
    required this.existingWallets,
  });

  static Future<ScanSelectionResult?> show({
    required BuildContext context,
    required List<SmsScanResult> scanResults,
    required List<WalletModel> existingWallets,
  }) {
    return showModalBottomSheet<ScanSelectionResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) => SmsScanResultsBottomSheet(
        scanResults: scanResults,
        existingWallets: existingWallets,
      ),
    );
  }

  @override
  ConsumerState<SmsScanResultsBottomSheet> createState() => _SmsScanResultsBottomSheetState();
}

class _SmsScanResultsBottomSheetState extends ConsumerState<SmsScanResultsBottomSheet> {
  late Set<String> _selectedBankCodes;
  late Map<String, int?> _mergeWalletMap; // bankCode -> walletId (null = create new)

  @override
  void initState() {
    super.initState();
    // Select all by default
    _selectedBankCodes = widget.scanResults.map((r) => r.bankCode).toSet();
    _mergeWalletMap = {};

    // Check for existing wallets with matching names
    for (final result in widget.scanResults) {
      final matchingWallet = _findMatchingWallet(result.bankName);
      if (matchingWallet != null) {
        _mergeWalletMap[result.bankCode] = matchingWallet.id;
      }
    }
  }

  WalletModel? _findMatchingWallet(String bankName) {
    final normalizedBankName = bankName.toLowerCase();
    for (final wallet in widget.existingWallets) {
      if (wallet.name.toLowerCase().contains(normalizedBankName) ||
          normalizedBankName.contains(wallet.name.toLowerCase())) {
        return wallet;
      }
    }
    return null;
  }

  void _toggleSelection(String bankCode) {
    setState(() {
      if (_selectedBankCodes.contains(bankCode)) {
        _selectedBankCodes.remove(bankCode);
      } else {
        _selectedBankCodes.add(bankCode);
      }
    });
  }

  void _setMergeWallet(String bankCode, int? walletId) {
    setState(() {
      if (walletId == null) {
        _mergeWalletMap.remove(bankCode);
      } else {
        _mergeWalletMap[bankCode] = walletId;
      }
    });
  }

  void _onConfirm() {
    final selectedResults = widget.scanResults
        .where((r) => _selectedBankCodes.contains(r.bankCode))
        .toList();

    Navigator.of(context).pop(ScanSelectionResult(
      selectedSenders: selectedResults,
      mergeWalletMap: _mergeWalletMap,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.radius20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.spacing12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.spacing20),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedDiscoverCircle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.autoTransactionScanResultsTitle,
                            style: AppTextStyles.heading5,
                          ),
                          const SizedBox(height: AppSpacing.spacing4),
                          Text(
                            context.l10n.autoTransactionScanResultsDescription(
                              widget.scanResults.length,
                            ),
                            style: AppTextStyles.body4.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.spacing16),
                  itemCount: widget.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = widget.scanResults[index];
                    return _buildBankItem(result);
                  },
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _selectedBankCodes.isEmpty ? null : _onConfirm,
                          child: Text(context.l10n.autoTransactionCreateWallets(
                            _selectedBankCodes.length,
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBankItem(SmsScanResult result) {
    final isSelected = _selectedBankCodes.contains(result.bankCode);
    final mergeWalletId = _mergeWalletMap[result.bankCode];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Column(
        children: [
          CheckboxListTile(
            value: isSelected,
            onChanged: (_) => _toggleSelection(result.bankCode),
            title: Text(
              result.bankName,
              style: AppTextStyles.body3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${result.messageCount} SMS${result.detectedCurrency != null ? ' • ${result.detectedCurrency}' : ''}',
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            secondary: _getBankIcon(result.bankCode),
          ),
          if (isSelected && widget.existingWallets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.spacing16,
                right: AppSpacing.spacing16,
                bottom: AppSpacing.spacing12,
              ),
              child: _buildWalletSelector(result, mergeWalletId),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletSelector(SmsScanResult result, int? selectedWalletId) {
    return DropdownButtonFormField<int?>(
      value: selectedWalletId,
      decoration: InputDecoration(
        labelText: context.l10n.autoTransactionTargetWallet,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing12,
          vertical: AppSpacing.spacing8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: AppSpacing.spacing8),
              Text(context.l10n.autoTransactionCreateNewWallet),
            ],
          ),
        ),
        ...widget.existingWallets.map((wallet) => DropdownMenuItem<int?>(
              value: wallet.id,
              child: Text(
                '${wallet.name} (${wallet.currency})',
                overflow: TextOverflow.ellipsis,
              ),
            )),
      ],
      onChanged: (value) => _setMergeWallet(result.bankCode, value),
    );
  }

  Widget _getBankIcon(String bankCode) {
    // Return different colors based on bank type
    Color iconColor;
    switch (bankCode.toUpperCase()) {
      case 'VCB':
        iconColor = const Color(0xFF006A4E); // Vietcombank green
        break;
      case 'TCB':
        iconColor = const Color(0xFFE31837); // Techcombank red
        break;
      case 'TPB':
        iconColor = const Color(0xFF5B2D8E); // TPBank purple
        break;
      case 'MOMO':
        iconColor = const Color(0xFFD82D8B); // MoMo pink
        break;
      case 'BIDV':
        iconColor = const Color(0xFF005BA1); // BIDV blue
        break;
      case 'MB':
        iconColor = const Color(0xFF004B87); // MB Bank blue
        break;
      default:
        iconColor = Theme.of(context).colorScheme.primary;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(alpha: 0.1),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedBank,
        color: iconColor,
        size: 20,
      ),
    );
  }
}

/// Bottom sheet showing scanning progress
class SmsScanningBottomSheet extends StatelessWidget {
  final int current;
  final int total;
  final String status;

  const SmsScanningBottomSheet({
    super.key,
    required this.current,
    required this.total,
    required this.status,
  });

  static void show({
    required BuildContext context,
    required int current,
    required int total,
    required String status,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => SmsScanningBottomSheet(
        current: current,
        total: total,
        status: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircularProgressIndicator(value: progress > 0 ? progress : null),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              status,
              style: AppTextStyles.body3,
              textAlign: TextAlign.center,
            ),
            if (total > 0) ...[
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                '$current / $total',
                style: AppTextStyles.body4.copyWith(
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing import progress
class TransactionImportBottomSheet extends StatelessWidget {
  final int current;
  final int total;
  final String bankName;

  const TransactionImportBottomSheet({
    super.key,
    required this.current,
    required this.total,
    required this.bankName,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircularProgressIndicator(value: progress > 0 ? progress : null),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              context.l10n.autoTransactionImporting(bankName),
              style: AppTextStyles.body3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              '$current / $total',
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing import results summary
class ImportResultsBottomSheet extends StatelessWidget {
  final int walletsCreated;
  final int transactionsImported;
  final int duplicatesSkipped;

  const ImportResultsBottomSheet({
    super.key,
    required this.walletsCreated,
    required this.transactionsImported,
    required this.duplicatesSkipped,
  });

  static Future<void> show({
    required BuildContext context,
    required int walletsCreated,
    required int transactionsImported,
    required int duplicatesSkipped,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => ImportResultsBottomSheet(
        walletsCreated: walletsCreated,
        transactionsImported: transactionsImported,
        duplicatesSkipped: duplicatesSkipped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Success icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              context.l10n.autoTransactionImportComplete,
              style: AppTextStyles.heading5,
            ),
            const SizedBox(height: AppSpacing.spacing20),
            _buildResultRow(
              context,
              HugeIcons.strokeRoundedWallet03,
              context.l10n.autoTransactionWalletsCreated(walletsCreated),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            _buildResultRow(
              context,
              HugeIcons.strokeRoundedTransaction,
              context.l10n.autoTransactionTransactionsImported(transactionsImported),
            ),
            if (duplicatesSkipped > 0) ...[
              const SizedBox(height: AppSpacing.spacing8),
              _buildResultRow(
                context,
                HugeIcons.strokeRoundedCancel01,
                context.l10n.autoTransactionDuplicatesSkipped(duplicatesSkipped),
                color: AppColors.neutral500,
              ),
            ],
            const SizedBox(height: AppSpacing.spacing24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.ok),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, List<List> icon, String text, {Color? color}) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 20, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body3.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet showing no results
class NoResultsBottomSheet extends StatelessWidget {
  const NoResultsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => const NoResultsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Empty state icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSearchMinus,
                color: AppColors.neutral500,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              context.l10n.autoTransactionNoResults,
              style: AppTextStyles.heading5,
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              context.l10n.autoTransactionNoResultsDescription,
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.ok),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for permission denied
class PermissionDeniedBottomSheet extends StatelessWidget {
  final String feature;

  const PermissionDeniedBottomSheet({
    super.key,
    required this.feature,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String feature,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (context) => PermissionDeniedBottomSheet(feature: feature),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Warning icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              context.l10n.autoTransaction,
              style: AppTextStyles.heading5,
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              'Permission required for $feature. Please enable it in Settings.',
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Open Settings'),
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

/// Bottom sheet to manage pending notifications
class PendingNotificationsBottomSheet extends StatefulWidget {
  final PendingNotificationSummary summary;
  final List<WalletModel> existingWallets;

  const PendingNotificationsBottomSheet({
    super.key,
    required this.summary,
    required this.existingWallets,
  });

  static Future<Map<String, int?>?> show({
    required BuildContext context,
    required PendingNotificationSummary summary,
    required List<WalletModel> existingWallets,
  }) {
    return showModalBottomSheet<Map<String, int?>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PendingNotificationsBottomSheet(
        summary: summary,
        existingWallets: existingWallets,
      ),
    );
  }

  @override
  State<PendingNotificationsBottomSheet> createState() => _PendingNotificationsBottomSheetState();
}

class _PendingNotificationsBottomSheetState extends State<PendingNotificationsBottomSheet> {
  // mappingKey -> walletId (null = create new, 0 = ignore)
  late Map<String, int?> _decisions;

  @override
  void initState() {
    super.initState();
    _decisions = {};
    // Default: create new wallet for each group
    for (final group in widget.summary.groups) {
      _decisions[group.mappingKey] = group.existingWalletId; // Use existing if already mapped
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.radius20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.spacing12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.spacing20),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedNotificationBubble,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Notifications',
                            style: AppTextStyles.heading5,
                          ),
                          const SizedBox(height: AppSpacing.spacing4),
                          Text(
                            '${widget.summary.totalNotifications} transaction(s) from ${widget.summary.groups.length} source(s)',
                            style: AppTextStyles.body4.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.spacing16),
                  itemCount: widget.summary.groups.length,
                  itemBuilder: (context, index) {
                    final group = widget.summary.groups[index];
                    return _buildGroupItem(group);
                  },
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _decisions.values.any((v) => v != 0)
                              ? () => Navigator.of(context).pop(_decisions)
                              : null,
                          child: const Text('Process'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupItem(PendingNotificationGroup group) {
    final decision = _decisions[group.mappingKey];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedBank,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.displayName,
                        style: AppTextStyles.body3.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${group.notificationCount} transaction(s)',
                        style: AppTextStyles.body4.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing12),
            // Action selector
            DropdownButtonFormField<int?>(
              value: decision,
              decoration: InputDecoration(
                labelText: 'Action',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing12,
                  vertical: AppSpacing.spacing8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: AppSpacing.spacing8),
                      Text('Create new wallet'),
                    ],
                  ),
                ),
                const DropdownMenuItem<int?>(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: AppSpacing.spacing8),
                      Text('Ignore'),
                    ],
                  ),
                ),
                ...widget.existingWallets
                    .where((wallet) => wallet.id != null)
                    .map((wallet) => DropdownMenuItem<int?>(
                          value: wallet.id!,
                          child: Text(
                            '${wallet.name} (${wallet.currency})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
              ],
              onChanged: (value) {
                setState(() {
                  _decisions[group.mappingKey] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple processing bottom sheet (for pending notifications processing)
class ProcessingBottomSheet extends StatelessWidget {
  final String message;

  const ProcessingBottomSheet({
    super.key,
    required this.message,
  });

  static void show({
    required BuildContext context,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => ProcessingBottomSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.spacing20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              message,
              style: AppTextStyles.body3,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Re-export for backward compatibility (classes that need to be imported)
typedef SmsScanResultsDialog = SmsScanResultsBottomSheet;
typedef SmsScanningDialog = SmsScanningBottomSheet;
typedef TransactionImportDialog = TransactionImportBottomSheet;
typedef ImportResultsDialog = ImportResultsBottomSheet;
