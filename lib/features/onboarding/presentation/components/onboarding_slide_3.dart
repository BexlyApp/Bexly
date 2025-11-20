import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/services/device_location_service.dart';
import 'package:bexly/features/wallet/data/model/wallet_model.dart';
import 'package:bexly/features/wallet/riverpod/wallet_providers.dart';
import 'package:bexly/features/wallet/screens/wallet_form_bottom_sheet.dart';
import 'package:bexly/features/onboarding/presentation/components/avatar_picker.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';

/// Provider to hold display name
final displayNameProvider = StateProvider.autoDispose<String>((ref) {
  // Pre-fill with Firebase user display name if available
  final firebaseDisplayName = ref.watch(userDisplayNameProvider);
  return firebaseDisplayName ?? '';
});

class OnboardingSlide3 extends HookConsumerWidget {
  const OnboardingSlide3({super.key});

  /// Get currency based on device location using DeviceLocationService
  /// Priority: SIM card → Timezone → Locale → Default USD
  Future<Currency> _getCurrencyFromDevice(WidgetRef ref) async {
    final currencies = ref.watch(currenciesStaticProvider);

    // Get country code from device (SIM → Timezone → Locale)
    final countryCode = await DeviceLocationService.getCountryCode();

    // Find currency by country code
    final currency = currencies.cast<Currency?>().firstWhere(
      (c) => c?.countryCode == countryCode,
      orElse: () => null,
    );

    // Final fallback to USD
    return currency ?? currencies.firstWhere(
      (c) => c.isoCode == 'USD',
      orElse: () => currencies.first,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for Firebase user info
    final firebaseDisplayName = ref.watch(userDisplayNameProvider);
    final firebasePhotoUrl = ref.watch(userPhotoUrlProvider);

    final displayName = ref.watch(displayNameProvider);
    final wallet = ref.watch(activeWalletProvider).valueOrNull;

    // Initialize currency from device location on first load
    final isInitialized = useState(false);
    useEffect(() {
      if (!isInitialized.value) {
        // Async call to get currency from device
        _getCurrencyFromDevice(ref).then((deviceCurrency) {
          ref.read(currencyProvider.notifier).state = deviceCurrency;
          isInitialized.value = true;
        });
      }
      return null;
    }, []);

    // Pre-fill name controller with Firebase display name
    final nameController = useTextEditingController(
      text: firebaseDisplayName ?? displayName,
    );

    // Update name controller if Firebase name changes
    useEffect(() {
      if (firebaseDisplayName != null && nameController.text.isEmpty) {
        nameController.text = firebaseDisplayName;
        ref.read(displayNameProvider.notifier).state = firebaseDisplayName;
      }
      return null;
    }, [firebaseDisplayName]);

    final walletText = wallet != null
        ? '${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}'
        : 'Tap to setup your first wallet';

    final walletTextController = useTextEditingController(text: walletText);

    useEffect(() {
      final newText = wallet != null
          ? '${wallet.currencyByIsoCode(ref).symbol} ${wallet.balance.toPriceFormat()}'
          : 'Tap to setup your first wallet';
      if (walletTextController.text != newText) {
        walletTextController.text = newText;
      }
      return null;
    }, [wallet]);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing24,
        vertical: AppSpacing.spacing40,
      ),
      child: Column(
        children: [
          // Title
          const Text(
            'Setup Your Profile',
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.spacing40),

          // Avatar Picker (will use Firebase photo URL if available)
          AvatarPicker(
            initialImageUrl: firebasePhotoUrl,
          ),
          const Gap(AppSpacing.spacing32),

          // Display Name
          CustomTextField(
            context: context,
            controller: nameController,
            label: 'Display Name',
            hint: 'Enter your name',
            prefixIcon: HugeIcons.strokeRoundedUser,
            isRequired: true, // Mark as required with red asterisk
            onChanged: (value) {
              ref.read(displayNameProvider.notifier).state = value;
            },
          ),
          const Gap(AppSpacing.spacing32),

          // Divider
          const Divider(),
          const Gap(AppSpacing.spacing24),

          // Wallet setup section
          const Text(
            'Setup Your First Wallet',
            style: AppTextStyles.heading4,
            textAlign: TextAlign.center,
          ),
          const Gap(AppSpacing.spacing16),

          // Wallet field (tap to edit)
          CustomTextField(
            context: context,
            controller: walletTextController,
            label: wallet?.name ?? 'Wallet',
            hint: wallet != null ? '' : 'Tap to setup your first wallet',
            prefixIcon: HugeIcons.strokeRoundedWallet01,
            isRequired: true, // Mark as required with red asterisk
            readOnly: true,
            onTap: () {
              context.openBottomSheet(
                child: WalletFormBottomSheet(
                  wallet: wallet, // Edit current wallet or create first one
                  showDeleteButton: false,
                  allowFullEdit: true,
                ),
              );
            },
          ),
          const Gap(AppSpacing.spacing12),

          // Add another wallet button (only show after first wallet created)
          if (wallet != null)
            InkWell(
              onTap: () {
                context.openBottomSheet(
                  child: WalletFormBottomSheet(
                    wallet: null, // Create new wallet
                    showDeleteButton: false,
                    allowFullEdit: true,
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIcons.strokeRoundedAdd01,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const Gap(AppSpacing.spacing8),
                  Text(
                    'Add another wallet',
                    style: AppTextStyles.body3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Gap(AppSpacing.spacing24),
        ],
      ),
    );
  }
}
