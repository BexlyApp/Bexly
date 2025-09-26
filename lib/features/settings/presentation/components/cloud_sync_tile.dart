import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/auth_required_dialog.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:gap/gap.dart';

/// Example of a settings tile that requires authentication
class CloudSyncTile extends ConsumerWidget {
  const CloudSyncTile({super.key});

  Future<void> _handleCloudSync(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(isGuestModeProvider);

    if (isGuest) {
      final shouldLogin = await AuthRequiredDialog.show(
        context,
        featureName: 'Cloud Sync',
        description: 'Sign in to automatically sync your data across all your devices',
      );

      if (shouldLogin != true) {
        return;
      }
    } else {
      // User is authenticated, proceed with cloud sync
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cloud sync enabled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.cloud_sync,
            color: theme.colorScheme.primary,
          ),
        ),
        title: const Text('Cloud Sync'),
        subtitle: Text(
          isAuthenticated
              ? 'Your data is synced across devices'
              : 'Sign in to enable cloud sync',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isAuthenticated
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
            : Icon(
                Icons.lock_outline,
                color: theme.colorScheme.outline,
              ),
        onTap: () => _handleCloudSync(context, ref),
      ),
    );
  }
}

/// Example of a backup tile that requires authentication
class AutoBackupTile extends ConsumerWidget {
  const AutoBackupTile({super.key});

  Future<void> _handleAutoBackup(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(isGuestModeProvider);

    if (isGuest) {
      final shouldLogin = await AuthRequiredDialog.show(
        context,
        featureName: 'Automatic Backup',
        description: 'Sign in to enable automatic daily backups to the cloud',
      );

      if (shouldLogin != true) {
        return;
      }
    } else {
      // User is authenticated, show backup settings
      _showBackupSettings(context);
    }
  }

  void _showBackupSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Gap(16),
            ListTile(
              title: const Text('Daily'),
              leading: Radio<String>(
                value: 'daily',
                groupValue: 'daily',
                onChanged: (_) {},
              ),
            ),
            ListTile(
              title: const Text('Weekly'),
              leading: Radio<String>(
                value: 'weekly',
                groupValue: 'daily',
                onChanged: (_) {},
              ),
            ),
            ListTile(
              title: const Text('Monthly'),
              leading: Radio<String>(
                value: 'monthly',
                groupValue: 'daily',
                onChanged: (_) {},
              ),
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.backup,
            color: theme.colorScheme.secondary,
          ),
        ),
        title: const Text('Automatic Backup'),
        subtitle: Text(
          isAuthenticated
              ? 'Backing up daily'
              : 'Sign in to enable automatic backups',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isAuthenticated
            ? Chip(
                label: const Text('Daily'),
                backgroundColor: theme.colorScheme.secondaryContainer,
              )
            : Icon(
                Icons.lock_outline,
                color: theme.colorScheme.outline,
              ),
        onTap: () => _handleAutoBackup(context, ref),
      ),
    );
  }
}