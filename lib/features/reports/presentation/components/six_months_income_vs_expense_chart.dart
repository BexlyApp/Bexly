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

class SixMonthsIncomeExpenseChart extends ConsumerWidget {
  const SixMonthsIncomeExpenseChart({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final summaryAsync = ref.watch(sixMonthSummaryProvider);

    return ChartContainer(
      title: 'Income vs. Expense',
      subtitle: 'Last 6 Months',
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
      return const Center(child: Text('No transaction data available yet.'));
    }

    // Calculate max Y to give some headroom
    double maxY = 0;
    for (var item in data) {
      if (item.income > maxY) maxY = item.income;
      if (item.expense > maxY) maxY = item.expense;
    }
    // Add 20% buffer
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;

                String label = barSpot.barIndex == 0 ? 'Income' : 'Expense';
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
                  NumberFormat.compact().format(value),
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
}
