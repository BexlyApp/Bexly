import 'package:flutter/material.dart';
import 'package:bexly/core/constants/app_spacing.dart';

class CustomTab extends Tab {
  final String label;

  CustomTab({
    super.key,
    super.height,
    super.icon,
    super.iconMargin,
    required this.label,
  }) : super(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing12,
            ),
            child: Text(label),
          ),
        );
}
