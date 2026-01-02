import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';

import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/buttons/button_state.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/features/bank_connections/riverpod/bank_connection_provider.dart';
import 'package:bexly/features/bank_connections/data/models/linked_account_model.dart';

class BankConnectionsScreen extends HookConsumerWidget {
  const BankConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bankConnectionProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Load accounts on first build only if authenticated
    useEffect(() {
      if (isAuthenticated) {
        Future.microtask(() {
          ref.read(bankConnectionProvider.notifier).loadAccounts();
        });
      }
      return null;
    }, [isAuthenticated]);

    return CustomScaffold(
      context: context,
      title: 'Bank Connections',
      showBalance: false,
      body: isAuthenticated
          ? _buildContent(context, ref, state)
          : _buildLoginRequired(context),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary900.withValues(alpha: 0.3)
                    : AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedLock,
                color: AppColors.primary600,
                size: 40,
              ),
            ),
            const Gap(AppSpacing.spacing24),
            Text(
              'Login Required',
              style: AppTextStyles.heading2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Gap(AppSpacing.spacing12),
            Text(
              'You need to sign in to connect your bank accounts and sync transactions securely.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body3.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(AppSpacing.spacing32),
            PrimaryButton(
              onPressed: () => context.push('/login'),
              label: 'Sign In',
              state: ButtonState.active,
            ),
            const Gap(AppSpacing.spacing16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: AppTextStyles.body3.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    BankConnectionState state,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          _InfoCard(),

          const Gap(AppSpacing.spacing24),

          // Available Providers Section
          Text(
            'Available Providers',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const Gap(AppSpacing.spacing12),

          // Stripe Provider (US only)
          _ProviderCard(
            name: 'Stripe',
            description: 'Connect US bank accounts via Stripe Financial Connections',
            icon: HugeIcons.strokeRoundedCreditCard,
            color: const Color(0xFF635BFF),
            isLoading: state.isLinking || state.isLoading,
            isAvailable: true,
            onTap: () => _linkAccounts(context, ref),
          ),

          const Gap(AppSpacing.spacing12),

          // Plaid Provider (Coming Soon)
          _ProviderCard(
            name: 'Plaid',
            description: 'Connect bank accounts worldwide',
            icon: HugeIcons.strokeRoundedBank,
            color: const Color(0xFF00D09C),
            isLoading: false,
            isAvailable: false,
          ),

          const Gap(AppSpacing.spacing12),

          // MX Provider (Coming Soon)
          _ProviderCard(
            name: 'MX',
            description: 'Financial data aggregation for North America',
            icon: HugeIcons.strokeRoundedChartLineData02,
            color: const Color(0xFF0077B5),
            isLoading: false,
            isAvailable: false,
          ),

          if (state.accounts.isNotEmpty) ...[
            const Gap(AppSpacing.spacing24),

            // Linked Accounts
            Text(
              'Linked Accounts',
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const Gap(AppSpacing.spacing12),

            ...state.accounts.map((account) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
              child: _LinkedAccountCard(
                account: account,
                onSync: () => _syncAccount(context, ref, account.id),
                onDisconnect: () => _showDisconnectDialog(context, ref, account),
              ),
            )),

            const Gap(AppSpacing.spacing12),

            // Sync All Button
            if (state.accounts.length > 1)
              _SyncAllCard(
                isSyncing: state.isSyncing,
                onSync: () => _syncAllAccounts(context, ref),
              ),
          ],

          if (state.error != null) ...[
            const Gap(AppSpacing.spacing16),
            _ErrorCard(
              error: state.error!,
              onDismiss: () {
                ref.read(bankConnectionProvider.notifier).clearError();
              },
            ),
          ],

          const Gap(AppSpacing.spacing24),

          // Privacy Info
          _PrivacyCard(),
        ],
      ),
    );
  }

  Future<void> _linkAccounts(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(bankConnectionProvider.notifier).linkAccounts();

    if (context.mounted && success) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Bank accounts linked successfully'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _syncAccount(BuildContext context, WidgetRef ref, String accountId) async {
    final count = await ref.read(bankConnectionProvider.notifier).syncTransactions(
      accountId: accountId,
    );

    if (context.mounted) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text('Synced $count transactions'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _syncAllAccounts(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(bankConnectionProvider.notifier).syncTransactions();

    if (context.mounted) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text('Synced $count transactions'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    }
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref, LinkedAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Account'),
        content: Text(
          'Are you sure you want to disconnect ${account.institutionName}? '
          'Your synced transactions will remain in Bexly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(bankConnectionProvider.notifier)
                  .disconnectAccount(account.id);

              if (context.mounted && success) {
                toastification.show(
                  context: context,
                  type: ToastificationType.success,
                  title: const Text('Account disconnected'),
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.red600),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primary900.withValues(alpha: 0.3) : AppColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.primary800 : AppColors.primary100,
        ),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedBank,
            color: AppColors.primary600,
            size: 32,
          ),
          const Gap(AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Your Accounts',
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Gap(4),
                Text(
                  'Automatically import transactions from your bank accounts and financial services.',
                  style: AppTextStyles.body4.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ProviderCard extends StatelessWidget {
  final String name;
  final String description;
  final dynamic icon;
  final Color color;
  final bool isLoading;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _ProviderCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.neutral700 : AppColors.neutral200,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAvailable && !isLoading ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: Row(
                children: [
                  // Provider Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.spacing12),

                  // Provider Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.body1.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (!isAvailable) ...[
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Coming Soon',
                                  style: AppTextStyles.body5.copyWith(
                                    color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Gap(2),
                        Text(
                          description,
                          style: AppTextStyles.body4.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action indicator
                  if (isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (isAvailable)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkedAccountCard extends StatelessWidget {
  final LinkedAccount account;
  final VoidCallback onSync;
  final VoidCallback onDisconnect;

  const _LinkedAccountCard({
    required this.account,
    required this.onSync,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          // Bank Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.neutral700 : AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedBank,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const Gap(AppSpacing.spacing12),

          // Account Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.institutionName,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (account.displayName != null || account.last4 != null) ...[
                  const Gap(2),
                  Text(
                    account.displayName ?? '••••${account.last4}',
                    style: AppTextStyles.body4.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (account.category != null) ...[
                  const Gap(2),
                  Text(
                    _formatCategory(account.category!),
                    style: AppTextStyles.body4.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            onSelected: (value) {
              switch (value) {
                case 'sync':
                  onSync();
                  break;
                case 'disconnect':
                  onDisconnect();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: Theme.of(context).colorScheme.onSurface, size: 20),
                    const Gap(8),
                    const Text('Sync Transactions'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedLink01, color: AppColors.red600, size: 20),
                    const Gap(8),
                    Text('Disconnect', style: TextStyle(color: AppColors.red600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCategory(String category) {
    return category.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class _SyncAllCard extends StatelessWidget {
  final bool isSyncing;
  final VoidCallback onSync;

  const _SyncAllCard({
    required this.isSyncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      onPressed: onSync,
      label: 'Sync All Accounts',
      isLoading: isSyncing,
      state: ButtonState.outlinedActive,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorCard({
    required this.error,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.red200),
      ),
      child: Row(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: AppColors.red600, size: 20),
          const Gap(8),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.body4.copyWith(color: AppColors.red700),
            ),
          ),
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.red600, size: 18),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedSecurityCheck,
            color: AppColors.green200,
            size: 20,
          ),
          const Gap(AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure & Private',
                  style: AppTextStyles.body3.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Gap(4),
                Text(
                  'Your bank credentials are never stored. All connections use secure, industry-standard protocols. You can disconnect at any time.',
                  style: AppTextStyles.body4.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
