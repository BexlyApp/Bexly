import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';
import 'package:bexly/core/services/ads/ad_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// A widget that displays a native advanced ad using NativeAdOptions
/// Only shows for Free tier users (controlled by shouldShowAdsProvider)
class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adService = ref.read(adServiceProvider);

    if (!adService.isInitialized) {
      Log.w('AdService not initialized, skipping native ad load', label: 'NativeAdWidget');
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: AdUnitIds.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
          Log.d('Native ad loaded successfully', label: 'NativeAdWidget');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _nativeAd = null;
          Log.e('Native ad failed to load: ${error.message}', label: 'NativeAdWidget');
        },
        onAdOpened: (ad) => Log.d('Native ad opened', label: 'NativeAdWidget'),
        onAdClosed: (ad) => Log.d('Native ad closed', label: 'NativeAdWidget'),
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.transparent,
        cornerRadius: 12,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.primary500,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.neutral800,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.neutral600,
          style: NativeTemplateFontStyle.normal,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: AppColors.neutral500,
          style: NativeTemplateFontStyle.normal,
          size: 11,
        ),
      ),
    );

    _nativeAd?.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowAds = ref.watch(shouldShowAdsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Don't show ads for paid users
    if (!shouldShowAds) {
      return const SizedBox.shrink();
    }

    // Show placeholder while loading
    if (!_isAdLoaded || _nativeAd == null) {
      return Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: AppSpacing.spacing16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral900 : AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Ad',
              style: AppTextStyles.body5.copyWith(
                color: AppColors.neutral400,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral900 : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
