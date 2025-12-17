import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/features/family/presentation/riverpod/family_providers.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';

/// Screen to select wallets to share with family
class ShareWalletScreen extends HookConsumerWidget {
  const ShareWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final walletsAsync = ref.watch(allWalletsStreamProvider);
    final sharedWalletsAsync = ref.watch(sharedWalletsProvider);
    final selectedWalletIds = useState<Set<int>>({});
    final isLoading = useState(false);

    if (currentFamily == null) {
      return CustomScaffold(
        context: context,
        title: 'Share Wallets',
        showBackButton: true,
        body: const Center(
          child: Text('No family group selected'),
        ),
      );
    }

    // Initialize selected wallets from already shared ones
    useEffect(() {
      sharedWalletsAsync.whenData((sharedWallets) {
        selectedWalletIds.value = sharedWallets
            .where((sw) => sw.isActive)
            .map((sw) => sw.walletId)
            .whereType<int>()
            .toSet();
      });
      return null;
    }, [sharedWalletsAsync]);

    return CustomScaffold(
      context: context,
      title: 'Share Wallets',
      showBackButton: true,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.spacing16),
                    decoration: BoxDecoration(
                      color: context.purpleBackground,
                      borderRadius: BorderRadius.circular(AppRadius.radius12),
                      border: Border.all(color: context.purpleBorderLighter),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationCircle as dynamic,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const Gap(AppSpacing.spacing12),
                        Expanded(
                          child: Text(
                            'Select wallets to share with ${currentFamily.name}. Shared wallets will be visible to all family members.',
                            style: AppTextStyles.body4.copyWith(color: AppColors.neutral500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.spacing24),

                  // Wallets list
                  Text(
                    'Your Wallets',
                    style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Gap(AppSpacing.spacing12),

                  walletsAsync.when(
                    data: (wallets) => _buildWalletsList(
                      context,
                      wallets,
                      selectedWalletIds,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacing20),
            decoration: BoxDecoration(
              color: context.floatingContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          isLoading.value = true;
                          // TODO: Save shared wallets
                          await Future.delayed(const Duration(seconds: 1));
                          isLoading.value = false;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Wallet sharing updated!')),
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
                      : Text('Save (${selectedWalletIds.value.length} selected)'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletsList(
    BuildContext context,
    List<WalletModel> wallets,
    ValueNotifier<Set<int>> selectedWalletIds,
  ) {
    if (wallets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppRadius.radius8),
        ),
        child: Center(
          child: Column(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedWallet01 as dynamic,
                color: AppColors.neutral400,
                size: 48,
              ),
              const Gap(AppSpacing.spacing12),
              Text(
                'No wallets yet',
                style: AppTextStyles.body3.copyWith(color: AppColors.neutral500),
              ),
              const Gap(AppSpacing.spacing4),
              Text(
                'Create a wallet first to share it with your family',
                style: AppTextStyles.body5.copyWith(color: AppColors.neutral400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: wallets.map((wallet) {
        final isSelected = wallet.id != null && selectedWalletIds.value.contains(wallet.id);

        return GestureDetector(
          onTap: () {
            if (wallet.id == null) return;
            final newSet = Set<int>.from(selectedWalletIds.value);
            if (isSelected) {
              newSet.remove(wallet.id);
            } else {
              newSet.add(wallet.id!);
            }
            selectedWalletIds.value = newSet;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
            padding: const EdgeInsets.all(AppSpacing.spacing12),
            decoration: BoxDecoration(
              color: isSelected ? context.purpleBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.radius8),
              border: Border.all(
                color: isSelected ? AppColors.primary : context.purpleBorderLighter,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (wallet.id == null) return;
                    final newSet = Set<int>.from(selectedWalletIds.value);
                    if (value == true) {
                      newSet.add(wallet.id!);
                    } else {
                      newSet.remove(wallet.id);
                    }
                    selectedWalletIds.value = newSet;
                  },
                  activeColor: AppColors.primary,
                ),
                const Gap(AppSpacing.spacing8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    borderRadius: BorderRadius.circular(AppRadius.radius8),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedWallet01 as dynamic,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const Gap(AppSpacing.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: AppTextStyles.body3.copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        wallet.formattedBalance,
                        style: AppTextStyles.body5.copyWith(color: AppColors.neutral500),
                      ),
                    ],
                  ),
                ),
                if (wallet.isShared)
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
                      'Shared',
                      style: AppTextStyles.body5.copyWith(
                        color: AppColors.green200,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
