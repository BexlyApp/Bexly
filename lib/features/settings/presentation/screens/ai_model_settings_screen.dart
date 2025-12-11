import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select AI Model',
              style: AppTextStyles.heading3.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              'Choose which AI model to use for chat and transaction parsing.',
              style: AppTextStyles.body3.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing20),

            // AI Model Options
            ...AIModel.values.map((model) => _buildModelOption(
              context,
              ref,
              model,
              isSelected: selectedModel == model,
            )),

            const SizedBox(height: AppSpacing.spacing24),

            // Info card
            Container(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: Text(
                      'DOSAI is free for all users. Gemini and OpenAI require Plus or Pro subscription.',
                      style: AppTextStyles.body4.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: InkWell(
        onTap: () {
          ref.read(aiModelProvider.notifier).setModel(model);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Model icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getModelColor(model).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: _getModelIcon(model),
                    color: _getModelColor(model),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing16),

              // Model info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          model.displayName,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (model == AIModel.dosAI) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FREE',
                              style: AppTextStyles.body5.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      model.description,
                      style: AppTextStyles.body4.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
