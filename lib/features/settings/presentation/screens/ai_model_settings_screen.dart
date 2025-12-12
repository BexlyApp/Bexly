import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/settings/presentation/riverpod/ai_model_provider.dart';

class AIModelSettingsScreen extends ConsumerWidget {
  const AIModelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedModel = ref.watch(aiModelProvider);
    final theme = Theme.of(context);

    return CustomScaffold(
      context: context,
      title: 'AI Model',
      showBackButton: true,
      showBalance: false,
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing20,
          AppSpacing.spacing0,
          AppSpacing.spacing20,
          AppSpacing.spacing20,
        ),
        itemCount: AIModel.values.length + 1, // +1 for info card
        separatorBuilder: (context, index) => const Gap(AppSpacing.spacing12),
        itemBuilder: (context, index) {
          // Last item is info card
          if (index == AIModel.values.length) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.spacing12),
              decoration: BoxDecoration(
                color: AppColors.purple50,
                borderRadius: BorderRadius.circular(AppRadius.radius8),
                border: Border.all(color: AppColors.purpleAlpha10),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const Gap(AppSpacing.spacing12),
                  Expanded(
                    child: Text(
                      'Standard is free for all users. Premium requires Plus, Flagship requires Pro subscription.',
                      style: AppTextStyles.body4.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final model = AIModel.values[index];
          final isSelected = selectedModel == model;

          return _buildModelOption(context, ref, model, isSelected: isSelected);
        },
      ),
    );
  }

  Widget _buildModelOption(
    BuildContext context,
    WidgetRef ref,
    AIModel model, {
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        ref.read(aiModelProvider.notifier).setModel(model);
      },
      borderRadius: BorderRadius.circular(AppRadius.radius8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : AppColors.purple50,
          borderRadius: BorderRadius.circular(AppRadius.radius8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : AppColors.purpleAlpha10,
          ),
        ),
        child: Row(
          children: [
            // Model icon
            Container(
              height: 50,
              width: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _getModelColor(model).withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.radius8),
                border: Border.all(
                  color: _getModelColor(model).withOpacity(0.3),
                ),
              ),
              child: HugeIcon(
                icon: _getModelIcon(model),
                color: _getModelColor(model),
                size: 24,
              ),
            ),
            const Gap(AppSpacing.spacing12),

            // Model info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        model.displayName,
                        style: AppTextStyles.body3.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (model == AIModel.dosAI) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FREE',
                            style: AppTextStyles.body5.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(4),
                  Text(
                    model.description,
                    style: AppTextStyles.body4.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  dynamic _getModelIcon(AIModel model) {
    switch (model) {
      case AIModel.dosAI:
        return HugeIcons.strokeRoundedAiBrain01;
      case AIModel.gemini:
        return HugeIcons.strokeRoundedSparkles;
      case AIModel.openAI:
        return HugeIcons.strokeRoundedArtificialIntelligence04;
    }
  }

  Color _getModelColor(AIModel model) {
    switch (model) {
      case AIModel.dosAI:
        return Colors.blue;
      case AIModel.gemini:
        return Colors.purple;
      case AIModel.openAI:
        return Colors.green;
    }
  }
}
