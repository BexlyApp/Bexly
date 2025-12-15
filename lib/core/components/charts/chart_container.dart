import 'package:flutter/material.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';

class ChartContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? height;

  const ChartContainer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chart,
    this.margin,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate chart height (total height minus padding and text)
    // Title ~24px + subtitle ~18px + spacing ~8px + padding ~32px = ~82px overhead
    final chartHeight = height != null ? (height! - 82).clamp(100.0, double.infinity) : null;

    return Container(
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: context.purpleBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Text(
            title,
            style: AppTextStyles.heading6.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            subtitle,
            style: AppTextStyles.body3.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          // Use SizedBox with explicit height instead of Expanded
          // This ensures chart renders even on platforms with layout differences
          if (chartHeight != null)
            SizedBox(height: chartHeight, child: chart)
          else
            Expanded(child: chart),
        ],
      ),
    );
  }
}
