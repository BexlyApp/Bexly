import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

class TransactionTitleField extends HookConsumerWidget {
  final TextEditingController controller;
  final bool isEditing;

  const TransactionTitleField({
    super.key,
    required this.controller,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomTextField(
      controller: controller,
      label: context.l10n.titleMax50,
      hint: context.l10n.lunchWithFriendsHint,
      prefixIcon: HugeIcons.strokeRoundedArrangeByLettersAZ,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.name,
      isRequired: true,
      autofocus: !isEditing,
      maxLength: 50,
      customCounterText: '',
    );
  }
}
