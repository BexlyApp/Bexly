import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
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
    final currentTier = subscriptionState.tier;

    // Build plan data list
    final plans = [
      _PlanData(
        tier: SubscriptionTier.free,
        title: 'Free',
        subtitle: 'Get started for free',
        monthlyPrice: '\$0',
        yearlyPrice: '\$0',
        features: const [
          '2 wallets, 2 budgets, 2 goals',
          '20 AI messages/month',
          '30 days analytics',
          'Basic reports',
          'Contains ads',
        ],
        accentColor: AppColors.neutral500,
        monthlyProductId: '',
        yearlyProductId: '',
      ),
      _PlanData(
        tier: SubscriptionTier.plus,
        title: 'Plus',
        subtitle: 'Best for couples',
        monthlyPrice: notifier.getPrice(SubscriptionProducts.plusMonthly) ?? '\$1.99',
        yearlyPrice: notifier.getPrice(SubscriptionProducts.plusYearly) ?? '\$19.99',
        features: const [
          '✨ All Free features, plus:',
          'Unlimited wallets, budgets & goals',
          '240 AI messages/month',
          '6 months analytics',
          'Receipt scanning (1 year storage)',
          'Email sync (1 account)',
          'Family sharing (2 members)',
          'Ad-free',
        ],
        accentColor: AppColors.primary500,
        monthlyProductId: SubscriptionProducts.plusMonthly,
        yearlyProductId: SubscriptionProducts.plusYearly,
      ),
      _PlanData(
        tier: SubscriptionTier.pro,
        title: 'Pro',
        subtitle: 'Best for power users',
        monthlyPrice: notifier.getPrice(SubscriptionProducts.proMonthly) ?? '\$3.99',
        yearlyPrice: notifier.getPrice(SubscriptionProducts.proYearly) ?? '\$39.99',
        features: const [
          '✨ All Plus features, plus:',
          'Unlimited AI messages',
          'Full analytics history',
          'Receipt scanning (3 years storage)',
          'Email sync (3 accounts)',
          'Family sharing (5 members, Editor role)',
          'AI insights & predictions',
          'Priority support',
        ],
        accentColor: AppColors.purple,
        isRecommended: true,
        monthlyProductId: SubscriptionProducts.proMonthly,
        yearlyProductId: SubscriptionProducts.proYearly,
      ),
    ];

    // Sort plans: current plan first, then by tier index
    plans.sort((a, b) {
      if (a.tier == currentTier) return -1;
      if (b.tier == currentTier) return 1;
      return a.tier.index.compareTo(b.tier.index);
    });

    return CustomScaffold(
      context: context,
      title: l10n.subscription,
      showBackButton: true,
      showBalance: false,
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plans
                  ...plans.map((plan) {
                    final isCurrentPlan = plan.tier == currentTier;
                    final isUpgrade = plan.tier.index > currentTier.index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.spacing16),
                      child: _PlanCard(
                        title: plan.title,
                        subtitle: plan.subtitle,
                        monthlyPrice: plan.monthlyPrice,
                        yearlyPrice: plan.yearlyPrice,
                        features: plan.features,
                        isCurrentPlan: isCurrentPlan,
                        isUpgrade: isUpgrade,
                        accentColor: plan.accentColor,
                        isRecommended: plan.isRecommended && !isCurrentPlan,
                        monthlyProductId: plan.monthlyProductId,
                        yearlyProductId: plan.yearlyProductId,
                        onPurchase: !isCurrentPlan
                            ? (productId) => _purchase(context, ref, productId)
                            : null,
                      ),
                    );
                  }),

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
    await ref.read(subscriptionProvider.notifier).purchase(productId);
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

/// Data class for plan information
class _PlanData {
  final SubscriptionTier tier;
  final String title;
  final String subtitle;
  final String monthlyPrice;
  final String yearlyPrice;
  final List<String> features;
  final Color accentColor;
  final bool isRecommended;
  final String monthlyProductId;
  final String yearlyProductId;

  _PlanData({
    required this.tier,
    required this.title,
    required this.subtitle,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.accentColor,
    this.isRecommended = false,
    required this.monthlyProductId,
    required this.yearlyProductId,
  });
}

class _PlanCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String monthlyPrice;
  final String yearlyPrice;
  final List<String> features;
  final bool isCurrentPlan;
  final bool isUpgrade;
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
    this.isUpgrade = true,
    this.isRecommended = false,
    this.onPurchase,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _isYearly = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    // Determine price to show in header
    final displayPrice = _isYearly ? widget.yearlyPrice : widget.monthlyPrice;
    final priceSuffix = _isYearly ? l10n.perYear : l10n.perMonth;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isCurrentPlan
              ? widget.accentColor
              : (isDark ? AppColors.neutral800 : AppColors.neutral200),
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
          // Header with title, subtitle, and price
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.heading6.copyWith(color: widget.accentColor),
                          ),
                          if (widget.isRecommended) ...[
                            const Gap(8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.bestValue,
                                style: AppTextStyles.body5.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        widget.subtitle,
                        style: AppTextStyles.body5.copyWith(
                          color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Price (for non-free plans)
                if (widget.title != 'Free')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        displayPrice,
                        style: AppTextStyles.heading5.copyWith(
                          color: widget.accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        priceSuffix,
                        style: AppTextStyles.body5.copyWith(
                          color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                        ),
                      ),
                    ],
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

                const Gap(AppSpacing.spacing12),

                // Monthly/Yearly toggle (only for non-current, non-free plans)
                if (!widget.isCurrentPlan && widget.title != 'Free') ...[
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
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.spacing12),
                ],

                // Action button
                _buildActionButton(context, isDark, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isDark, dynamic l10n) {
    if (widget.isCurrentPlan) {
      // Current plan - show disabled "Your Current Plan" button
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            l10n.yourCurrentPlan,
            style: AppTextStyles.body2.copyWith(
              color: isDark ? AppColors.neutral400 : AppColors.neutral500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Free plan - no purchase button needed (downgrade happens automatically)
    if (widget.title == 'Free') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral700 : AppColors.neutral200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Cancel subscription to switch',
            style: AppTextStyles.body3.copyWith(
              color: isDark ? AppColors.neutral400 : AppColors.neutral500,
            ),
          ),
        ),
      );
    }

    // Other plans - show upgrade/switch button
    final buttonText = widget.isUpgrade
        ? 'Upgrade to ${widget.title}'
        : 'Switch to ${widget.title}';

    return Material(
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
          child: Center(
            child: Text(
              buttonText,
              style: AppTextStyles.body2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
