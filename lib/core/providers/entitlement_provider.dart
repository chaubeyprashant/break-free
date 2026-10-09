import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:break_free/features/subscription/data/billing_products.dart';
import 'package:break_free/features/subscription/data/billing_service.dart';
import 'package:break_free/features/subscription/data/entitlement_cache.dart';
import 'package:break_free/features/subscription/domain/entitlement.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';

/// Single authoritative answer to: is the current user Premium?
///
/// Store ownership is the source of truth. SharedPreferences is only a short
/// offline grace cache after a successful verify — never a permanent unlock.
class EntitlementProvider extends ChangeNotifier {
  EntitlementProvider({
    BillingService? billing,
    EntitlementCache? cache,
    Connectivity? connectivity,
  })  : _billing = billing ?? BillingService(),
        _cache = cache ?? EntitlementCache(),
        _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  final BillingService _billing;
  final EntitlementCache _cache;
  final Connectivity _connectivity;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Entitlement _entitlement = Entitlement.free;
  PurchaseFlowStatus _flow = PurchaseFlowStatus.idle;
  String? _flowMessage;
  List<ProductDetails> _products = const [];
  String? _selectedProductId;
  bool _initialized = false;
  bool _storeAvailable = false;
  PurchaseDetails? _activePurchase;

  Entitlement get entitlement => _entitlement;
  bool get isPremium => _entitlement.isPremium;
  PurchaseFlowStatus get flowStatus => _flow;
  String? get flowMessage => _flowMessage;
  List<ProductDetails> get products => List.unmodifiable(_products);
  String? get selectedProductId => _selectedProductId;
  bool get isInitialized => _initialized;
  bool get storeAvailable => _storeAvailable;
  PurchaseDetails? get activePurchase => _activePurchase;

  ProductDetails? get weeklyProduct => _find(BillingProducts.weekly);
  ProductDetails? get monthlyProduct => _find(BillingProducts.monthly);
  ProductDetails? get semiannualProduct => _find(BillingProducts.semiannual);
  ProductDetails? get annualProduct => _find(BillingProducts.annual);
  ProductDetails? get selectedProduct =>
      _selectedProductId == null ? null : _find(_selectedProductId!);

  /// Plans returned by Play, in marketing order (missing IDs omitted).
  List<ProductDetails> get orderedProducts {
    final list = <ProductDetails>[];
    for (final id in BillingProducts.orderedProductIds) {
      final p = _find(id);
      if (p != null) list.add(p);
    }
    return list;
  }

  ProductDetails? _find(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool hasFeature(PremiumFeature feature) => isPremium;

  int get freezesPerWeek => isPremium ? PremiumTiers.freezesPerWeek : FreeTier.freezesPerWeek;
  int get shieldsPerWeek => isPremium ? PremiumTiers.shieldsPerWeek : FreeTier.shieldsPerWeek;
  int get maxHabits => isPremium ? 999 : FreeTier.maxHabits;

  Future<void> _init() async {
    _setFlow(PurchaseFlowStatus.loadingProducts);
    try {
      _storeAvailable = await _billing.initialize();
      _purchaseSub = _billing.purchaseUpdates.listen(
        _onPurchaseUpdates,
        onError: (Object e) {
          debugPrint('Entitlement purchase updates error: $e');
          _setFlow(PurchaseFlowStatus.failed, message: 'Could not listen for purchases.');
        },
      );

      if (!_storeAvailable) {
        await _applyOfflineOrFree(storeUnavailable: true);
        _initialized = true;
        notifyListeners();
        return;
      }

      await loadProducts();
      await refreshEntitlement(userInitiated: false);
      _selectedProductId ??=
          annualProduct?.id ?? semiannualProduct?.id ?? monthlyProduct?.id ?? weeklyProduct?.id ?? BillingProducts.annual;
    } catch (e) {
      debugPrint('Entitlement init failed: $e');
      await _applyOfflineOrFree();
      _setFlow(PurchaseFlowStatus.failed, message: 'Could not start billing.');
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> _isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty) return false;
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true; // fail open to store query
    }
  }

