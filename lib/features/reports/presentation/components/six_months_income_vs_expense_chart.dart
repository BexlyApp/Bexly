import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bexly/core/components/charts/chart_container.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/features/reports/data/models/monthly_financial_summary_model.dart';
import 'package:bexly/features/reports/presentation/riverpod/financial_health_provider.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

class SixMonthsIncomeExpenseChart extends ConsumerWidget {
  const SixMonthsIncomeExpenseChart({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final summaryAsync = ref.watch(sixMonthSummaryProvider);

    return ChartContainer(
      title: context.l10n.incomeVsExpense,
      subtitle: context.l10n.lastSixMonths,
      height: 300,
      chart: summaryAsync.when(
        data: (data) => _buildChart(context, data, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading data: $err')),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<MonthlyFinancialSummary> data,
    WidgetRef ref,
  ) {
    if (data.isEmpty || data.every((e) => e.income == 0 && e.expense == 0)) {
      return Center(child: Text(context.l10n.noTransactionDataYet));
    }

    // Calculate max Y to give some headroom
    double maxIncome = 0;
    double maxExpense = 0;
    for (var item in data) {
      if (item.income > maxIncome) maxIncome = item.income;
      if (item.expense > maxExpense) maxExpense = item.expense;
    }

    // Set maxY based on the larger value
    double maxY = maxIncome > maxExpense ? maxIncome : maxExpense;

    // Add 20% buffer
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    // Calculate minY to ensure small values are visible
    // If expense is very small compared to income (< 5%), adjust minY
    double minY = 0;
    if (maxExpense > 0 && maxExpense < maxY * 0.05) {
      // Set minY to negative to "lift" the expense line
      minY = -(maxY * 0.1);
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
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
                  AppTextStyles.body3.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
            getTooltipColor: (touchedSpot) => context.purpleBackground,
            tooltipBorder: BorderSide(color: context.purpleBorderLighter),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
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
                    DateFormat('MMM').format(data[index].month),
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
        minY: minY,
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
