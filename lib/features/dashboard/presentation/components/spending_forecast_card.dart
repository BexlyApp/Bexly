part of '../screens/dashboard_screen.dart';

/// Compact spending forecast card showing projected end-of-month balance
class SpendingForecastCard extends ConsumerWidget {
  const SpendingForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(spendingForecastProvider);

    return forecastAsync.when(
      data: (forecast) {
        if (forecast.isEmpty) return const SizedBox.shrink();
        return _ForecastCard(forecast: forecast);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final SpendingForecast forecast;
  const _ForecastCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = forecast.projectedIncome >= forecast.projectedExpense;
    final color = isPositive ? Colors.green : Colors.orange;

    String fmt(num v) => v.toInt().abs().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.radius16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 18,
                color: color,
              ),
              const Gap(6),
              Text(
                'End-of-Month Forecast',
                style: AppTextStyles.body4.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${forecast.daysRemaining}d left',
                style: AppTextStyles.body5.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const Gap(10),
          // Projected amounts row
          Row(
            children: [
              _ForecastMetric(
                label: 'Projected Expense',
                value: fmt(forecast.projectedExpense),
                color: Colors.red.shade300,
              ),
              const Gap(16),
              _ForecastMetric(
                label: 'Projected Income',
                value: fmt(forecast.projectedIncome),
                color: Colors.green.shade300,
              ),
              const Gap(16),
              _ForecastMetric(
                label: 'Daily Burn',
                value: '${fmt(forecast.dailyBurnRate)}/d',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
          const Gap(8),
          // Summary
          Text(
            forecast.summary,
            style: AppTextStyles.body5.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ForecastMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body5.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body4.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
