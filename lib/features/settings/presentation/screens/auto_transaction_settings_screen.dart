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
import 'package:bexly/features/settings/presentation/widgets/sms_scan_results_dialog.dart';
import 'package:bexly/features/settings/presentation/widgets/sms_permission_dialog.dart';
import 'package:bexly/features/settings/presentation/widgets/sms_date_range_bottom_sheet.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';

/// Auto Transaction settings providers
final autoTransactionSmsEnabledProvider = StateProvider<bool>((ref) => false);
final autoTransactionNotificationEnabledProvider = StateProvider<bool>((ref) => false);

/// Provider for pending notification count
final pendingNotificationCountProvider = FutureProvider<int>((ref) async {
  final autoService = ref.read(autoTransactionServiceProvider);
  await autoService.initialize();
  return await autoService.getPendingNotificationCount();
});

/// Provider for pending notification summary
final pendingNotificationSummaryProvider = FutureProvider<PendingNotificationSummary>((ref) async {
  final autoService = ref.read(autoTransactionServiceProvider);
  await autoService.initialize();
  return await autoService.checkPendingOnStartup();
});

class AutoTransactionSettingsScreen extends ConsumerStatefulWidget {
  const AutoTransactionSettingsScreen({super.key});

  @override
  ConsumerState<AutoTransactionSettingsScreen> createState() =>
      _AutoTransactionSettingsScreenState();
}

