import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

/// Dialog to create a new family group
class CreateFamilyDialog extends HookConsumerWidget {
  const CreateFamilyDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => const CreateFamilyDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final isLoading = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Family Group',
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(AppSpacing.spacing8),
              Text(
                'Create a family group to share wallets and track expenses together',
                style: AppTextStyles.body4.copyWith(color: AppColors.neutral500),
              ),
              const Gap(AppSpacing.spacing20),

              // Family name input
              Text(
                'Family Name',
                style: AppTextStyles.body4.copyWith(fontWeight: FontWeight.w500),
              ),
              const Gap(AppSpacing.spacing8),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., The Smiths',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.radius8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a family name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const Gap(AppSpacing.spacing24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.body4.copyWith(color: AppColors.neutral500),
                    ),
                  ),
                  const Gap(AppSpacing.spacing12),
                  ElevatedButton(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            isLoading.value = true;
                            // Return the family name
                            await Future.delayed(const Duration(milliseconds: 300));
                            if (context.mounted) {
                              Navigator.of(context).pop(nameController.text.trim());
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
