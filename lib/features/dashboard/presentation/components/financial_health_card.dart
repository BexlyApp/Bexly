part of '../screens/dashboard_screen.dart';

/// Compact Financial Health Score card for the dashboard
class FinancialHealthCard extends ConsumerWidget {
  const FinancialHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(financialHealthProvider);

    return healthAsync.when(
      data: (health) {
        if (health.score == 0 && health.grade == '-') {
          return const SizedBox.shrink(); // No data yet
        }
        return _HealthScoreCard(health: health);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final FinancialHealthScore health;
  const _HealthScoreCard({required this.health});

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(health.score);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.radius16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Circular score indicator
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: health.score / 100,
                    strokeWidth: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${health.score}',
                      style: AppTextStyles.heading3.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      health.grade,
                      style: AppTextStyles.body5.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Health',
                  style: AppTextStyles.body3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                // Mini metrics row
                Row(
                  children: [
                    _MiniMetric(
                      label: 'Savings',
                      value: '${(health.savingsRate * 100).round()}%',
                      isGood: health.savingsRate >= 0.1,
                    ),
                    const Gap(12),
                    _MiniMetric(
                      label: 'Budget',
                      value: '${(health.budgetAdherence * 100).round()}%',
                      isGood: health.budgetAdherence >= 0.8,
                    ),
                    const Gap(12),
                    _MiniMetric(
                      label: 'Trend',
                      value: health.expenseTrend >= 0
                          ? '+${(health.expenseTrend * 100).round()}%'
                          : '${(health.expenseTrend * 100).round()}%',
                      isGood: health.expenseTrend <= 0,
                    ),
                  ],
                ),
                if (health.tips.isNotEmpty) ...[
                  const Gap(6),
                  Text(
                    health.tips.first,
                    style: AppTextStyles.body4.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isGood;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body4.copyWith(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body4.copyWith(
            color: isGood ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
