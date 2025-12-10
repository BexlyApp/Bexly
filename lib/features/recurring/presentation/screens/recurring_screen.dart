import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_providers.dart';
import 'package:bexly/features/recurring/presentation/components/recurring_card.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/recurring/presentation/screens/recurring_form_screen.dart';

class RecurringScreen extends HookConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);

    return CustomScaffold(
      context: context,
      title: context.l10n.recurringPayments,
      showBackButton: false,
      showBalance: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            useSafeArea: true,
            builder: (context) => const RecurringFormScreen(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedPlusSign,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: tabController,
              indicatorColor: AppColors.primary600,
              indicatorWeight: 3,
              labelColor: AppColors.primary600,
              unselectedLabelColor: AppColors.neutral400,
              labelStyle: AppTextStyles.body3.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 6),
                      Text(context.l10n.active),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pause_circle_outline, size: 18),
                      const SizedBox(width: 6),
                      Text(context.l10n.paused),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                _ActiveRecurringsTab(),
                _PausedRecurringsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveRecurringsTab extends HookConsumerWidget {
  const _ActiveRecurringsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringsAsync = ref.watch(activeRecurringsProvider);

    return recurringsAsync.when(
      data: (recurrings) {
        if (recurrings.isEmpty) {
          return _EmptyState(
            icon: Icons.repeat,
            title: context.l10n.noActiveRecurringPayments,
            subtitle: context.l10n.addFirstSubscription,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recurrings.length,
          itemBuilder: (context, index) {
            final recurring = recurrings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecurringCard(
                recurring: recurring,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    useSafeArea: true,
                    builder: (context) => RecurringFormScreen(recurringId: recurring.id),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => _EmptyState(
        icon: Icons.error_outline,
        title: context.l10n.errorLoadingRecurrings,
        subtitle: error.toString(),
      ),
    );
  }
}

class _PausedRecurringsTab extends HookConsumerWidget {
  const _PausedRecurringsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringsAsync = ref.watch(
      recurringsByStatusProvider(RecurringStatus.paused),
    );

    return recurringsAsync.when(
      data: (recurrings) {
        if (recurrings.isEmpty) {
          return _EmptyState(
            icon: Icons.pause_circle_outline,
            title: context.l10n.noPausedRecurringPayments,
            subtitle: context.l10n.pausedSubscriptionsWillAppear,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recurrings.length,
          itemBuilder: (context, index) {
            final recurring = recurrings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecurringCard(
                recurring: recurring,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    useSafeArea: true,
                    builder: (context) => RecurringFormScreen(recurringId: recurring.id),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stack) => _EmptyState(
        icon: Icons.error_outline,
        title: context.l10n.errorLoadingRecurrings,
        subtitle: error.toString(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
