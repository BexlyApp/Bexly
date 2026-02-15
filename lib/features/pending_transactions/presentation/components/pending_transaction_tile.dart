import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_radius.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/database/database_provider.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/extensions/double_extension.dart';
import 'package:bexly/core/extensions/string_extension.dart';
import 'package:bexly/core/extensions/text_style_extensions.dart';
import 'package:bexly/features/category/data/model/icon_type.dart';
import 'package:bexly/features/category_picker/presentation/components/category_icon.dart';
import 'package:bexly/features/currency_picker/data/models/currency.dart';
import 'package:bexly/features/currency_picker/presentation/riverpod/currency_picker_provider.dart';
import 'package:bexly/features/pending_transactions/data/models/pending_transaction_model.dart';

/// Tile widget for displaying a pending transaction
/// Design matches TransactionTile from the transaction list
class PendingTransactionTile extends HookConsumerWidget {
  final PendingTransactionModel pending;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const PendingTransactionTile({
    super.key,
    required this.pending,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = pending.isIncome;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get currency info
    final currencies = ref.watch(currenciesStaticProvider);
    final currencyData = currencies.fromIsoCode(pending.currency);
    final currencySymbol = currencyData?.symbol ?? pending.currency;

    // Get display texts - handle garbage merchant names from parser
    final rawTitle = pending.merchant ?? pending.title;
    // If merchant is too short or looks like garbage, use bank name + transaction type
    final displayTitle = (rawTitle.length <= 4 || !_isValidMerchantName(rawTitle))
        ? '${pending.sourceDisplayName} ${pending.isIncome ? 'Credit' : 'Debit'}'
        : _cleanMerchantName(rawTitle);
    final displaySubtitle = pending.categoryHint ?? pending.sourceDisplayName;

    // Watch for matching category
    final db = ref.watch(databaseProvider);
    final matchedCategory = useState<Category?>(null);

    // Match category from categoryHint
    useEffect(() {
      final subscription = db.categoryDao.watchAllCategories().listen((categories) {
        final matched = _findMatchingCategory(categories, pending);
        matchedCategory.value = matched;
      });
      return subscription.cancel;
    }, [pending.id]);

    return Dismissible(
      key: Key('pending_${pending.id}'),
      background: _buildSwipeBackground(
        context,
        isApprove: true,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        isApprove: false,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onApprove?.call();
        } else {
          onReject?.call();
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutralAlpha25 : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppRadius.radius12),
          border: Border.all(
            color: isDark ? AppColors.neutralAlpha25 : AppColors.neutralAlpha10,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main transaction row - EXACTLY like TransactionTile
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.radius12),
                topRight: Radius.circular(AppRadius.radius12),
              ),
              child: Container(
                height: 70,
                padding: const EdgeInsets.only(right: AppSpacing.spacing12),
                child: Row(
                  children: [
                    // Icon section (70x70) - same as TransactionTile
                    Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(AppSpacing.spacing12),
                      decoration: BoxDecoration(
                        color: isIncome
                            ? context.incomeBackground
                            : context.expenseBackground,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.radius12 - 1),
                        ),
                      ),
                      child: matchedCategory.value != null
                          ? CategoryIcon(
                              iconType: _getIconType(matchedCategory.value!.iconType),
                              icon: matchedCategory.value!.icon ?? '',
                              iconBackground: matchedCategory.value!.iconBackground ?? '',
                            )
                          : CategoryIcon(
                              iconType: IconType.initial,
                              icon: displayTitle.isNotEmpty
                                  ? displayTitle[0].toUpperCase()
                                  : '?',
                              iconBackground: '',
                            ),
                    ),
                    const Gap(AppSpacing.spacing12),
                    // Content section - same as TransactionTile
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title + Category
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  displayTitle,
                                  style: AppTextStyles.body3.bold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Gap(AppSpacing.spacing2),
                                AutoSizeText(
                                  displaySubtitle,
                                  style: AppTextStyles.body4,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Source tag + Amount
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Source tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getSourceColor(pending.source).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  pending.source.displayName,
                                  style: AppTextStyles.body5.copyWith(
                                    color: _getSourceColor(pending.source),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const Gap(AppSpacing.spacing4),
                              Text(
                                formatAmountWithCurrency(
                                  amount: isIncome ? pending.amount : -pending.amount,
                                  symbol: currencySymbol,
                                  isoCode: pending.currency,
                                  decimalDigits: currencyData?.decimalDigits ?? 0,
                                  showSign: true,
                                ),
                                style: AppTextStyles.numericMedium.copyWith(
                                  color: isIncome
                                      ? AppColors.green200
                                      : AppColors.red700,
                                  height: 1.12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.neutralAlpha25 : AppColors.neutralAlpha10,
            ),
            // Action buttons row
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing12),
              child: Row(
                children: [
                  // Reject button - use theme outlined style
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Colors.transparent,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radius8),
                        ),
                      ),
                      child: Text(context.l10n.reject),
                    ),
                  ),
                  const Gap(AppSpacing.spacing8),
                  // Approve button - use theme filled style
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.radius8),
                        ),
                      ),
                      child: Text(context.l10n.approve),
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

  /// Clean up raw merchant names from email/SMS/notification
  /// - Remove payment gateway prefixes (.OP*, TT*, VNP*, etc.)
  /// - Convert ALL CAPS to Title Case
  /// - Trim trailing whitespace
  static String _cleanMerchantName(String name) {
    var cleaned = name.trim();

    // Remove common payment gateway prefixes
    final prefixPattern = RegExp(r'^[.\s]*(OP\*|TT\*|VNP\*|VNPAY\*|PP\*|SQ\*|SP\*|GG\*|MOMO\*)', caseSensitive: false);
    cleaned = cleaned.replaceFirst(prefixPattern, '');
    cleaned = cleaned.trim();

    // Convert ALL CAPS to Title Case (if most chars are uppercase)
    final upperCount = cleaned.runes.where((r) => String.fromCharCode(r).toUpperCase() == String.fromCharCode(r) && String.fromCharCode(r).toLowerCase() != String.fromCharCode(r)).length;
    final letterCount = cleaned.runes.where((r) => String.fromCharCode(r).toUpperCase() != String.fromCharCode(r) || String.fromCharCode(r).toLowerCase() != String.fromCharCode(r)).length;

    if (letterCount > 0 && upperCount / letterCount > 0.7) {
      cleaned = cleaned.split(RegExp(r'[\s\-_.]+')).map((word) {
        if (word.isEmpty) return word;
        // Keep short acronyms (AI, SM, etc.) uppercase
        if (word.length <= 3 && word == word.toUpperCase()) return word;
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }).join(' ');
    }

    return cleaned;
  }

  /// Check if merchant name looks valid (not garbage from parser)
  static bool _isValidMerchantName(String name) {
    // Names that are all lowercase single words are likely garbage
    if (name == name.toLowerCase() && !name.contains(' ')) {
      return false;
    }
    // Names with only numbers or special chars are garbage
    if (RegExp(r'^[\d\s\-_]+$').hasMatch(name)) {
      return false;
    }
    return true;
  }

  /// Find matching category from categoryHint
  static Category? _findMatchingCategory(
    List<Category> categories,
    PendingTransactionModel pending,
  ) {
    // If already has selectedCategoryId, find that category
    if (pending.selectedCategoryId != null) {
      return categories.firstWhereOrNull((c) => c.id == pending.selectedCategoryId);
    }

    // Try to match by categoryHint
    if (pending.categoryHint == null || pending.categoryHint!.isEmpty) {
      return null;
    }

    final hint = pending.categoryHint!.toLowerCase();

    // First try exact match (case-insensitive)
    for (final category in categories) {
      if (category.title.toLowerCase() == hint) {
        return category;
      }
    }

    // Then try contains match
    for (final category in categories) {
      if (category.title.toLowerCase().contains(hint) ||
          hint.contains(category.title.toLowerCase())) {
        return category;
      }
    }

    return null;
  }

  /// Convert iconTypeValue string to IconType enum
  static IconType _getIconType(String? iconTypeValue) {
    switch (iconTypeValue) {
      case 'emoji':
        return IconType.emoji;
      case 'initial':
        return IconType.initial;
      case 'asset':
        return IconType.asset;
      default:
        return IconType.asset;
    }
  }

  /// Get color for source tag
  Color _getSourceColor(PendingTxSource source) {
    switch (source) {
      case PendingTxSource.email:
        return AppColors.primary600; // Teal for email
      case PendingTxSource.sms:
        return AppColors.green200; // Green for SMS
      case PendingTxSource.notification:
        return AppColors.tertiary600; // Yellow/gold for notification
      case PendingTxSource.bank:
        return AppColors.purple500; // Purple for bank
    }
  }

  Widget _buildSwipeBackground(
    BuildContext context, {
    required bool isApprove,
    required Alignment alignment,
  }) {
    final color = isApprove ? AppColors.green200 : AppColors.red600;
    final label = isApprove ? context.l10n.approve : context.l10n.reject;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.radius12),
      ),
      child: Text(
        label,
        style: AppTextStyles.body3.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
