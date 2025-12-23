import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:bexly/core/services/subscription/subscription_products.dart';
import 'package:bexly/core/services/subscription/subscription_tier.dart';
import 'package:bexly/core/utils/logger.dart';

/// Service to handle in-app purchases and subscription management
class SubscriptionService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  /// Callback when subscription status changes
  Function(SubscriptionTier)? onSubscriptionChanged;

  /// Current subscription tier
  SubscriptionTier _currentTier = SubscriptionTier.free;
  SubscriptionTier get currentTier => _currentTier;

  /// Available products loaded from store
  List<ProductDetails> get products => _products;

  /// Whether in-app purchase is available
  bool get isAvailable => _isAvailable;

  /// Initialize the subscription service
  Future<void> initialize() async {
    Log.i('Initializing SubscriptionService...', label: 'Subscription');

    // Check if in-app purchase is available
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      Log.w('In-app purchase not available', label: 'Subscription');
      return;
    }

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        Log.e('Purchase stream error: $error', label: 'Subscription');
      },
    );

    // Load products
    await loadProducts();

    // Restore previous purchases
    await restorePurchases();

    Log.i('SubscriptionService initialized', label: 'Subscription');
  }

  /// Load available products from the store with retry
  Future<void> loadProducts({int retryCount = 3}) async {
    if (!_isAvailable) return;

    for (int attempt = 1; attempt <= retryCount; attempt++) {
      try {
        Log.i('Loading products (attempt $attempt/$retryCount)...', label: 'Subscription');

        final response = await _inAppPurchase.queryProductDetails(
          SubscriptionProducts.allProductIds,
        );

        if (response.notFoundIDs.isNotEmpty) {
          Log.w(
            'Products not found: ${response.notFoundIDs}',
            label: 'Subscription',
          );
        }

        _products = response.productDetails;
        Log.i(
          'Loaded ${_products.length} products: ${_products.map((p) => p.id).join(", ")}',
          label: 'Subscription',
        );

        // Success - exit retry loop
        if (_products.isNotEmpty) return;

        // No products found, wait before retry
        if (attempt < retryCount) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        Log.e('Error loading products (attempt $attempt): $e', label: 'Subscription');
        if (attempt < retryCount) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  /// Purchase a subscription product
  Future<bool> purchaseSubscription(ProductDetails product) async {
    if (!_isAvailable) {
      Log.w('In-app purchase not available', label: 'Subscription');
      return false;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final result = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      Log.i(
        'Purchase initiated for ${product.id}: $result',
        label: 'Subscription',
      );
      return result;
    } catch (e) {
      Log.e('Error purchasing: $e', label: 'Subscription');
      return false;
    }
  }

  /// Track if we're in a restore operation
  bool _isRestoring = false;
  SubscriptionTier _restoredTier = SubscriptionTier.free;

  /// Restore previous purchases
  /// This will reset tier to free if no valid purchases are found (e.g., after refund)
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      _isRestoring = true;
      _restoredTier = SubscriptionTier.free;

      await _inAppPurchase.restorePurchases();
      Log.i('Restore purchases initiated', label: 'Subscription');

      // Give time for restore callbacks to complete
      await Future.delayed(const Duration(seconds: 2));

      // After restore completes, update tier to what was actually restored
      // If no valid purchases were restored, _restoredTier stays at free
      if (_currentTier != _restoredTier) {
        Log.i(
          'Subscription changed after restore: ${_currentTier.displayName} -> ${_restoredTier.displayName}',
          label: 'Subscription',
        );
        _currentTier = _restoredTier;
        onSubscriptionChanged?.call(_currentTier);
      }

      _isRestoring = false;
    } catch (e) {
      _isRestoring = false;
      Log.e('Error restoring purchases: $e', label: 'Subscription');
    }
  }

  /// Handle purchase updates from the stream
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      Log.i(
        'Purchase update: ${purchase.productID} - ${purchase.status}',
        label: 'Subscription',
      );

      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Show pending UI
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify and deliver the product
          _verifyAndDeliverProduct(purchase);
          break;

        case PurchaseStatus.error:
          Log.e(
            'Purchase error: ${purchase.error?.message}',
            label: 'Subscription',
          );
          // Complete the purchase to clear from queue
          if (purchase.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          Log.i('Purchase canceled', label: 'Subscription');
          if (purchase.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchase);
          }
          break;
      }
    }
  }

  /// Verify purchase and update subscription tier
  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchase) async {
    // In a production app, you should verify the purchase with your server
    // For now, we trust the local purchase status

    final productId = purchase.productID;

    // Determine the tier based on product ID
    SubscriptionTier newTier = SubscriptionTier.free;
    if (SubscriptionProducts.isProProduct(productId)) {
      newTier = SubscriptionTier.pro;
    } else if (SubscriptionProducts.isPlusProduct(productId)) {
      newTier = SubscriptionTier.plus;
    }

    // If restoring, track the highest tier found
    if (_isRestoring) {
      if (newTier.index > _restoredTier.index) {
        _restoredTier = newTier;
        Log.i('Restored tier: ${_restoredTier.displayName}', label: 'Subscription');
      }
    } else {
      // Normal purchase - update tier immediately if higher
      if (newTier.index > _currentTier.index) {
        _currentTier = newTier;
        onSubscriptionChanged?.call(_currentTier);
        Log.i('Subscription tier updated to: ${_currentTier.displayName}',
            label: 'Subscription');
      }
    }

    // Complete the purchase
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
      Log.i('Purchase completed: ${purchase.productID}', label: 'Subscription');
    }
  }

  /// Get a product by its ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Get formatted price for a product
  String? getFormattedPrice(String productId) {
    final product = getProduct(productId);
    return product?.price;
  }

  /// Clean up resources
  void dispose() {
    _subscription?.cancel();
  }
}
