import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'package:bexly/core/router/routes.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/email_sync/riverpod/email_sync_provider.dart';
import 'package:bexly/features/email_sync/riverpod/email_scan_provider.dart';
import 'package:bexly/features/email_sync/domain/services/gmail_auth_service.dart';
import 'package:bexly/features/email_sync/data/models/email_sync_settings_model.dart';

class EmailSyncSettingsScreen extends HookConsumerWidget {
  const EmailSyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(emailSyncProvider);

    return CustomScaffold(
      context: context,
      title: 'Email Sync',
      showBalance: false,
      body: syncState.when(
        data: (settings) => _buildContent(context, ref, settings),
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: TextStyle(color: AppColors.red600)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    EmailSyncSettingsModel? settings,
  ) {
    final isConnected = settings?.gmailEmail != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Card
          _EmailConnectionCard(
            isConnected: isConnected,
            email: settings?.gmailEmail,
            onConnect: () => _connectGmail(context, ref),
            onDisconnect: () => _showDisconnectDialog(context, ref),
          ),

          if (isConnected && settings != null) ...[
            const Gap(AppSpacing.spacing24),

            // Sync Status Card
            _SyncStatusCard(settings: settings),

            const Gap(AppSpacing.spacing24),

            // Enable/Disable Toggle
            _EnableToggleCard(
              isEnabled: settings.isEnabled,
              onToggle: (enabled) {
                ref.read(emailSyncProvider.notifier).setEnabled(enabled);
              },
            ),

            const Gap(AppSpacing.spacing24),

            // Sync Now Button
            _SyncNowCard(
              onSync: () => _syncNow(context, ref),
            ),

            const Gap(AppSpacing.spacing24),

            // Review Pending Transactions
            if (settings.pendingReview > 0)
              _ReviewPendingCard(
                pendingCount: settings.pendingReview,
                onTap: () => context.push(Routes.emailReview),
              ),

            if (settings.pendingReview > 0)
              const Gap(AppSpacing.spacing24),

            // Privacy Info
            _PrivacyInfoCard(),
          ],
        ],
      ),
    );
  }

  Future<void> _connectGmail(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(emailSyncProvider.notifier).connectGmail();

    if (!context.mounted) return;

    switch (result) {
      case GmailConnectSuccess(:final email):
        toastification.show(
          context: context,
          title: const Text('Gmail Connected'),
          description: Text('Connected to $email'),
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 3),
        );
      case GmailConnectCancelled():
        // User cancelled, do nothing
        break;
      case GmailConnectError(:final message):
        toastification.show(
          context: context,
          title: const Text('Connection Failed'),
          description: Text(message),
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          autoCloseDuration: const Duration(seconds: 4),
        );
    }
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disconnect Gmail?'),
        content: const Text(
          'This will stop syncing transactions from your email. '
          'Previously imported transactions will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(emailSyncProvider.notifier).disconnectGmail();

              if (context.mounted) {
                toastification.show(
                  context: context,
                  title: const Text('Gmail Disconnected'),
                  type: ToastificationType.info,
                  style: ToastificationStyle.fillColored,
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red600,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final scanNotifier = ref.read(emailScanProvider.notifier);

    // Get last sync time to only fetch new emails
    final settings = ref.read(emailSyncProvider).when(
      data: (data) => data,
      loading: () => null,
      error: (_, __) => null,
    );
    final since = settings?.lastSyncTime ?? DateTime.now().subtract(const Duration(days: 7));

    final result = await scanNotifier.scanEmails(since: since);

    if (!context.mounted) return;

    if (result != null) {
      toastification.show(
        context: context,
        title: const Text('Scan Complete'),
        description: Text('Found ${result.parsedCount} transactions from ${result.totalEmails} emails'),
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } else {
      final error = ref.read(emailScanProvider).error;
      toastification.show(
        context: context,
        title: const Text('Scan Failed'),
        description: Text(error ?? 'Unknown error'),
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }
}

/// Card showing Gmail connection status
class _EmailConnectionCard extends StatelessWidget {
  final bool isConnected;
  final String? email;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _EmailConnectionCard({
    required this.isConnected,
    required this.email,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? AppColors.green100.withValues(alpha: 0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.greenAlpha10
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email_outlined,
                  color: isConnected ? AppColors.green200 : AppColors.neutral500,
                  size: 28,
                ),
              ),
              const Gap(AppSpacing.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Gmail Connected' : 'Not Connected',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (email != null) ...[
                      const Gap(4),
                      Text(
                        email!,
                        style: AppTextStyles.body4.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isConnected)
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.green200,
                  size: 24,
                ),
            ],
          ),
          const Gap(AppSpacing.spacing16),
          SizedBox(
            width: double.infinity,
            child: isConnected
                ? OutlinedButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red600,
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Connect Gmail'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card showing sync statistics
class _SyncStatusCard extends StatelessWidget {
  final EmailSyncSettingsModel settings;

  const _SyncStatusCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Statistics',
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(AppSpacing.spacing16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.access_time,
                  label: 'Last Sync',
                  value: settings.lastSyncTime != null
                      ? _formatLastSync(settings.lastSyncTime!)
                      : 'Never',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.inbox_outlined,
                  label: 'Imported',
                  value: '${settings.totalImported}',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.pending_outlined,
                  label: 'Pending',
                  value: '${settings.pendingReview}',
                  valueColor: settings.pendingReview > 0 ? AppColors.tertiary600 : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${lastSync.day}/${lastSync.month}';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.neutral500),
        const Gap(8),
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const Gap(4),
        Text(
          label,
          style: AppTextStyles.body4.copyWith(
            color: AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}

/// Toggle card for enabling/disabling sync
class _EnableToggleCard extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  const _EnableToggleCard({
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-sync Enabled',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Text(
                  'Automatically scan and import transactions from banking emails',
                  style: AppTextStyles.body4.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

/// Card with sync now button
class _SyncNowCard extends ConsumerWidget {
  final VoidCallback onSync;

  const _SyncNowCard({required this.onSync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(emailScanProvider);
    final isScanning = scanState.isScanning;
    final progress = scanState.progress;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sync,
                color: isScanning ? AppColors.primary600 : AppColors.neutral500,
                size: 24,
              ),
              const Gap(AppSpacing.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Sync',
                      style: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Scan your inbox for new banking emails',
                      style: AppTextStyles.body4.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.spacing16),
          if (isScanning) ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary600),
            ),
            const Gap(AppSpacing.spacing12),
            Text(
              'Scanning emails... ${(progress * 100).toInt()}%',
              style: AppTextStyles.body4.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSync,
                icon: const Icon(Icons.refresh),
                label: const Text('Sync Now'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card showing pending transactions to review
class _ReviewPendingCard extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onTap;

  const _ReviewPendingCard({
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: AppColors.tertiary600.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.tertiary600.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.tertiary600.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pending_actions,
                color: AppColors.tertiary600,
                size: 24,
              ),
            ),
            const Gap(AppSpacing.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pendingCount Pending Review',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'Tap to review and approve transactions',
                    style: AppTextStyles.body4.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.tertiary600,
            ),
          ],
        ),
      ),
    );
  }
}

/// Privacy information card
class _PrivacyInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primaryAlpha10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryAlpha25,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppColors.primary600,
            size: 24,
          ),
          const Gap(AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy is Protected',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary700,
                  ),
                ),
                const Gap(8),
                Text(
                  '• We only read emails from banking domains\n'
                  '• Email content is never stored\n'
                  '• Only transaction data is extracted\n'
                  '• You can disconnect anytime',
                  style: AppTextStyles.body4.copyWith(
                    color: AppColors.neutral600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
