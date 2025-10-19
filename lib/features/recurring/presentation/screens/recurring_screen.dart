import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/features/recurring/presentation/riverpod/recurring_providers.dart';
import 'package:bexly/features/recurring/presentation/components/recurring_card.dart';
import 'package:bexly/features/recurring/data/model/recurring_enums.dart';
import 'package:bexly/features/recurring/presentation/screens/recurring_form_screen.dart';

class RecurringScreen extends HookConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState<int>(0);

    return CustomScaffold(
      context: context,
      title: 'Recurring Payments',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RecurringFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Active',
                    isSelected: selectedTab.value == 0,
                    onTap: () => selectedTab.value = 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: 'All',
                    isSelected: selectedTab.value == 1,
                    onTap: () => selectedTab.value = 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: 'Paused',
                    isSelected: selectedTab.value == 2,
                    onTap: () => selectedTab.value = 2,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: selectedTab.value == 0
                ? const _ActiveRecurringsTab()
                : selectedTab.value == 1
                    ? const _AllRecurringsTab()
                    : const _PausedRecurringsTab(),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
          return const _EmptyState(
            icon: Icons.repeat,
            title: 'No Active Recurring Payments',
            subtitle: 'Add your first subscription or recurring bill',
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
                  // TODO: Navigate to recurring details
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View ${recurring.name} details')),
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
        title: 'Error loading recurrings',
        subtitle: error.toString(),
      ),
    );
  }
}

class _AllRecurringsTab extends HookConsumerWidget {
  const _AllRecurringsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringsAsync = ref.watch(allRecurringsProvider);

    return recurringsAsync.when(
      data: (recurrings) {
        if (recurrings.isEmpty) {
          return const _EmptyState(
            icon: Icons.repeat,
            title: 'No Recurring Payments',
            subtitle: 'Add your first subscription or recurring bill',
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
                  // TODO: Navigate to recurring details
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View ${recurring.name} details')),
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
        title: 'Error loading recurrings',
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
          return const _EmptyState(
            icon: Icons.pause_circle_outline,
            title: 'No Paused Recurring Payments',
            subtitle: 'Paused subscriptions and bills will appear here',
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
                  // TODO: Navigate to recurring details
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('View ${recurring.name} details')),
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
        title: 'Error loading recurrings',
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
