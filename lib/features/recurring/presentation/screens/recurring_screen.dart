import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/extensions/screen_utils_extensions.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_providers.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_suggestion_provider.dart';
import 'package:bexly/features/recurring/presentation/components/recurring_card.dart';
import 'package:bexly/features/recurring/presentation/components/recurring_suggestion_card.dart';
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
      // Hide FAB on desktop - use sidebar button instead
      floatingActionButton: context.isDesktopLayout
          ? null
          : FloatingActionButton(
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
                icon: HugeIcons.strokeRoundedPlusSign as dynamic,
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
    final suggestionsAsync = ref.watch(recurringSuggestionsProvider);
    final isExpanded = useState(true);

    return recurringsAsync.when(
      data: (recurrings) {
        // Build suggestion section + recurring list
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI Suggestions section
            suggestionsAsync.when(
              data: (suggestions) {
                if (suggestions.isEmpty) return const SizedBox.shrink();
                return _SuggestionsSection(
                  suggestions: suggestions,
                  isExpanded: isExpanded,
                );
              },
              loading: () => const SizedBox.shrink(), // Don't show loading for suggestions
              error: (_, _) => const SizedBox.shrink(),
            ),

            // Empty state if no recurrings
            if (recurrings.isEmpty)
              _EmptyState(
                icon: Icons.repeat,
                title: context.l10n.noActiveRecurringPayments,
                subtitle: context.l10n.addFirstSubscription,
              ),

            // Recurring cards
            ...recurrings.map((recurring) => Padding(
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
            )),
          ],
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

/// Collapsible section showing AI-detected recurring suggestions
class _SuggestionsSection extends ConsumerWidget {
  final List<dynamic> suggestions;
  final ValueNotifier<bool> isExpanded;

  const _SuggestionsSection({
    required this.suggestions,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with expand/collapse
        InkWell(
          onTap: () => isExpanded.value = !isExpanded.value,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAiBrain01,
                  color: AppColors.primary600,
                  size: 18,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    'AI detected ${suggestions.length} recurring pattern${suggestions.length > 1 ? 's' : ''}',
                    style: AppTextStyles.body3.copyWith(
                      color: AppColors.primary600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  isExpanded.value ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary600,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const Gap(8),

        // Suggestion cards (collapsible)
        if (isExpanded.value)
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RecurringSuggestionCard(
              suggestion: suggestion,
              onAdd: () {
                // Navigate to create recurring form pre-filled with suggestion
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  useSafeArea: true,
                  builder: (context) => RecurringFormScreen(
                    prefillName: suggestion.name,
                    prefillAmount: suggestion.amount,
                    prefillFrequency: suggestion.frequency,
                  ),
                );
              },
              onDismiss: () {
                ref.read(dismissedSuggestionsProvider.notifier).dismiss(suggestion.name);
              },
            ),
          )),

        // Divider between suggestions and recurring list
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1),
        ),
      ],
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
