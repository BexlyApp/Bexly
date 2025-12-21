import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:bexly/core/services/subscription/subscription_service.dart';
import 'package:bexly/core/services/subscription/subscription_tier.dart';

/// Provider for the SubscriptionService singleton
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// State class for subscription
class SubscriptionState {
  final SubscriptionTier tier;
  final bool isLoading;
  final List<ProductDetails> products;
  final String? error;

  const SubscriptionState({
    this.tier = SubscriptionTier.free,
    this.isLoading = false,
    this.products = const [],
    this.error,
  });

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isLoading,
    List<ProductDetails>? products,
    String? error,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      error: error,
    );
  }

  /// Get limits for current tier
  SubscriptionLimits get limits => SubscriptionLimits(tier);

  /// Check if user has plus or higher
  bool get isPlusOrHigher => tier.hasAccess(SubscriptionTier.plus);

  /// Check if user has pro
  bool get isPro => tier == SubscriptionTier.pro;

  /// Check if user is on free tier
  bool get isFree => tier == SubscriptionTier.free;
}

/// Notifier for subscription state
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  late final SubscriptionService _service;

  @override
  SubscriptionState build() {
    _service = ref.watch(subscriptionServiceProvider);
    // Use Future.microtask to avoid accessing state before build() returns
    Future.microtask(() => _initialize());
    return const SubscriptionState(isLoading: true);
  }

  Future<void> _initialize() async {

    // Set callback for subscription changes
    _service.onSubscriptionChanged = (tier) {
      state = state.copyWith(tier: tier);
    };

    await _service.initialize();

    state = state.copyWith(
      isLoading: false,
      tier: _service.currentTier,
      products: _service.products,
    );
  }

  /// Purchase a subscription
  Future<bool> purchase(String productId) async {
    var product = _service.getProduct(productId);

    // If product not found, try reloading products
    if (product == null) {
      state = state.copyWith(isLoading: true, error: null);
      await _service.loadProducts();
      state = state.copyWith(products: _service.products);
      product = _service.getProduct(productId);
    }

    if (product == null) {
      state = state.copyWith(isLoading: false, error: 'Product not found. Please check your internet connection and try again.');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    final success = await _service.purchaseSubscription(product);
    state = state.copyWith(isLoading: false);

    return success;
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);
    await _service.restorePurchases();
    state = state.copyWith(isLoading: false);
  }

  /// Get formatted price for a product
  String? getPrice(String productId) {
    return _service.getFormattedPrice(productId);
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for subscription state
final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);

/// Provider for current subscription tier (convenience)
final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  return ref.watch(subscriptionProvider).tier;
});

/// Provider for subscription limits (convenience)
final subscriptionLimitsProvider = Provider<SubscriptionLimits>((ref) {
  return ref.watch(subscriptionProvider).limits;
});

/// Provider to check if a specific feature is available
final featureAvailableProvider =
    Provider.family<bool, SubscriptionTier>((ref, requiredTier) {
  final currentTier = ref.watch(subscriptionTierProvider);
  return currentTier.hasAccess(requiredTier);
});
