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
              padding: const EdgeInsets.all(AppSpacing.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current plan banner
                  _CurrentPlanBanner(tier: subscriptionState.tier),
                  const Gap(AppSpacing.spacing24),

                  // Free tier info (always show)
                  _FreeTierCard(
                    isCurrentPlan: subscriptionState.tier == SubscriptionTier.free,
                  ),
                  const Gap(AppSpacing.spacing16),

                  // Plan cards
                  _PlanCard(
                    title: 'Plus',
                    monthlyPrice: notifier.getPrice(SubscriptionProducts.plusMonthly) ?? '\$2.99',
                    yearlyPrice: notifier.getPrice(SubscriptionProducts.plusYearly) ?? '\$29.99',
                    features: [
                      l10n.unlimitedWallets,
                      l10n.unlimitedBudgetsGoals,
                      l10n.unlimitedRecurring,
                      l10n.aiMessagesPerMonth,
                      l10n.sixMonthsAnalytics,
                      l10n.multiCurrencySupport,
                      l10n.cloudSync,
                      l10n.receiptPhotos1GB,
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

                  _PlanCard(
                    title: 'Pro',
                    monthlyPrice: notifier.getPrice(SubscriptionProducts.proMonthly) ?? '\$5.99',
                    yearlyPrice: notifier.getPrice(SubscriptionProducts.proYearly) ?? '\$59.99',
                    features: [
                      l10n.everythingInPlus,
                      l10n.unlimitedAiMessages,
                      l10n.fullAnalyticsHistory,
                      l10n.unlimitedReceiptStorage,
                      l10n.ocrReceiptScanning,
                      l10n.prioritySupport,
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
                  const Gap(AppSpacing.spacing24),

                  // Restore purchases button
                  Center(
                    child: TextButton(
                      onPressed: () => _restorePurchases(context, ref),
                      child: Text(l10n.restorePurchases),
                    ),
                  ),
                  const Gap(AppSpacing.spacing16),

                  // Error message
                  if (subscriptionState.error != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.redAlpha10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.red),
                          const Gap(AppSpacing.spacing8),
                          Expanded(
                            child: Text(
                              subscriptionState.error!,
                              style: AppTextStyles.body3.copyWith(color: AppColors.red),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: _getTierIcon(tier),
                color: Colors.white,
                size: 20,
              ),
              const Gap(AppSpacing.spacing8),
              Text(
                l10n.currentPlan,
                style: AppTextStyles.body4.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.spacing4),
          Text(
            'Bexly ${tier.displayName}',
            style: AppTextStyles.heading5.copyWith(
              color: Colors.white,
            ),
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
        return (AppColors.primary400, AppColors.primary700);
      case SubscriptionTier.pro:
        return (AppColors.purple400, AppColors.purple700);
    }
  }

  List<List<dynamic>> _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return HugeIcons.strokeRoundedUser;
      case SubscriptionTier.plus:
        return HugeIcons.strokeRoundedCrown;
      case SubscriptionTier.pro:
        return HugeIcons.strokeRoundedDiamond01;
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
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
        color: isDark ? AppColors.neutral950 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? accentColor : (isDark ? AppColors.neutral800 : AppColors.neutral200),
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(isDark ? 40 : 20),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading6.copyWith(
                    color: accentColor,
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing8,
                      vertical: AppSpacing.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.bestValue,
                      style: AppTextStyles.body5.copyWith(
                        color: Colors.white,
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.current,
                      style: AppTextStyles.body5.copyWith(
                        color: Colors.white,
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
                      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                            color: accentColor,
                            size: 18,
                          ),
                          const Gap(AppSpacing.spacing8),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.body3,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Gap(AppSpacing.spacing12),

                // Price buttons
                if (!isCurrentPlan) ...[
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
                      const Gap(AppSpacing.spacing12),
                      Expanded(
                        child: _PriceButton(
                          price: yearlyPrice,
                          period: l10n.perYear,
                          onTap: onYearlyTap,
                          accentColor: accentColor,
                          isPrimary: true,
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

  const _PriceButton({
    required this.price,
    required this.period,
    required this.accentColor,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isPrimary ? accentColor : (isDark ? accentColor.withAlpha(30) : accentColor.withAlpha(20)),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.spacing12,
            horizontal: AppSpacing.spacing8,
          ),
          child: Column(
            children: [
              Text(
                price,
                style: AppTextStyles.body2.copyWith(
                  color: isPrimary ? Colors.white : accentColor,
                ),
              ),
              Text(
                period,
                style: AppTextStyles.body5.copyWith(
                  color: isPrimary ? Colors.white70 : accentColor.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreeTierCard extends StatelessWidget {
  final bool isCurrentPlan;

  const _FreeTierCard({required this.isCurrentPlan});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    const accentColor = AppColors.neutral500;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral950 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan ? accentColor : (isDark ? AppColors.neutral800 : AppColors.neutral200),
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(isDark ? 40 : 20),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      color: accentColor,
                      size: 20,
                    ),
                    const Gap(AppSpacing.spacing8),
                    Text(
                      'Free',
                      style: AppTextStyles.heading6.copyWith(
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing8,
                      vertical: AppSpacing.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.current,
                      style: AppTextStyles.body5.copyWith(
                        color: Colors.white,
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
                _FreeTierFeatureRow(
                  icon: HugeIcons.strokeRoundedWallet01,
                  text: '3 wallets',
                ),
                _FreeTierFeatureRow(
                  icon: HugeIcons.strokeRoundedChartRose,
                  text: '2 budgets & 2 goals',
                ),
                _FreeTierFeatureRow(
                  icon: HugeIcons.strokeRoundedRepeat,
                  text: '5 recurring transactions',
                ),
                _FreeTierFeatureRow(
                  icon: HugeIcons.strokeRoundedAiBrain01,
                  text: '20 AI messages/month (Standard)',
                ),
                _FreeTierFeatureRow(
                  icon: HugeIcons.strokeRoundedAnalytics01,
                  text: '3 months analytics history',
                ),
                _FreeTierFeatureRow(
                  icon: HugeIcons.strokeRoundedCloud,
                  text: 'Basic cloud sync',
                ),
                const Gap(AppSpacing.spacing8),
                // Ads notice
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing12),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryAlpha10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification03,
                        color: AppColors.tertiary700,
                        size: 18,
                      ),
                      const Gap(AppSpacing.spacing8),
                      Expanded(
                        child: Text(
                          'Contains ads',
                          style: AppTextStyles.body4.copyWith(
                            color: AppColors.tertiary700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeTierFeatureRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;

  const _FreeTierFeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: icon,
            color: AppColors.neutral500,
            size: 18,
          ),
          const Gap(AppSpacing.spacing8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body3,
            ),
          ),
        ],
      ),
    );
  }
}
