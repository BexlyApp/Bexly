import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/services/subscription/subscription.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final notifier = ref.read(subscriptionProvider.notifier);
    final l10n = context.l10n;

    return CustomScaffold(
      context: context,
      title: l10n.subscription,
      showBackButton: true,
      showBalance: false,
      body: subscriptionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current plan banner
                  _CurrentPlanBanner(tier: subscriptionState.tier),
                  const Gap(AppSpacing.spacing20),

                  // Plus plan
                  _PlanCard(
                    title: 'Plus',
                    subtitle: 'All Free features, plus:',
                    monthlyPrice: notifier.getPrice(SubscriptionProducts.plusMonthly) ?? '\$1.99',
                    yearlyPrice: notifier.getPrice(SubscriptionProducts.plusYearly) ?? '\$19.99',
                    features: const [
                      'Unlimited wallets, budgets & goals',
                      '240 AI messages/month',
                      '6 months analytics',
                      'Receipt scanning (1 year storage)',
                      'Email sync (1 account, 30 days)',
                      'Family sharing (3 members)',
                      'No ads',
                    ],
                    isCurrentPlan: subscriptionState.tier == SubscriptionTier.plus,
                    accentColor: AppColors.primary500,
                    onMonthlyTap: subscriptionState.tier.index < SubscriptionTier.plus.index
                        ? () => _purchase(context, ref, SubscriptionProducts.plusMonthly)
                        : null,
                    onYearlyTap: subscriptionState.tier.index < SubscriptionTier.plus.index
                        ? () => _purchase(context, ref, SubscriptionProducts.plusYearly)
                        : null,
                  ),
                  const Gap(AppSpacing.spacing16),

                  // Pro plan
                  _PlanCard(
                    title: 'Pro',
                    subtitle: 'All Plus features, plus:',
                    monthlyPrice: notifier.getPrice(SubscriptionProducts.proMonthly) ?? '\$3.99',
                    yearlyPrice: notifier.getPrice(SubscriptionProducts.proYearly) ?? '\$39.99',
                    features: const [
                      'Unlimited AI messages',
                      'Full analytics history',
                      'Receipt scanning (3 years storage)',
                      'Email sync (3 accounts, all time)',
                      'Family sharing (5 members, Editor role)',
                      'AI insights & predictions',
                      'Priority support',
                    ],
                    isCurrentPlan: subscriptionState.tier == SubscriptionTier.pro,
                    accentColor: AppColors.purple,
                    isRecommended: true,
                    onMonthlyTap: subscriptionState.tier.index < SubscriptionTier.pro.index
                        ? () => _purchase(context, ref, SubscriptionProducts.proMonthly)
                        : null,
                    onYearlyTap: subscriptionState.tier.index < SubscriptionTier.pro.index
                        ? () => _purchase(context, ref, SubscriptionProducts.proYearly)
                        : null,
                  ),
                  const Gap(AppSpacing.spacing16),

                  // Restore purchases button
                  Center(
                    child: TextButton(
                      onPressed: () => _restorePurchases(context, ref),
                      child: Text(l10n.restorePurchases),
                    ),
                  ),

                  // Error message
                  if (subscriptionState.error != null) ...[
                    const Gap(AppSpacing.spacing12),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.redAlpha10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.red, size: 18),
                          const Gap(AppSpacing.spacing8),
                          Expanded(
                            child: Text(
                              subscriptionState.error!,
                              style: AppTextStyles.body4.copyWith(color: AppColors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Gap(AppSpacing.spacing16),
                ],
              ),
            ),
    );
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref, String productId) async {
    final success = await ref.read(subscriptionProvider.notifier).purchase(productId);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.purchaseSuccessful)),
      );
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.purchasesRestored)),
      );
    }
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  final SubscriptionTier tier;

  const _CurrentPlanBanner({required this.tier});

  @override
  Widget build(BuildContext context) {
    final colors = _getTierColors(tier);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.$1, colors.$2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: _getTierIcon(tier),
            color: Colors.white,
            size: 24,
          ),
          const Gap(AppSpacing.spacing12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currentPlan,
                style: AppTextStyles.body5.copyWith(color: Colors.white70),
              ),
              Text(
                'Bexly ${tier.displayName}',
                style: AppTextStyles.heading6.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _getTierColors(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return (AppColors.neutral600, AppColors.neutral800);
      case SubscriptionTier.plus:
      case SubscriptionTier.plusFamily:
        return (AppColors.primary400, AppColors.primary700);
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return (AppColors.purple400, AppColors.purple700);
    }
  }

  dynamic _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return HugeIcons.strokeRoundedUser;
      case SubscriptionTier.plus:
      case SubscriptionTier.plusFamily:
        return HugeIcons.strokeRoundedCrown;
      case SubscriptionTier.pro:
      case SubscriptionTier.proFamily:
        return HugeIcons.strokeRoundedDiamond01;
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String monthlyPrice;
  final String yearlyPrice;
  final List<String> features;
  final bool isCurrentPlan;
  final bool isRecommended;
  final Color accentColor;
  final VoidCallback? onMonthlyTap;
  final VoidCallback? onYearlyTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.accentColor,
    this.isCurrentPlan = false,
    this.isRecommended = false,
    this.onMonthlyTap,
    this.onYearlyTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? accentColor : (isDark ? AppColors.neutral800 : AppColors.neutral200),
          width: isCurrentPlan ? 2 : 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing16,
              vertical: AppSpacing.spacing12,
            ),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(isDark ? 30 : 15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading6.copyWith(color: accentColor),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.body5.copyWith(
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing8,
                      vertical: AppSpacing.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.bestValue,
                      style: AppTextStyles.body5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing8,
                      vertical: AppSpacing.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.current,
                      style: AppTextStyles.body5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: accentColor,
                            size: 18,
                          ),
                          const Gap(AppSpacing.spacing8),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.body3.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                // Price buttons
                if (!isCurrentPlan) ...[
                  const Gap(AppSpacing.spacing12),
                  Row(
                    children: [
                      Expanded(
                        child: _PriceButton(
                          price: monthlyPrice,
                          period: l10n.perMonth,
                          onTap: onMonthlyTap,
                          accentColor: accentColor,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: _PriceButton(
                          price: yearlyPrice,
                          period: l10n.perYear,
                          onTap: onYearlyTap,
                          accentColor: accentColor,
                          isPrimary: true,
                          badge: '2 months free',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  final String price;
  final String period;
  final VoidCallback? onTap;
  final Color accentColor;
  final bool isPrimary;
  final String? badge;

  const _PriceButton({
    required this.price,
    required this.period,
    required this.accentColor,
    this.onTap,
    this.isPrimary = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isPrimary ? accentColor : (isDark ? accentColor.withAlpha(30) : accentColor.withAlpha(20)),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 8,
              ),
              child: Column(
                children: [
                  Text(
                    price,
                    style: AppTextStyles.body2.copyWith(
                      color: isPrimary ? Colors.white : accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    period,
                    style: AppTextStyles.body4.copyWith(
                      color: isPrimary ? Colors.white.withAlpha(220) : accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -10,
            right: 4,
            left: 4,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tertiary500,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.body5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

