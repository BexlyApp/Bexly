import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/services/ads/ad_service.dart';
import 'package:bexly/core/utils/logger.dart';

/// A widget that displays a banner ad
/// Only shows for Free tier users (controlled by shouldShowAdsProvider)
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    // Google Mobile Ads SDK is not supported on web
    if (kIsWeb) return;

    final adService = ref.read(adServiceProvider);

    if (!adService.isInitialized) {
      Log.w('AdService not initialized, skipping banner ad load', label: 'BannerAdWidget');
      return;
    }

    _bannerAd = adService.createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
        Log.d('Banner ad loaded successfully', label: 'BannerAdWidget');
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        _bannerAd = null;
        Log.e('Banner ad failed to load: ${error.message}', label: 'BannerAdWidget');
      },
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ads not supported on web
    if (kIsWeb) return const SizedBox.shrink();

    final shouldShowAds = ref.watch(shouldShowAdsProvider);

    // Don't show ads for paid users
    if (!shouldShowAds) {
      return const SizedBox.shrink();
    }

    // Show placeholder while loading
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// A convenient wrapper that adds bottom padding for banner ad
class BannerAdContainer extends ConsumerWidget {
  final Widget child;

  const BannerAdContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ads not supported on web
    if (kIsWeb) return child;

    final shouldShowAds = ref.watch(shouldShowAdsProvider);

    return Column(
      children: [
        Expanded(child: child),
        if (shouldShowAds) const BannerAdWidget(),
      ],
    );
  }
}
