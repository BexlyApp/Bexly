import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/services/auto_transaction/bank_wallet_mapping.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

/// Result of user selection from scan results dialog
class ScanSelectionResult {
  final List<SmsScanResult> selectedSenders;
  final Map<String, int?> mergeWalletMap; // bankCode -> existing walletId (null = create new)

  ScanSelectionResult({
    required this.selectedSenders,
    required this.mergeWalletMap,
  });
}

/// Dialog to show SMS scan results and let user select which banks to create wallets for
class SmsScanResultsDialog extends ConsumerStatefulWidget {
  final List<SmsScanResult> scanResults;
  final List<WalletModel> existingWallets;

  const SmsScanResultsDialog({
    super.key,
    required this.scanResults,
    required this.existingWallets,
  });

  static Future<ScanSelectionResult?> show({
    required BuildContext context,
    required List<SmsScanResult> scanResults,
    required List<WalletModel> existingWallets,
  }) {
    return showDialog<ScanSelectionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SmsScanResultsDialog(
        scanResults: scanResults,
        existingWallets: existingWallets,
      ),
    );
  }

  @override
  ConsumerState<SmsScanResultsDialog> createState() => _SmsScanResultsDialogState();
}

class _SmsScanResultsDialogState extends ConsumerState<SmsScanResultsDialog> {
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            HugeIcons.strokeRoundedDiscoverCircle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              context.l10n.autoTransactionScanResultsTitle,
              style: AppTextStyles.heading5,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.autoTransactionScanResultsDescription(
                widget.scanResults.length,
              ),
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.scanResults.length,
                itemBuilder: (context, index) {
                  final result = widget.scanResults[index];
                  return _buildBankItem(result);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _selectedBankCodes.isEmpty ? null : _onConfirm,
          child: Text(context.l10n.autoTransactionCreateWallets(
            _selectedBankCodes.length,
          )),
        ),
      ],
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
      initialValue: selectedWalletId,
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
      child: Icon(
        HugeIcons.strokeRoundedBank,
        color: iconColor,
        size: 20,
      ),
    );
  }
}

/// Dialog showing scanning progress
class SmsScanningDialog extends StatelessWidget {
  final int current;
  final int total;
  final String status;

  const SmsScanningDialog({
    super.key,
    required this.current,
    required this.total,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    );
  }
}

/// Dialog showing import progress
class TransactionImportDialog extends StatelessWidget {
  final int current;
  final int total;
  final String bankName;

  const TransactionImportDialog({
    super.key,
    required this.current,
    required this.total,
    required this.bankName,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    );
  }
}

/// Dialog showing import results summary
class ImportResultsDialog extends StatelessWidget {
  final int walletsCreated;
  final int transactionsImported;
  final int duplicatesSkipped;

  const ImportResultsDialog({
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
    return showDialog(
      context: context,
      builder: (context) => ImportResultsDialog(
        walletsCreated: walletsCreated,
        transactionsImported: transactionsImported,
        duplicatesSkipped: duplicatesSkipped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            color: Colors.green,
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Text(
            context.l10n.autoTransactionImportComplete,
            style: AppTextStyles.heading5,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.ok),
        ),
      ],
    );
  }

  Widget _buildResultRow(BuildContext context, IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.primary),
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
