import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

class CustomBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final EdgeInsets? padding;

  const CustomBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding:
            padding ??
            const EdgeInsets.fromLTRB(
              AppSpacing.spacing20,
              AppSpacing.spacing16,
              AppSpacing.spacing20,
              AppSpacing.spacing20,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: AppTextStyles.body1, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const Gap(AppSpacing.spacing8),
              Text(
                subtitle!,
                style: AppTextStyles.body3.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const Gap(AppSpacing.spacing32),
            child,
          ],
        ),
      ),
    );
  }
}
