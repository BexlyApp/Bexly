import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/family/presentation/riverpod/family_providers.dart';
import 'package:bexly/features/family/presentation/components/create_family_dialog.dart';

/// Screen to manage family settings, members, and invitations
class FamilySettingsScreen extends ConsumerWidget {
  const FamilySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final familyMembersAsync = ref.watch(familyMembersProvider);
    final pendingInvitationsAsync = ref.watch(pendingInvitationsProvider);

    return CustomScaffold(
      context: context,
      title: 'Family Settings',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No family - show create option
            if (currentFamily == null) ...[
              _buildNoFamilyCard(context, ref),
            ] else ...[
              // Family info card
              _buildFamilyInfoCard(context, currentFamily.name),
              const Gap(AppSpacing.spacing16),

              // Members section
              Text(
                'Members',
                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(AppSpacing.spacing8),
              familyMembersAsync.when(
                data: (members) => _buildMembersList(context, members),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const Gap(AppSpacing.spacing16),

              // Pending invitations section
              Text(
                'Pending Invitations',
                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(AppSpacing.spacing8),
              pendingInvitationsAsync.when(
                data: (invitations) => invitations.isEmpty
                    ? _buildEmptyState('No pending invitations')
                    : _buildInvitationsList(context, invitations),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const Gap(AppSpacing.spacing16),

              // Invite button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to invite screen
                  },
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Invite Family Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoFamilyCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: context.purpleBackground,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: context.purpleBorderLighter),
      ),
      child: Column(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedUserGroup as dynamic,
            color: AppColors.primary,
            size: 48,
          ),
          const Gap(AppSpacing.spacing12),
          Text(
            'No Family Group',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          const Gap(AppSpacing.spacing8),
          Text(
            'Create a family group to share wallets and track expenses together',
            textAlign: TextAlign.center,
            style: AppTextStyles.body4.copyWith(color: AppColors.neutral500),
          ),
          const Gap(AppSpacing.spacing16),
          ElevatedButton(
            onPressed: () async {
              final familyName = await CreateFamilyDialog.show(context);
              if (familyName != null && familyName.isNotEmpty) {
                // TODO: Create family in database
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Family Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoCard(BuildContext context, String familyName) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: context.purpleBackground,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: context.purpleBorderLighter),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(AppRadius.radius8),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup as dynamic,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const Gap(AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  familyName,
                  style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Family Group',
                  style: AppTextStyles.body5.copyWith(color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Edit family settings
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(BuildContext context, List members) {
    if (members.isEmpty) {
      return _buildEmptyState('No members yet');
    }

    return Column(
      children: members.map((member) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            color: context.purpleBackground,
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            border: Border.all(color: context.purpleBorderLighter),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary100,
                child: Text(
                  (member.displayName ?? member.email ?? 'U')[0].toUpperCase(),
                  style: AppTextStyles.body3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Gap(AppSpacing.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName ?? member.email ?? 'Unknown',
                      style: AppTextStyles.body4.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      member.role.displayName,
                      style: AppTextStyles.body5.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing8,
                  vertical: AppSpacing.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenAlpha10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  member.status.displayName,
                  style: AppTextStyles.body5.copyWith(
                    color: AppColors.green200,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvitationsList(BuildContext context, List invitations) {
    return Column(
      children: invitations.map((invitation) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            color: context.purpleBackground,
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            border: Border.all(color: context.purpleBorderLighter),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.tertiaryAlpha10,
                child: Icon(
                  Icons.mail_outline,
                  color: AppColors.tertiary,
                  size: 20,
                ),
              ),
              const Gap(AppSpacing.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.invitedEmail,
                      style: AppTextStyles.body4.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Role: ${invitation.role.displayName}',
                      style: AppTextStyles.body5.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Cancel invitation
                },
                icon: const Icon(Icons.close, color: AppColors.red),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTextStyles.body4.copyWith(color: AppColors.neutral500),
        ),
      ),
    );
  }
}
