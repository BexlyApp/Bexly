import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/services/ai/ai_quota_state.dart';

/// Compact "X / 600 messages this period" indicator that reads from
/// [aiQuotaProvider]. Renders nothing until the first AI response brings
/// `X-RateLimit-*` headers back from the gateway.
///
/// Visual states:
///  - hasData=false → empty (zero height)
///  - remaining > 20% of limit → green
///  - remaining 10-20%       → amber
///  - remaining < 10%        → red
///  - exhausted              → red with reset hint
class AiQuotaIndicator extends ConsumerWidget {
  const AiQuotaIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(aiQuotaProvider);
    if (!quota.hasData) return const SizedBox.shrink();

    final limit = quota.limit ?? 0;
    final remaining = quota.remaining ?? 0;
    final used = (limit - remaining).clamp(0, limit);
    final fraction = limit == 0 ? 0.0 : used / limit;

    final color = _colorFor(quota);
    final bg = color.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing8,
      ),
      color: bg,
      child: Row(
        children: [
          Icon(Icons.bolt_outlined, size: 16, color: color),
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.16),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Text(
            quota.isExhausted
                ? 'Hết quota tháng này'
                : '$used / $limit',
            style: AppTextStyles.body4.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(AiQuotaState quota) {
    if (quota.isExhausted) return AppColors.red600;
    final fraction = quota.usedFraction ?? 0;
    if (fraction >= 0.9) return AppColors.red600;
    if (fraction >= 0.8) return Colors.amber.shade700;
    return AppColors.primary500;
  }
}
