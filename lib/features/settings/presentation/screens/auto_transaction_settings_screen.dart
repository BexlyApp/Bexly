import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gap/gap.dart';

import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/services/auto_transaction/auto_transaction_service.dart';
import 'package:bexly/features/settings/presentation/widgets/sms_scan_results_dialog.dart';
import 'package:bexly/features/settings/presentation/widgets/sms_permission_dialog.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/email_sync/presentation/screens/email_sync_settings_screen.dart';
import 'package:bexly/features/bank_connections/presentation/screens/bank_connections_screen.dart';
import 'package:bexly/features/bank_links/presentation/screens/linked_bank_accounts_screen.dart';
import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/utils/desktop_dialog_helper.dart';
import 'package:bexly/features/transaction/presentation/riverpod/transaction_providers.dart';
import 'package:bexly/features/main/presentation/riverpod/main_page_view_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Date range options for SMS scanning
enum SmsDateRange {
  last30Days,
  last90Days,
  allTime,
}

extension SmsDateRangeExtension on SmsDateRange {
  String getTitle(BuildContext context) {
    switch (this) {
      case SmsDateRange.last30Days:
        return 'Last 30 days';
      case SmsDateRange.last90Days:
        return 'Last 90 days';
      case SmsDateRange.allTime:
        return 'All time';
    }
  }

  String getDescription(BuildContext context) {
    switch (this) {
      case SmsDateRange.last30Days:
        return 'Faster scan, recent transactions only';
      case SmsDateRange.last90Days:
        return 'Balanced scan with recent history';
      case SmsDateRange.allTime:
        return 'Complete history, may take longer';
    }
  }

  /// Get the start date for this range
  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case SmsDateRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case SmsDateRange.last90Days:
        return now.subtract(const Duration(days: 90));
      case SmsDateRange.allTime:
        return null; // No limit
    }
  }
}

/// Auto Transaction settings notifiers
class AutoTransactionSmsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool value) => state = value;
}

class AutoTransactionNotificationEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool value) => state = value;
}