  Future<void> loadProducts() async {
    if (!_storeAvailable) {
      _setFlow(PurchaseFlowStatus.storeUnavailable, message: 'Store is unavailable on this device.');
      return;
    }
    _setFlow(PurchaseFlowStatus.loadingProducts);
    final response = await _billing.queryProducts();
    if (response.error != null) {
      _products = const [];
      _setFlow(PurchaseFlowStatus.failed, message: response.error!.message);
      notifyListeners();
      return;
    }
    _products = response.productDetails;
    if (_products.isEmpty) {
      _setFlow(
        PurchaseFlowStatus.failed,
        message: 'Subscription products are not available yet. Configure them in Google Play Console.',
      );
    } else {
      _selectedProductId ??=
          annualProduct?.id ?? semiannualProduct?.id ?? monthlyProduct?.id ?? weeklyProduct?.id;
      _setFlow(PurchaseFlowStatus.ready);
    }
    notifyListeners();
  }

  void selectPlan(String productId) {
    if (!BillingProducts.isPremiumProduct(productId)) return;
    _selectedProductId = productId;
    notifyListeners();
  }

  /// Re-query ownership from the store (or apply offline grace).
  Future<void> refreshEntitlement({bool userInitiated = true}) async {
    if (userInitiated) _setFlow(PurchaseFlowStatus.restoring, message: 'Checking your purchases…');

    final online = await _isOnline();
    if (!online) {
      await _applyOfflineOrFree();
      if (userInitiated) {
        _setFlow(
          PurchaseFlowStatus.offline,
          message: "You're offline. Connect to the internet to verify your subscription.",
        );
      }
      notifyListeners();
      return;
    }

    if (!_storeAvailable) {
      await _applyOfflineOrFree(storeUnavailable: true);
      notifyListeners();
      return;
    }

    try {
      final owned = await _billing.queryOwnedSubscriptions();
      final active = owned.cast<PurchaseDetails?>().firstWhere(
            (p) => p != null && _billing.grantsPremium(p) && p.status != PurchaseStatus.pending,
            orElse: () => null,
          );
      if (active != null) {
        await _grantFromStore(active);
        if (userInitiated) _setFlow(PurchaseFlowStatus.success, message: 'Premium unlocked');
      } else {
        await _revokeToFree(verifiedOnline: true);
        if (userInitiated) {
          _setFlow(PurchaseFlowStatus.ready, message: 'No active Premium subscription found.');
        } else if (_flow == PurchaseFlowStatus.restoring || _flow == PurchaseFlowStatus.loadingProducts) {
          _setFlow(PurchaseFlowStatus.ready);
        }
      }
    } catch (e) {
      debugPrint('refreshEntitlement failed: $e');
      await _applyOfflineOrFree();
      if (userInitiated) {
        _setFlow(PurchaseFlowStatus.failed, message: 'Could not verify subscription.');
      }
    }
    notifyListeners();
  }

