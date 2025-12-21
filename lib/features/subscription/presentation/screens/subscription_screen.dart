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
                      'Email sync (1 account)',
                      'Family sharing (3 members)',
                      'Ad-free',
                    ],
                    isCurrentPlan: subscriptionState.tier == SubscriptionTier.plus,
                    accentColor: AppColors.primary500,
                    monthlyProductId: SubscriptionProducts.plusMonthly,
                    yearlyProductId: SubscriptionProducts.plusYearly,
                    onPurchase: subscriptionState.tier.index < SubscriptionTier.plus.index
                        ? (productId) => _purchase(context, ref, productId)
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
                      'Email sync (3 accounts)',
                      'Family sharing (5 members, Editor role)',
                      'AI insights & predictions',
                      'Priority support',
                    ],
                    isCurrentPlan: subscriptionState.tier == SubscriptionTier.pro,
                    accentColor: AppColors.purple,
                    isRecommended: true,
                    monthlyProductId: SubscriptionProducts.proMonthly,
                    yearlyProductId: SubscriptionProducts.proYearly,
                    onPurchase: subscriptionState.tier.index < SubscriptionTier.pro.index
                        ? (productId) => _purchase(context, ref, productId)
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
    // Note: purchase() returns true when Google Play sheet is opened, not when purchase completes
    // The actual purchase result comes through the purchaseStream in SubscriptionService
    // UI will auto-update when subscription tier changes via the provider
    await ref.read(subscriptionProvider.notifier).purchase(productId);
    // Don't show success here - wait for actual purchase confirmation via stream
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

class _PlanCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String monthlyPrice;
  final String yearlyPrice;
  final List<String> features;
  final bool isCurrentPlan;
  final bool isRecommended;
  final Color accentColor;
  final String monthlyProductId;
  final String yearlyProductId;
  final void Function(String productId)? onPurchase;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.accentColor,
    required this.monthlyProductId,
    required this.yearlyProductId,
    this.isCurrentPlan = false,
    this.isRecommended = false,
    this.onPurchase,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _isYearly = true; // Default to yearly (better value)

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isCurrentPlan ? widget.accentColor : (isDark ? AppColors.neutral800 : AppColors.neutral200),
          width: widget.isCurrentPlan ? 2 : 1,
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
              color: widget.accentColor.withAlpha(isDark ? 30 : 15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.heading6.copyWith(color: widget.accentColor),
                    ),
                    Text(
                      widget.subtitle,
                      style: AppTextStyles.body5.copyWith(
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
                if (widget.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing8,
                      vertical: AppSpacing.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
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
                if (widget.isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spacing8,
                      vertical: AppSpacing.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
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
                ...widget.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: widget.accentColor,
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

                // Price section with toggle
                if (!widget.isCurrentPlan) ...[
                  const Gap(AppSpacing.spacing12),
                  // Monthly/Yearly toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isYearly = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isYearly
                                    ? (isDark ? AppColors.neutral700 : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_isYearly
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(10),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Monthly',
                                  style: AppTextStyles.body4.copyWith(
                                    fontWeight: !_isYearly ? FontWeight.w600 : FontWeight.w400,
                                    color: !_isYearly
                                        ? (isDark ? Colors.white : AppColors.neutral900)
                                        : AppColors.neutral500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isYearly = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isYearly
                                    ? (isDark ? AppColors.neutral700 : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isYearly
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(10),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Yearly',
                                      style: AppTextStyles.body4.copyWith(
                                        fontWeight: _isYearly ? FontWeight.w600 : FontWeight.w400,
                                        color: _isYearly
                                            ? (isDark ? Colors.white : AppColors.neutral900)
                                            : AppColors.neutral500,
                                      ),
                                    ),
                                    if (_isYearly) ...[
                                      const Gap(4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.tertiary500,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '-17%',
                                          style: AppTextStyles.body5.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.spacing12),

                  // Single purchase button
                  Material(
                    color: widget.accentColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: widget.onPurchase != null
                          ? () => widget.onPurchase!(
                              _isYearly ? widget.yearlyProductId : widget.monthlyProductId)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Text(
                              _isYearly ? widget.yearlyPrice : widget.monthlyPrice,
                              style: AppTextStyles.heading6.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _isYearly ? l10n.perYear : l10n.perMonth,
                              style: AppTextStyles.body5.copyWith(
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