class _AutoTransactionSettingsScreenState
    extends ConsumerState<AutoTransactionSettingsScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isScanning = false;
  int _scanProgress = 0;
  int _scanTotal = 0;
  bool _awaitingNotificationPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _checkPendingPermissionRequest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background (e.g., user returns from Settings)
    if (state == AppLifecycleState.resumed && _awaitingNotificationPermission) {
      _checkNotificationPermissionAfterResume();
    }
  }

  /// Check if there's a pending permission request from before app was killed
  Future<void> _checkPendingPermissionRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingRequest = prefs.getBool('pending_notification_permission_request') ?? false;

    if (pendingRequest) {
      // Clear the flag first
      await prefs.remove('pending_notification_permission_request');

      // Check if permission was granted while we were away
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.initialize();

      final granted = await autoService.hasNotificationPermission();
      if (granted) {
        await autoService.setNotificationEnabled(true);
        ref.read(autoTransactionNotificationEnabledProvider.notifier).state = true;
        await _saveSetting('auto_transaction_notification_enabled', true);
        Log.d('Notification permission granted (detected on restart)', label: 'AutoTransaction');
      }
    }
  }

  Future<void> _checkNotificationPermissionAfterResume() async {
    _awaitingNotificationPermission = false;

    // Clear the persistent flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_notification_permission_request');

    final autoService = ref.read(autoTransactionServiceProvider);
    await autoService.initialize();

    final granted = await autoService.hasNotificationPermission();
    if (granted) {
      await autoService.setNotificationEnabled(true);
      ref.read(autoTransactionNotificationEnabledProvider.notifier).state = true;
      await _saveSetting('auto_transaction_notification_enabled', true);
      Log.d('Notification permission granted after resume', label: 'AutoTransaction');
    } else {
      Log.w('Notification permission not granted after resume', label: 'AutoTransaction');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      ref.read(autoTransactionSmsEnabledProvider.notifier).state =
          prefs.getBool('auto_transaction_sms_enabled') ?? false;
      ref.read(autoTransactionNotificationEnabledProvider.notifier).state =
          prefs.getBool('auto_transaction_notification_enabled') ?? false;

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
      // Show permission explanation bottom sheet first
      final shouldProceed = await SmsPermissionBottomSheet.show(context);
      if (!shouldProceed) {
        return;
      }

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
      // Show permission explanation bottom sheet first
      final shouldProceed = await NotificationPermissionBottomSheet.show(context);
      if (!shouldProceed) {
        return;
      }

      // Initialize auto transaction service and request notification permission
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.initialize();

      // Check if permission is granted
      final hasPermission = await autoService.hasNotificationPermission();
      if (!hasPermission) {
        // Set flag before opening system settings
        // This allows us to check permission when app resumes
        _awaitingNotificationPermission = true;

        // Save to SharedPreferences in case app gets killed while in settings
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pending_notification_permission_request', true);

        // Open system settings - app may be killed while in settings
        await autoService.requestNotificationPermission();

        // If we get here, app wasn't killed - check permission directly
        // Wait a bit for settings to apply
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        final granted = await autoService.hasNotificationPermission();
        if (granted) {
          _awaitingNotificationPermission = false;
          // Clear the persistent flag
          await prefs.remove('pending_notification_permission_request');
          await autoService.setNotificationEnabled(true);
          ref.read(autoTransactionNotificationEnabledProvider.notifier).state = true;
          await _saveSetting('auto_transaction_notification_enabled', true);
        } else {
          _awaitingNotificationPermission = false;
          // Clear the persistent flag
          await prefs.remove('pending_notification_permission_request');
          Log.w('Notification permission not granted', label: 'AutoTransaction');
        }
        return;
      }

      // Permission already granted
      await autoService.setNotificationEnabled(true);
      ref.read(autoTransactionNotificationEnabledProvider.notifier).state = true;
      await _saveSetting('auto_transaction_notification_enabled', true);
    } else {
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.setNotificationEnabled(false);
      ref.read(autoTransactionNotificationEnabledProvider.notifier).state = false;
      await _saveSetting('auto_transaction_notification_enabled', false);
    }
  }

  Future<void> _scanSmsForBanks() async {
    // Show date range selection bottom sheet first
    final dateRange = await SmsDateRangeBottomSheet.show(context);
    if (dateRange == null) {
      return; // User cancelled
    }

    // Request SMS permission
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
        startDate: dateRange.startDate,
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

            // Pending Notifications Section (only show if notification is enabled)
            if (notificationEnabled) ...[
              const SizedBox(height: AppSpacing.spacing12),
              _buildPendingNotificationsSection(),
            ],
          ],

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
        leading: HugeIcon(
          icon: HugeIcons.strokeRoundedSearch01,
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
            : HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.neutral400,
              ),
        onTap: _isScanning ? null : _scanSmsForBanks,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedInformationCircle,
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
    required List<List> icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        secondary: HugeIcon(
          icon: icon,
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

  Widget _buildPendingNotificationsSection() {
    final pendingAsync = ref.watch(pendingNotificationSummaryProvider);

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Badge(
                  label: Text('${summary.totalNotifications}'),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedNotificationBubble,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                title: Text(
                  'Pending Notifications',
                  style: AppTextStyles.body3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${summary.totalNotifications} transactions from ${summary.groups.length} source(s)',
                  style: AppTextStyles.body4.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                trailing: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: AppColors.neutral400,
                ),
                onTap: () => _showPendingNotificationsDialog(summary),
              ),
              // Show preview of groups
              if (summary.groups.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.spacing16,
                    right: AppSpacing.spacing16,
                    bottom: AppSpacing.spacing12,
                  ),
                  child: Wrap(
                    spacing: AppSpacing.spacing8,
                    runSpacing: AppSpacing.spacing8,
                    children: summary.groups.take(3).map((group) {
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            '${group.notificationCount}',
                            style: AppTextStyles.body5.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        label: Text(
                          group.displayName,
                          style: AppTextStyles.body5,
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPendingNotificationsDialog(PendingNotificationSummary summary) async {
    final wallets = ref.read(allWalletsStreamProvider).valueOrNull ?? [];

    final result = await showDialog<Map<String, int?>>(
      context: context,
      builder: (context) => _PendingNotificationsDialog(
        summary: summary,
        existingWallets: wallets,
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _processPendingWithMapping(summary, result);
    }
  }

  Future<void> _processPendingWithMapping(
    PendingNotificationSummary summary,
    Map<String, int?> mappingDecisions, // mappingKey -> walletId (null = create new)
  ) async {
    final autoService = ref.read(autoTransactionServiceProvider);

    // Build the wallet map
    final bankAccountToWalletMap = <String, int>{};

    for (final group in summary.groups) {
      final decision = mappingDecisions[group.mappingKey];

      if (decision == null) {
        // Create new wallet
        final wallet = await autoService.createWalletForPendingNotifications(
          bankCode: group.bankCode,
          accountId: group.accountId,
          bankName: group.bankName,
          currency: 'VND', // Default to VND, could detect from notifications
          accountType: group.accountType,
        );

        if (wallet?.id != null) {
          bankAccountToWalletMap[group.mappingKey] = wallet!.id!;
        }
      } else if (decision > 0) {
        // Link to existing wallet
        bankAccountToWalletMap[group.mappingKey] = decision;
      }
      // decision == 0 means ignore
    }

    if (bankAccountToWalletMap.isEmpty) {
      return;
    }

    // Show processing dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.spacing16),
              Text('Processing pending notifications...'),
            ],
          ),
        ),
      );
    }

    // Process pending notifications
    final result = await autoService.processPendingNotifications(
      bankAccountToWalletMap: bankAccountToWalletMap,
    );

    // Close processing dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Show results
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Processed ${result.processed} transactions, ${result.skipped} skipped',
          ),
        ),
      );

      // Refresh the pending count
      ref.invalidate(pendingNotificationCountProvider);
      ref.invalidate(pendingNotificationSummaryProvider);
    }
  }

  Widget _buildPlatformNotice() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
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

/// Dialog to manage pending notifications
class _PendingNotificationsDialog extends StatefulWidget {
  final PendingNotificationSummary summary;
  final List<WalletModel> existingWallets;

  const _PendingNotificationsDialog({
    required this.summary,
    required this.existingWallets,
  });

  @override
  State<_PendingNotificationsDialog> createState() => _PendingNotificationsDialogState();
}

class _PendingNotificationsDialogState extends State<_PendingNotificationsDialog> {
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
    return AlertDialog(
      title: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNotificationBubble,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              'Pending Notifications',
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
              '${widget.summary.totalNotifications} transaction(s) from ${widget.summary.groups.length} source(s) are waiting to be processed.',
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.summary.groups.length,
                itemBuilder: (context, index) {
                  final group = widget.summary.groups[index];
                  return _buildGroupItem(group);
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
          onPressed: _decisions.values.any((v) => v != 0)
              ? () => Navigator.of(context).pop(_decisions)
              : null,
          child: const Text('Process'),
        ),
      ],
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
              initialValue: decision,
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
