import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

/// Render an agent tool call as a card the user can confirm or cancel.
///
/// Phase 3.4 will wire this into the chat stream once the agent endpoint
/// emits structured tool-call events. For Phase 3.1, this widget exists so
/// the design + interaction model is locked in.
class ActionConfirmationCard extends StatelessWidget {
  const ActionConfirmationCard({
    super.key,
    required this.title,
    required this.body,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String body;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.body2),
          const Gap(AppSpacing.spacing4),
          Text(
            body,
            style: AppTextStyles.body4.copyWith(color: AppColors.neutral700),
          ),
          const Gap(AppSpacing.spacing12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Hủy'),
                ),
              ),
              const Gap(AppSpacing.spacing8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
