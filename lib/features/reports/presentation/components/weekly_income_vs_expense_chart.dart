import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bexly/core/components/charts/chart_container.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/reports/data/models/weekly_financial_summary_model.dart';
import 'package:bexly/features/reports/presentation/riverpod/financial_health_provider.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

class WeeklyIncomeExpenseChart extends ConsumerWidget {
  final DateTime date;

  const WeeklyIncomeExpenseChart({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklySummaryForMonthProvider(date));

    return ChartContainer(
      title: context.l10n.weeklyOverview,
      subtitle: context.l10n.currentMonthBreakdown,
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing16),
      chart: summaryAsync.when(
        data: (data) => _buildChart(context, data, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading data: $err')),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<WeeklyFinancialSummary> data,
    WidgetRef ref,
  ) {
    // Check if we have any data to show
    if (data.every((e) => e.income == 0 && e.expense == 0)) {
      return Center(child: Text(context.l10n.noTransactionsThisMonth));
    }

    // Calculate max Y to give some headroom
    double maxY = 0;
    for (var item in data) {
      Log.i('Week ${item.weekNumber}: income=${item.income}, expense=${item.expense}',
        label: 'WeeklyChart');
      if (item.income > maxY) maxY = item.income;
      if (item.expense > maxY) maxY = item.expense;
    }
    // Add 20% buffer
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;
    Log.i('Weekly chart maxY: $maxY', label: 'WeeklyChart');

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (group) => context.purpleBackground,
            tooltipBorder: BorderSide(color: context.purpleBorderLighter),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;

                String label = barSpot.barIndex == 0 ? context.l10n.income : context.l10n.expense;
                Color color = barSpot.barIndex == 0
                    ? AppColors.green200
                    : AppColors.red700;

                // Custom tooltip content
                return LineTooltipItem(
                  '$label: ${flSpot.y.toPriceFormat()}',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4, // 4 grid lines roughly
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withAlpha(20),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${context.l10n.week} ${data[index].weekNumber}',
                    style: AppTextStyles.body4.bold,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _formatCompact(value),
                  style: AppTextStyles.body4,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          // Income Line (Green)
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.income);
            }).toList(),
            isCurved: true,
            color: AppColors.green200,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.green200.withAlpha(20),
            ),
          ),
          // Expense Line (Red)
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.expense);
            }).toList(),
            isCurved: true,
            color: AppColors.red700,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.red700.withAlpha(20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