  Future<void> purchaseSelected() async {
    final product = selectedProduct;
    if (product == null) {
      _setFlow(PurchaseFlowStatus.failed, message: 'Select a plan first.');
      notifyListeners();
      return;
    }
    if (!await _isOnline()) {
      _setFlow(
        PurchaseFlowStatus.offline,
        message: "You're offline. Connect to the internet to verify your subscription.",
      );
      notifyListeners();
      return;
    }
    _setFlow(PurchaseFlowStatus.purchasing, message: 'Continue to Google Play');
    notifyListeners();
    try {
      _setFlow(PurchaseFlowStatus.processing, message: 'Processing…');
      notifyListeners();
      final started = await _billing.buy(product, oldSubscription: _activePurchase);
      if (!started) {
        _setFlow(PurchaseFlowStatus.failed, message: 'Purchase could not be completed');
        notifyListeners();
      }
      // Final status arrives via purchaseStream.
    } catch (e) {
      debugPrint('purchaseSelected error: $e');
      _setFlow(PurchaseFlowStatus.failed, message: 'Purchase could not be completed');
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!await _isOnline()) {
      _setFlow(
        PurchaseFlowStatus.offline,
        message: "You're offline. Connect to the internet to verify your subscription.",
      );
      notifyListeners();
      return;
    }
    _setFlow(PurchaseFlowStatus.restoring, message: 'Checking your purchases…');
    notifyListeners();
    try {
      await _billing.restore();
      // Also query Android past purchases / refresh.
      await refreshEntitlement(userInitiated: true);
    } catch (e) {
      debugPrint('restorePurchases error: $e');
      _setFlow(PurchaseFlowStatus.failed, message: 'Could not restore purchases.');
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _setFlow(PurchaseFlowStatus.pending, message: 'Purchase pending');
          notifyListeners();
        case PurchaseStatus.error:
          _setFlow(
            PurchaseFlowStatus.failed,
            message: purchase.error?.message ?? 'Purchase could not be completed',
          );
          notifyListeners();
          await _billing.complete(purchase);
        case PurchaseStatus.canceled:
          _setFlow(PurchaseFlowStatus.cancelled, message: 'Purchase cancelled');
          notifyListeners();
          await _billing.complete(purchase);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (BillingProducts.isPremiumProduct(purchase.productID) &&
              purchase.status != PurchaseStatus.pending) {
            // Ownership is confirmed by store delivery; complete acknowledgment.
            await _billing.complete(purchase);
            await _grantFromStore(purchase);
            _setFlow(PurchaseFlowStatus.success, message: 'Premium unlocked');
            notifyListeners();
          } else {
            await _billing.complete(purchase);
          }
      }
    }
  }

  Future<void> _grantFromStore(PurchaseDetails purchase) async {
    _activePurchase = purchase;
    _entitlement = Entitlement(
      isPremium: true,
      source: EntitlementSource.store,
      activeProductId: purchase.productID,
      verifiedAt: DateTime.now(),
    );
    await _cache.write(
      CachedEntitlement(
        isPremium: true,
        verifiedAt: DateTime.now(),
        productId: purchase.productID,
      ),
    );
  }

  Future<void> _revokeToFree({required bool verifiedOnline}) async {
    _activePurchase = null;
    _entitlement = Entitlement.free;
    if (verifiedOnline) {
      await _cache.write(
        CachedEntitlement(isPremium: false, verifiedAt: DateTime.now()),
      );
    }
  }

  Future<void> _applyOfflineOrFree({bool storeUnavailable = false}) async {
    final cached = await _cache.read();
    if (cached != null && cached.isPremium && cached.isWithinGrace) {
      _entitlement = Entitlement(
        isPremium: true,
        source: EntitlementSource.offlineCache,
        activeProductId: cached.productId,
        verifiedAt: cached.verifiedAt,
        message: storeUnavailable
            ? 'Using cached Premium until the store is available.'
            : "You're offline. Premium remains active until we can re-verify.",
      );
      if (storeUnavailable) {
        _setFlow(PurchaseFlowStatus.storeUnavailable, message: _entitlement.message);
      } else {
        _setFlow(PurchaseFlowStatus.offline, message: _entitlement.message);
      }
      return;
    }
    _entitlement = Entitlement.free;
    if (storeUnavailable) {
      _setFlow(PurchaseFlowStatus.storeUnavailable, message: 'Store is unavailable on this device.');
    }
  }

  void _setFlow(PurchaseFlowStatus status, {String? message}) {
    _flow = status;
    _flowMessage = message;
  }

  /// Clear flow banner after the user dismisses success/error UI.
  void acknowledgeFlow() {
    if (_flow == PurchaseFlowStatus.success ||
        _flow == PurchaseFlowStatus.cancelled ||
        _flow == PurchaseFlowStatus.failed ||
        _flow == PurchaseFlowStatus.pending) {
      _flowMessage = null;
      _setFlow(PurchaseFlowStatus.ready);
      notifyListeners();
    }
  }

  /// Sign-out does not delete Play ownership. Local coaching data stays.
  /// Re-verify on next launch / restore.
  Future<void> onSignedOut() async {
    // Keep cache so reinstall/re-login can still use offline grace briefly;
    // ownership is always re-checked when online.
    _activePurchase = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    unawaited(_billing.dispose());
    super.dispose();
  }
}
