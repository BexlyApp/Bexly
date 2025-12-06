import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/core/services/subscription/subscription.dart';

/// Ad unit IDs for different platforms
class AdUnitIds {
  // Test Ad Unit IDs (use these during development)
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';

  // Production Ad Unit IDs
  static const String _prodBannerAndroid = 'ca-app-pub-7528798617302619/4566961191';
  static const String _prodBannerIos = 'ca-app-pub-7528798617302619/4566961191'; // Same for now, create iOS-specific later
  static const String _prodInterstitialAndroid = 'ca-app-pub-7528798617302619/4566961191'; // Create interstitial ad unit later
  static const String _prodInterstitialIos = 'ca-app-pub-7528798617302619/4566961191'; // Create interstitial ad unit later
  static const String _prodNativeAndroid = 'ca-app-pub-7528798617302619/4566961191'; // Create native ad unit later
  static const String _prodNativeIos = 'ca-app-pub-7528798617302619/4566961191'; // Create native ad unit later

  /// Get banner ad unit ID based on platform and environment
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testBannerAndroid : _testBannerIos;
    }
    return Platform.isAndroid ? _prodBannerAndroid : _prodBannerIos;
  }

  /// Get interstitial ad unit ID based on platform and environment
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testInterstitialAndroid : _testInterstitialIos;
    }
    return Platform.isAndroid ? _prodInterstitialAndroid : _prodInterstitialIos;
  }

  /// Get native ad unit ID based on platform and environment
  static String get nativeAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testNativeAndroid : _testNativeIos;
    }
    return Platform.isAndroid ? _prodNativeAndroid : _prodNativeIos;
  }
}

/// Service to manage ads
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  static const int _maxInterstitialLoadAttempts = 3;

  /// Initialize the Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      Log.i('AdMob SDK initialized successfully', label: 'AdService');

      // Preload interstitial ad
      _loadInterstitialAd();
    } catch (e) {
      Log.e('Failed to initialize AdMob SDK: $e', label: 'AdService');
    }
  }

  /// Check if ads SDK is initialized
  bool get isInitialized => _isInitialized;

  /// Load banner ad
  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: AdUnitIds.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) => Log.d('Banner ad opened', label: 'AdService'),
        onAdClosed: (ad) => Log.d('Banner ad closed', label: 'AdService'),
      ),
    );
  }

  /// Load interstitial ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          Log.i('Interstitial ad loaded', label: 'AdService');
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          Log.e('Interstitial ad failed to load: ${error.message}', label: 'AdService');

          if (_interstitialLoadAttempts < _maxInterstitialLoadAttempts) {
            _loadInterstitialAd();
          }
        },
      ),
    );
  }

  /// Show interstitial ad
  Future<void> showInterstitialAd({VoidCallback? onAdDismissed}) async {
    if (_interstitialAd == null) {
      Log.w('Interstitial ad not ready', label: 'AdService');
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Preload next ad
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        Log.e('Interstitial ad failed to show: ${error.message}', label: 'AdService');
        onAdDismissed?.call();
      },
    );

    await _interstitialAd!.show();
  }

  /// Check if interstitial ad is ready
  bool get isInterstitialReady => _interstitialAd != null;

  /// Dispose all ads
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

/// Provider for AdService
final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

/// Provider to check if ads should be shown (based on subscription)
final shouldShowAdsProvider = Provider<bool>((ref) {
  final limits = ref.watch(subscriptionLimitsProvider);
  return limits.showAds;
});
