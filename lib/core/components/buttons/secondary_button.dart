import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/loading_indicators/loading_indicator.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';

class SecondaryButton extends OutlinedButton {
  SecondaryButton({
    super.key,
    required BuildContext context,
    required super.onPressed,
    String? label,
    dynamic icon, // Support both IconData and List<List> (HugeIcons)
    bool isLoading = false,
  }) : super(
         style: OutlinedButton.styleFrom(
           backgroundColor: context.purpleBackground,
           side: BorderSide(color: context.purpleBorderLighter),
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(AppSpacing.spacing8),
           ),
         ),
         child: isLoading
             ? SizedBox.square(dimension: 22, child: LoadingIndicator())
             : Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   if (icon != null)
                     icon is IconData
                         ? Icon(icon, size: 22)
                         : HugeIcon(icon: icon, size: 22),
                   if (label != null) const Gap(AppSpacing.spacing8),
                   if (label != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 1),
                       child: Text(label, style: AppTextStyles.body3.semibold),
                     ),
                 ],
               ),
       );
}
