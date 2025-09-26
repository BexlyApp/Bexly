import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

class CategoryIconInitialPicker extends HookConsumerWidget {
  const CategoryIconInitialPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: '');

    return CustomBottomSheet(
      title: 'Select Initial',
      child: Column(
        spacing: AppSpacing.spacing20,
        children: [
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading4,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: context.purpleBorder),
                  borderRadius: BorderRadius.circular(AppRadius.radius12),
                ),
                counterText: '',
                filled: true,
                fillColor: context.purpleBackground,
              ),
              maxLength: 2,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
            ),
          ),
          PrimaryButton(
            label: 'Confirm',
            onPressed: () => context.pop(controller.text),
          ),
        ],
      ),
    );
  }
}
