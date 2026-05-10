import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

/// Date range options for SMS scanning
enum SmsDateRange {
  last30Days,
  last90Days,
  allTime,
}

extension SmsDateRangeExtension on SmsDateRange {
  String getTitle(BuildContext context) {
    switch (this) {
      case SmsDateRange.last30Days:
        return 'Last 30 days';
      case SmsDateRange.last90Days:
        return 'Last 90 days';
      case SmsDateRange.allTime:
        return 'All time';
    }
  }

  String getDescription(BuildContext context) {
    switch (this) {
      case SmsDateRange.last30Days:
        return 'Faster scan, recent transactions only';
      case SmsDateRange.last90Days:
        return 'Balanced scan with recent history';
      case SmsDateRange.allTime:
        return 'Complete history, may take longer';
    }
  }

  List<List> get icon {
    switch (this) {
      case SmsDateRange.last30Days:
        return HugeIcons.strokeRoundedCalendar01;
      case SmsDateRange.last90Days:
        return HugeIcons.strokeRoundedCalendar03;
      case SmsDateRange.allTime:
        return HugeIcons.strokeRoundedCalendarCheckIn01;
    }
  }

  /// Get the start date for this range
  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case SmsDateRange.last30Days:
        return now.subtract(const Duration(days: 30));
      case SmsDateRange.last90Days:
        return now.subtract(const Duration(days: 90));
      case SmsDateRange.allTime:
        return null; // No limit
    }
  }
}

/// Bottom sheet for selecting SMS scan date range
class SmsDateRangeBottomSheet extends StatefulWidget {
  const SmsDateRangeBottomSheet({super.key});

  static Future<SmsDateRange?> show(BuildContext context) async {
    return await showModalBottomSheet<SmsDateRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SmsDateRangeBottomSheet(),
    );
  }

  @override
  State<SmsDateRangeBottomSheet> createState() => _SmsDateRangeBottomSheetState();
}

class _SmsDateRangeBottomSheetState extends State<SmsDateRangeBottomSheet> {
  SmsDateRange _selectedRange = SmsDateRange.last30Days;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: AppSpacing.spacing24),

              // Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: AppSpacing.spacing20),

              // Title
              Text(
                context.l10n.autoTransactionScanSms,
                style: AppTextStyles.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.spacing8),

              // Subtitle
              Text(
                'Select how far back to scan for transactions',
                style: AppTextStyles.body3.copyWith(
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.spacing24),

              // Date range options
              ...SmsDateRange.values.map((range) => _buildRangeOption(range)),

              const SizedBox(height: AppSpacing.spacing24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(_selectedRange),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 20),
                      label: Text(context.l10n.autoTransactionScanSms),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeOption(SmsDateRange range) {
    final isSelected = _selectedRange == range;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: InkWell(
        onTap: () => setState(() => _selectedRange = range),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.spacing8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : AppColors.neutral200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: range.icon,
                  size: 24,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.neutral500,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      range.getTitle(context),
                      style: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      range.getDescription(context),
                      style: AppTextStyles.body4.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