final autoTransactionSmsEnabledProvider = NotifierProvider<AutoTransactionSmsEnabledNotifier, bool>(
  AutoTransactionSmsEnabledNotifier.new,
);
final autoTransactionNotificationEnabledProvider = NotifierProvider<AutoTransactionNotificationEnabledNotifier, bool>(
  AutoTransactionNotificationEnabledNotifier.new,
);

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

      // Check if widget is still mounted before accessing ref
      if (!mounted) return;

      // Check if permission was granted while we were away
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.initialize();

      final granted = await autoService.hasNotificationPermission();

      // Check mounted again after async operation
      if (!mounted) return;

      if (granted) {
        await autoService.setNotificationEnabled(true);
        ref.read(autoTransactionNotificationEnabledProvider.notifier).setEnabled(true);
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

    // Check if widget is still mounted before accessing ref
    if (!mounted) return;

    final autoService = ref.read(autoTransactionServiceProvider);
    await autoService.initialize();

    final granted = await autoService.hasNotificationPermission();

    // Check mounted again after async operation
    if (!mounted) return;

    if (granted) {
      await autoService.setNotificationEnabled(true);
      ref.read(autoTransactionNotificationEnabledProvider.notifier).setEnabled(true);
      await _saveSetting('auto_transaction_notification_enabled', true);
      Log.d('Notification permission granted after resume', label: 'AutoTransaction');
    } else {
      Log.w('Notification permission not granted after resume', label: 'AutoTransaction');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      ref.read(autoTransactionSmsEnabledProvider.notifier).setEnabled(
          prefs.getBool('auto_transaction_sms_enabled') ?? false);
      ref.read(autoTransactionNotificationEnabledProvider.notifier).setEnabled(
          prefs.getBool('auto_transaction_notification_enabled') ?? false);

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
          _showPermissionDeniedBottomSheet(context.l10n.autoTransactionSmsTitle);
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

    ref.read(autoTransactionSmsEnabledProvider.notifier).setEnabled(value);
    await _saveSetting('auto_transaction_sms_enabled', value);
  }

  Future<void> _showPermissionDeniedBottomSheet(String feature) async {
    final shouldOpenSettings = await PermissionDeniedBottomSheet.show(
      context: context,
      feature: feature,
    );
    if (shouldOpenSettings == true) {
      openAppSettings();
    }
  }

  Future<void> _toggleNotificationSetting(bool value) async {
    if (value) {
      // Show permission explanation bottom sheet first
      final shouldProceed = await NotificationPermissionBottomSheet.show(context);
      if (!shouldProceed) return;

      // Initialize auto transaction service
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.initialize();

      // Check if permission is already granted
      final hasPermission = await autoService.hasNotificationPermission();
      if (hasPermission) {
        // Already granted - just enable
        await autoService.setNotificationEnabled(true);
        ref.read(autoTransactionNotificationEnabledProvider.notifier).setEnabled(true);
        await _saveSetting('auto_transaction_notification_enabled', true);
        return;
      }

      // Set flags BEFORE opening system settings.
      // Android may kill the app when notification listener permission is toggled,
      // so we persist this flag to handle the restart case.
      _awaitingNotificationPermission = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pending_notification_permission_request', true);

      // Open system settings - app may be killed after this point.
      // DO NOT check permission or clear flags here.
      // didChangeAppLifecycleState(resumed) handles the "app survived" case.
      // main.dart startup handles the "app was killed" case.
      await autoService.requestNotificationPermission();
    } else {
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.setNotificationEnabled(false);
      ref.read(autoTransactionNotificationEnabledProvider.notifier).setEnabled(false);
      await _saveSetting('auto_transaction_notification_enabled', false);
    }
  }

  Future<void> _scanSmsForBanks() async {
    Log.d('_scanSmsForBanks called', label: 'AutoTransaction');

    // Show date range selection bottom sheet
    final dateRange = await context.openBottomSheet<SmsDateRange>(
      child: const _SmsDateRangeBottomSheet(),
    );
    if (dateRange == null) {
      Log.d('User cancelled date range selection', label: 'AutoTransaction');
      return;
    }

    // Check if SMS permission is already granted
    final currentStatus = await Permission.sms.status;
    Log.d('SMS permission status: $currentStatus', label: 'AutoTransaction');
    if (!currentStatus.isGranted) {
      // Show rationale bottom sheet before requesting permission
      if (!mounted) return;
      final shouldProceed = await SmsPermissionBottomSheet.show(context);
      if (!shouldProceed) return;

      // Request SMS permission after user consents
      final status = await Permission.sms.request();
      Log.d('SMS permission after request: $status', label: 'AutoTransaction');
      if (!status.isGranted) {
        if (mounted) {
          _showPermissionDeniedBottomSheet(context.l10n.autoTransactionSmsTitle);
        }
        return;
      }
    }

    setState(() => _isScanning = true);

    // Use ValueNotifiers so the bottom sheet can rebuild independently
    final progressNotifier = ValueNotifier<int>(0);
    final totalNotifier = ValueNotifier<int>(0);
    final scanStartTime = DateTime.now();

    // Show scanning bottom sheet with live progress
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (ctx) => _LiveScanningBottomSheet(
          progress: progressNotifier,
          total: totalNotifier,
          statusText: context.l10n.autoTransactionScanning,
        ),
      );
    }

    try {
      Log.d('Starting SMS scan, dateRange: ${dateRange.name}, startDate: ${dateRange.startDate}', label: 'AutoTransaction');
      final autoService = ref.read(autoTransactionServiceProvider);
      await autoService.initialize();
      Log.d('AutoService initialized, smsService=${autoService.smsService != null}', label: 'AutoTransaction');

      if (autoService.smsService == null) {
        Log.e('SmsService is null - AI provider may be unavailable', label: 'AutoTransaction');
        // Ensure scanning bottom sheet is visible for at least 1s
        final elapsed = DateTime.now().difference(scanStartTime);
        if (elapsed < const Duration(seconds: 1)) {
          await Future.delayed(const Duration(seconds: 1) - elapsed);
        }
        if (mounted) Navigator.of(context).pop();
        progressNotifier.dispose();
        totalNotifier.dispose();
        setState(() => _isScanning = false);
        if (mounted) await NoResultsBottomSheet.show(context);
        return;
      }

      final results = await autoService.scanSmsForBankSenders(
        startDate: dateRange.startDate,
        onProgress: (current, total) {
          progressNotifier.value = current;
          totalNotifier.value = total;
        },
      );

      Log.d('Scan complete: ${results.length} banks found', label: 'AutoTransaction');

      // Ensure scanning bottom sheet is visible for at least 1.5s
      final elapsed = DateTime.now().difference(scanStartTime);
      if (elapsed < const Duration(milliseconds: 1500)) {
        await Future.delayed(const Duration(milliseconds: 1500) - elapsed);
      }

      // Close scanning bottom sheet
      if (mounted) Navigator.of(context).pop();
      progressNotifier.dispose();
      totalNotifier.dispose();

      setState(() => _isScanning = false);

      if (results.isEmpty) {
        Log.d('No results, showing NoResultsBottomSheet', label: 'AutoTransaction');
        if (mounted) await NoResultsBottomSheet.show(context);
        return;
      }

      // Import all banks directly to pending tab
      int totalImported = 0;
      int totalDuplicates = 0;

      // Use same date range for import as scan
      final importMaxAge = dateRange.startDate != null
          ? DateTime.now().difference(dateRange.startDate!)
          : null;

      for (final sender in results) {
        Log.d('Importing bank: ${sender.bankName} (${sender.messageCount} msgs)', label: 'AutoTransaction');
        final result = await autoService.importTransactionsForBank(
          bankCode: sender.bankCode,
          maxAge: importMaxAge,
        );
        totalImported += result.imported;
        totalDuplicates += result.duplicates;
      }

      Log.d('Import complete: $totalImported imported, $totalDuplicates duplicates', label: 'AutoTransaction');

      // Show import summary with option to view pending
      if (mounted) {
        await ImportResultsBottomSheet.show(
          context: context,
          walletsCreated: 0,
          transactionsImported: totalImported,
          duplicatesSkipped: totalDuplicates,
          onViewPending: () {
            ref.read(requestedTransactionTabProvider.notifier).request(2);
            ref.read(pageControllerProvider.notifier).setPage(2);
            context.go(Routes.main);
          },
        );
      }
    } catch (e, stack) {
      Log.e('Error scanning SMS: $e\n$stack', label: 'AutoTransaction');
      progressNotifier.dispose();
      totalNotifier.dispose();
      if (mounted) {
        Navigator.of(context).pop(); // Close scanning bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning SMS: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      setState(() => _isScanning = false);
    }
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

          // Sub-menu cards
          // SMS Parsing - temporarily hidden (sensitive SMS permission, will revisit)
          // _buildSubMenuCard(
          //   title: 'SMS Parsing',
          //   subtitle: 'Auto-detect transactions from bank SMS',
          //   icon: HugeIcons.strokeRoundedMessage01,
          //   isEnabled: isAndroid,
          //   disabledReason: 'Android only',
          //   onTap: isAndroid ? _showSmsSettingsBottomSheet : null,
          // ),
          // const SizedBox(height: AppSpacing.spacing12),

          _buildSubMenuCard(
            title: 'Notification Listener',
            subtitle: 'Capture transactions from banking app notifications',
            icon: HugeIcons.strokeRoundedNotification01,
            isEnabled: isAndroid,
            disabledReason: 'Android only',
            onTap: isAndroid ? _showNotificationSettingsBottomSheet : null,
          ),
          const SizedBox(height: AppSpacing.spacing12),

          _buildSubMenuCard(
            title: 'Email Sync',
            subtitle: 'Import transactions from bank emails',
            icon: HugeIcons.strokeRoundedMail01,
            isEnabled: true,
            onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
              context,
              route: Routes.emailSyncSettings,
              desktopWidget: const EmailSyncSettingsScreen(),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),

          _buildSubMenuCard(
            title: 'Bank Connection',
            subtitle: 'Connect directly to your bank account (Stripe)',
            icon: HugeIcons.strokeRoundedBank,
            isEnabled: true,
            onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
              context,
              route: Routes.bankConnections,
              desktopWidget: const BankConnectionsScreen(),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),

          // Tingee Open Banking - Vietnam aggregator (Phase A: read-only)
          _buildSubMenuCard(
            title: 'Tingee Open Banking',
            subtitle: 'Liên kết tài khoản ngân hàng VN - auto-import giao dịch',
            icon: HugeIcons.strokeRoundedLinkSquare02,
            isEnabled: true,
            onTap: () => DesktopDialogHelper.navigateToSettingsSubmenu(
              context,
              route: Routes.linkedBankAccounts,
              desktopWidget: const LinkedBankAccountsScreen(),
            ),
          ),

          // Platform notice for iOS (show only if no Android features)
          if (!isAndroid) ...[
            const SizedBox(height: AppSpacing.spacing24),
            _buildPlatformNotice(),
          ],
        ],
      ),
    );
  }

  void _showSmsSettingsBottomSheet() {
    final smsEnabled = ref.read(autoTransactionSmsEnabledProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => CustomBottomSheet(
        title: context.l10n.autoTransactionSmsTitle,
        subtitle: context.l10n.autoTransactionSmsDescription,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingCard(
              title: 'Enable SMS Parsing',
              subtitle: 'Automatically detect transactions from bank SMS',
              icon: HugeIcons.strokeRoundedMessage01,
              value: smsEnabled,
              onChanged: (value) {
                Navigator.pop(ctx);
                _toggleSmsSetting(value);
              },
            ),
            const SizedBox(height: AppSpacing.spacing12),
            _buildScanSmsButton(onTap: () {
              Navigator.pop(ctx); // Close settings bottom sheet first
              _scanSmsForBanks();
            }),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettingsBottomSheet() {
    final notificationEnabled = ref.read(autoTransactionNotificationEnabledProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => CustomBottomSheet(
        title: context.l10n.autoTransactionNotificationTitle,
        subtitle: context.l10n.autoTransactionNotificationDescription,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingCard(
              title: 'Enable Notification Listener',
              subtitle: 'Capture transactions from banking app notifications',
              icon: HugeIcons.strokeRoundedNotification01,
              value: notificationEnabled,
              onChanged: (value) {
                Navigator.pop(ctx);
                _toggleNotificationSetting(value);
              },
            ),
            // Show pending notifications if enabled
            if (notificationEnabled) ...[
              const SizedBox(height: AppSpacing.spacing12),
              _buildPendingNotificationsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubMenuCard({
    required String title,
    required String subtitle,
    required List<List> icon,
    required bool isEnabled,
    String? disabledReason,
    VoidCallback? onTap,
  }) {
    // Use MenuTileButton-like style
    return ListTile(
      onTap: isEnabled ? onTap : null,
      tileColor: isEnabled ? context.purpleBackground : context.purpleBackground.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.purpleBorderLighter),
      ),
      leading: HugeIcon(
        icon: icon,
        color: isEnabled ? context.purpleIcon : AppColors.neutral400,
      ),
      title: Text(
        title,
        style: AppTextStyles.body3.copyWith(
          color: isEnabled ? Theme.of(context).colorScheme.onSurface : AppColors.neutral500,
        ),
      ),
      subtitle: Text(
        isEnabled ? subtitle : disabledReason ?? subtitle,
        style: AppTextStyles.body4.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        color: isEnabled
            ? (context.isDarkMode ? Theme.of(context).colorScheme.onSurfaceVariant : AppColors.purpleAlpha50)
            : AppColors.neutral300,
        size: 20,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.spacing16,
        AppSpacing.spacing4,
        AppSpacing.spacing12,
        AppSpacing.spacing4,
      ),
    );
  }

  Widget _buildScanSmsButton({VoidCallback? onTap}) {
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
        onTap: _isScanning ? null : (onTap ?? _scanSmsForBanks),
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
                onTap: () => _showPendingNotificationsBottomSheet(summary),
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

  Future<void> _showPendingNotificationsBottomSheet(PendingNotificationSummary summary) async {
    final wallets = ref.read(allWalletsStreamProvider).value ?? [];

    final result = await PendingNotificationsBottomSheet.show(
      context: context,
      summary: summary,
      existingWallets: wallets,
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

    // Show processing bottom sheet
    if (mounted) {
      ProcessingBottomSheet.show(
        context: context,
        message: 'Processing pending notifications...',
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

/// Bottom sheet for selecting SMS scan date range
class _SmsDateRangeBottomSheet extends StatefulWidget {
  const _SmsDateRangeBottomSheet();

  @override
  State<_SmsDateRangeBottomSheet> createState() => _SmsDateRangeBottomSheetState();
}

class _SmsDateRangeBottomSheetState extends State<_SmsDateRangeBottomSheet> {
  SmsDateRange _selectedRange = SmsDateRange.last30Days;

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: context.l10n.autoTransactionScanSms,
      subtitle: 'Select how far back to scan for transactions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date range options
          ...SmsDateRange.values.map((range) => _buildRangeOption(range)),

          const Gap(AppSpacing.spacing16),

          // Scan button
          PrimaryButton(
            label: context.l10n.autoTransactionScanSms,
            onPressed: () => Navigator.pop(context, _selectedRange),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeOption(SmsDateRange range) {
    final isSelected = _selectedRange == range;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: InkWell(
        onTap: () => setState(() => _selectedRange = range),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      range.getTitle(context),
                      style: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      range.getDescription(context),
                      style: AppTextStyles.body4.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that listens to ValueNotifiers for live progress updates
class _LiveScanningBottomSheet extends StatelessWidget {
  final ValueNotifier<int> progress;
  final ValueNotifier<int> total;
  final String statusText;

  const _LiveScanningBottomSheet({
    required this.progress,
    required this.total,
    required this.statusText,
  });

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
        child: ValueListenableBuilder<int>(
          valueListenable: total,
          builder: (context, totalVal, _) {
            return ValueListenableBuilder<int>(
              valueListenable: progress,
              builder: (context, currentVal, _) {
                final progressFraction = totalVal > 0 ? currentVal / totalVal : 0.0;
                return Column(
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
                    CircularProgressIndicator(
                      value: progressFraction > 0 ? progressFraction : null,
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    Text(
                      statusText,
                      style: AppTextStyles.body3,
                      textAlign: TextAlign.center,
                    ),
                    if (totalVal > 0) ...[
                      const SizedBox(height: AppSpacing.spacing8),
                      Text(
                        '$currentVal / $totalVal',
                        style: AppTextStyles.body4.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
