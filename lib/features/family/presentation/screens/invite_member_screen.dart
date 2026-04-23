import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/family/domain/enums/family_role.dart';
import 'package:bexly/features/family/presentation/riverpod/family_providers.dart';

/// Screen to invite new members to the family
class InviteMemberScreen extends HookConsumerWidget {
  const InviteMemberScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final emailController = useTextEditingController();
    final selectedRole = useState(FamilyRole.viewer);
    final isLoading = useState(false);

    if (currentFamily == null) {
      return CustomScaffold(
        context: context,
        title: 'Invite Member',
        showBackButton: true,
        body: const Center(
          child: Text('No family group selected'),
        ),
      );
    }

    return CustomScaffold(
      context: context,
      title: 'Invite Member',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Share link section
            _buildShareLinkSection(context, currentFamily.inviteCode),
            const Gap(AppSpacing.spacing24),

            // Or divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.neutral200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing12),
                  child: Text(
                    'OR',
                    style: AppTextStyles.body5.copyWith(color: AppColors.neutral500),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.neutral200)),
              ],
            ),
            const Gap(AppSpacing.spacing24),

            // Email invite section
            Text(
              'Invite by Email',
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(AppSpacing.spacing8),
            Text(
              'Send an invitation to a specific email address',
              style: AppTextStyles.body4.copyWith(color: AppColors.neutral500),
            ),
            const Gap(AppSpacing.spacing16),

            // Email input
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter email address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radius8),
                ),
              ),
            ),
            const Gap(AppSpacing.spacing16),

            // Role selector
            Text(
              'Role',
              style: AppTextStyles.body3.copyWith(fontWeight: FontWeight.w500),
            ),
            const Gap(AppSpacing.spacing8),
            _buildRoleSelector(context, selectedRole),
            const Gap(AppSpacing.spacing24),

            // Send invite button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        if (emailController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an email address')),
                          );
                          return;
                        }
                        isLoading.value = true;
                        // TODO: Send invitation
                        await Future.delayed(const Duration(seconds: 1));
                        isLoading.value = false;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invitation sent!')),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send Invitation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareLinkSection(BuildContext context, String? inviteCode) {
    final shareLink = inviteCode != null
        ? 'join.bexly.app/f/$inviteCode'
        : 'No invite link available';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: context.purpleBackground,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: context.purpleBorderLighter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLink01 as dynamic,
                color: AppColors.primary,
                size: 24,
              ),
              const Gap(AppSpacing.spacing8),
              Text(
                'Share Invite Link',
                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Gap(AppSpacing.spacing12),
          Text(
            'Anyone with this link can request to join your family',
            style: AppTextStyles.body4.copyWith(color: AppColors.neutral500),
          ),
          const Gap(AppSpacing.spacing12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacing12),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.radius8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    shareLink,
                    style: AppTextStyles.body4.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(
    BuildContext context,
    ValueNotifier<FamilyRole> selectedRole,
  ) {
    return Column(
      children: [
        _buildRoleOption(
          context,
          role: FamilyRole.editor,
          title: 'Editor',
          description: 'Can add/edit transactions and share wallets',
          isSelected: selectedRole.value == FamilyRole.editor,
          onTap: () => selectedRole.value = FamilyRole.editor,
        ),
        const Gap(AppSpacing.spacing8),
        _buildRoleOption(
          context,
          role: FamilyRole.viewer,
          title: 'Viewer',
          description: 'Can only view shared wallets and transactions',
          isSelected: selectedRole.value == FamilyRole.viewer,
          onTap: () => selectedRole.value = FamilyRole.viewer,
        ),
      ],
    );
  }

  Widget _buildRoleOption(
    BuildContext context, {
    required FamilyRole role,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        decoration: BoxDecoration(
          color: isSelected ? context.purpleBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.radius8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.neutral200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<FamilyRole>(
              value: role,
              groupValue: isSelected ? role : null,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body3.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.body5.copyWith(color: AppColors.neutral500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
