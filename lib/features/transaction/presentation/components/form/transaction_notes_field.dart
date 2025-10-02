import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/extensions/localization_extension.dart';

class TransactionNotesField extends HookConsumerWidget {
  final TextEditingController controller;

  const TransactionNotesField({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomTextField(
      controller: controller,
      label: context.l10n.writeNote,
      hint: context.l10n.writeHereHint,
      prefixIcon: HugeIcons.strokeRoundedNote,
      minLines: 1,
      maxLines: 3,
      maxLength: 500,
    );
  }
}
