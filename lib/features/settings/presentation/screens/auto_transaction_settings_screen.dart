import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/services/auto_transaction/auto_transaction_service.dart';
import 'package:bexly/core/services/auto_transaction/bank_wallet_mapping.dart';
import 'package:bexly/features/settings/presentation/widgets/sms_scan_results_dialog.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

/// Auto Transaction settings providers
final autoTransactionSmsEnabledProvider = StateProvider<bool>((ref) => false);
final autoTransactionNotificationEnabledProvider = StateProvider<bool>((ref) => false);
final autoTransactionDefaultWalletIdProvider = StateProvider<int?>((ref) => null);

class AutoTransactionSettingsScreen extends ConsumerStatefulWidget {
  const AutoTransactionSettingsScreen({super.key});

  @override
  ConsumerState<AutoTransactionSettingsScreen> createState() =>
      _AutoTransactionSettingsScreenState();
}

class _AutoTransactionSettingsScreenState
    extends ConsumerState<AutoTransactionSettingsScreen> {
  bool _isLoading = true;
  bool _isScanning = false;
  int _scanProgress = 0;
  int _scanTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      ref.read(autoTransactionSmsEnabledProvider.notifier).state =
          prefs.getBool('auto_transaction_sms_enabled') ?? false;
      ref.read(autoTransactionNotificationEnabledProvider.notifier).state =
          prefs.getBool('auto_transaction_notification_enabled') ?? false;
      ref.read(autoTransactionDefaultWalletIdProvider.notifier).state =
          prefs.getInt('auto_transaction_default_wallet_id');

      setState(() => _isLoading = false);
    } catch (e) {
      Log.e('Failed to load auto transaction settings: $e', label: 'AutoTransaction');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value == null) {
        await prefs.remove(key);
      }
      Log.d('Saved $key: $value', label: 'AutoTransaction');
    } catch (e) {
      Log.e('Failed to save auto transaction setting: $e', label: 'AutoTransaction');
    }
  }

  Future<void> _toggleSmsSetting(bool value) async {
    if (value) {
      // Request SMS permission when enabling
      final status = await Permission.sms.request();
      if (!status.isGranted) {
        Log.w('SMS permission denied', label: 'AutoTransaction');
        // Show dialog explaining why permission is needed
        if (mounted) {
          _showPermissionDeniedDialog(context.l10n.autoTransactionSmsTitle);
        }
        return;
      }

      // Initialize auto transaction service
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.initialize();
      await autoService.setSmsEnabled(true);
    } else {
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.setSmsEnabled(false);
    }

    ref.read(autoTransactionSmsEnabledProvider.notifier).state = value;
    await _saveSetting('auto_transaction_sms_enabled', value);
  }

  void _showPermissionDeniedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.autoTransaction),
        content: Text('Permission required for $feature. Please enable it in Settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotificationSetting(bool value) async {
    if (value) {
      // Initialize auto transaction service and request notification permission
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.initialize();

      // Check if permission is granted
      final hasPermission = await autoService.hasNotificationPermission();
      if (!hasPermission) {
        // Show dialog explaining that user needs to grant permission in settings
        if (mounted) {
          final shouldOpenSettings = await _showNotificationPermissionDialog();
          if (shouldOpenSettings) {
            await autoService.requestNotificationPermission();
            // Check again after user returns from settings
            await Future.delayed(const Duration(milliseconds: 500));
            final granted = await autoService.hasNotificationPermission();
            if (!granted) {
              Log.w('Notification permission not granted', label: 'AutoTransaction');
              return;
            }
          } else {
            return;
          }
        }
      }

      await autoService.setNotificationEnabled(true);
    } else {
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.setNotificationEnabled(false);
    }

    ref.read(autoTransactionNotificationEnabledProvider.notifier).state = value;
    await _saveSetting('auto_transaction_notification_enabled', value);
  }

  Future<bool> _showNotificationPermissionDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.autoTransactionNotificationTitle),
        content: const Text(
          'This feature requires Notification Access permission. '
          'You will be taken to system settings to enable it for Bexly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _setDefaultWallet(int? walletId) async {
    ref.read(autoTransactionDefaultWalletIdProvider.notifier).state = walletId;
    await _saveSetting('auto_transaction_default_wallet_id', walletId);
  }

  Future<void> _scanSmsForBanks() async {
    // Request SMS permission first
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      if (mounted) {
        _showPermissionDeniedDialog(context.l10n.autoTransactionSmsTitle);
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanProgress = 0;
      _scanTotal = 0;
    });

    // Show scanning dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            return SmsScanningDialog(
              current: _scanProgress,
              total: _scanTotal,
              status: context.l10n.autoTransactionScanning,
            );
          },
        ),
      );
    }

    try {
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.initialize();

      final results = await autoService.scanSmsForBankSenders(
        onProgress: (current, total) {
          setState(() {
            _scanProgress = current;
            _scanTotal = total;
          });
        },
      );

      // Close scanning dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() => _isScanning = false);

      if (results.isEmpty) {
        // Show no results dialog
        if (mounted) {
          _showNoResultsDialog();
        }
        return;
      }

      // Get existing wallets
      final wallets = ref.read(allWalletsStreamProvider).valueOrNull ?? [];

      // Show results dialog
      if (mounted) {
        final selection = await SmsScanResultsDialog.show(
          context: context,
          scanResults: results,
          existingWallets: wallets,
        );

        if (selection != null && selection.selectedSenders.isNotEmpty) {
          await _processSelectedSenders(selection, autoService);
        }
      }
    } catch (e) {
      Log.e('Error scanning SMS: $e', label: 'AutoTransaction');
      if (mounted) {
        Navigator.of(context).pop(); // Close scanning dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning SMS: $e')),
        );
      }
      setState(() => _isScanning = false);
    }
  }

  Future<void> _processSelectedSenders(
    ScanSelectionResult selection,
    AutoTransactionService autoService,
  ) async {
    int walletsCreated = 0;
    int totalImported = 0;
    int totalDuplicates = 0;

    for (final sender in selection.selectedSenders) {
      int walletId;

      // Check if user wants to merge into existing wallet
      final mergeWalletId = selection.mergeWalletMap[sender.bankCode];

      if (mergeWalletId != null) {
        // Use existing wallet
        walletId = mergeWalletId;
        // Add mapping for existing wallet
        await autoService.addMappingForExistingWallet(
          senderId: sender.senderId,
          bankName: sender.bankName,
          bankCode: sender.bankCode,
          walletId: walletId,
        );
      } else {
        // Create new wallet
        final wallet = await autoService.createWalletForBank(
          bankName: sender.bankName,
          bankCode: sender.bankCode,
          senderId: sender.senderId,
          currency: sender.detectedCurrency ?? 'VND',
        );

        if (wallet == null || wallet.id == null) {
          Log.e('Failed to create wallet for ${sender.bankName}', label: 'AutoTransaction');
          continue;
        }

        walletId = wallet.id!;
        walletsCreated++;
      }

      // Show importing dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => TransactionImportDialog(
            current: 0,
            total: sender.messageCount,
            bankName: sender.bankName,
          ),
        );
      }

      // Import transactions
      final result = await autoService.importTransactionsForBank(
        bankCode: sender.bankCode,
        walletId: walletId,
        onProgress: (current, total) {
          // Progress is shown in dialog
        },
      );

      totalImported += result.imported;
      totalDuplicates += result.duplicates;

      // Close importing dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    }

    // Show final results
    if (mounted) {
      await ImportResultsDialog.show(
        context: context,
        walletsCreated: walletsCreated,
        transactionsImported: totalImported,
        duplicatesSkipped: totalDuplicates,
      );
    }
  }

  void _showNoResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.autoTransactionNoResults),
        content: Text(context.l10n.autoTransactionNoResultsDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = Platform.isAndroid;

    if (_isLoading) {
      return CustomScaffold(
        context: context,
        title: context.l10n.autoTransaction,
        showBalance: false,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final smsEnabled = ref.watch(autoTransactionSmsEnabledProvider);
    final notificationEnabled = ref.watch(autoTransactionNotificationEnabledProvider);
    final defaultWalletId = ref.watch(autoTransactionDefaultWalletIdProvider);
    final walletsAsync = ref.watch(allWalletsStreamProvider);

    return CustomScaffold(
      context: context,
      title: context.l10n.autoTransaction,
      showBalance: false,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        children: [
          // Info card
          _buildInfoCard(),

          const SizedBox(height: AppSpacing.spacing24),

          // SMS Parsing Section (Android only)
          if (isAndroid) ...[
            _buildSectionTitle(context.l10n.autoTransactionSms),
            const SizedBox(height: AppSpacing.spacing12),

            _buildSettingCard(
              title: context.l10n.autoTransactionSmsTitle,
              subtitle: context.l10n.autoTransactionSmsDescription,
              icon: HugeIcons.strokeRoundedMessage01,
              value: smsEnabled,
              onChanged: _toggleSmsSetting,
            ),

            const SizedBox(height: AppSpacing.spacing12),

            // Scan SMS Button
            _buildScanSmsButton(),

            const SizedBox(height: AppSpacing.spacing24),
          ],

          // Notification Listener Section (Android only)
          if (isAndroid) ...[
            _buildSectionTitle(context.l10n.autoTransactionNotification),
            const SizedBox(height: AppSpacing.spacing12),

            _buildSettingCard(
              title: context.l10n.autoTransactionNotificationTitle,
              subtitle: context.l10n.autoTransactionNotificationDescription,
              icon: HugeIcons.strokeRoundedNotification01,
              value: notificationEnabled,
              onChanged: _toggleNotificationSetting,
            ),

            const SizedBox(height: AppSpacing.spacing24),
          ],

          // Default Wallet Section
          _buildSectionTitle(context.l10n.autoTransactionDefaultWallet),
          const SizedBox(height: AppSpacing.spacing12),

          walletsAsync.when(
            data: (wallets) => _buildWalletSelector(wallets, defaultWalletId),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          // Platform notice for iOS
          if (!isAndroid) ...[
            const SizedBox(height: AppSpacing.spacing24),
            _buildPlatformNotice(),
          ],
        ],
      ),
    );
  }

  Widget _buildScanSmsButton() {
    return Card(
      child: ListTile(
        leading: Icon(
          HugeIcons.strokeRoundedSearch01,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          context.l10n.autoTransactionScanSms,
          style: AppTextStyles.body3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Scan your SMS inbox to find bank messages and create wallets',
          style: AppTextStyles.body4.copyWith(
            color: AppColors.neutral500,
          ),
        ),
        trailing: _isScanning
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.neutral400,
              ),
        onTap: _isScanning ? null : _scanSmsForBanks,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              HugeIcons.strokeRoundedInformationCircle,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                context.l10n.autoTransactionInfo,
                style: AppTextStyles.body4.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading5.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: value ? Theme.of(context).colorScheme.primary : AppColors.neutral400,
        ),
        title: Text(
          title,
          style: AppTextStyles.body3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.body4.copyWith(
            color: AppColors.neutral500,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildWalletSelector(List<WalletModel> wallets, int? selectedId) {
    return Card(
      child: Column(
        children: [
          // Default (use active wallet) option
          RadioListTile<int?>(
            title: Text(
              context.l10n.autoTransactionUseActiveWallet,
              style: AppTextStyles.body3,
            ),
            subtitle: Text(
              context.l10n.autoTransactionUseActiveWalletDescription,
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            value: null,
            groupValue: selectedId,
            onChanged: (value) => _setDefaultWallet(value),
          ),

          const Divider(height: 1),

          // Wallet options
          ...wallets.map((wallet) => RadioListTile<int?>(
            title: Text(
              wallet.name,
              style: AppTextStyles.body3,
            ),
            subtitle: Text(
              wallet.currency,
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            value: wallet.id,
            groupValue: selectedId,
            onChanged: (value) => _setDefaultWallet(value),
          )),
        ],
      ),
    );
  }

  Widget _buildPlatformNotice() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              HugeIcons.strokeRoundedAlert02,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Text(
                context.l10n.autoTransactionIosNotice,
                style: AppTextStyles.body4.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
