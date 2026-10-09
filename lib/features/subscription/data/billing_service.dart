import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:break_free/features/subscription/data/billing_products.dart';

/// Thin wrapper around Google Play Billing via `in_app_purchase`.
/// UI and entitlement logic stay outside this class.
class BillingService {
  BillingService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isAvailableSync => _available;
  bool _available = false;

  final _purchaseController = StreamController<List<PurchaseDetails>>.broadcast();
  Stream<List<PurchaseDetails>> get purchaseUpdates => _purchaseController.stream;

  Future<bool> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) return false;
    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _purchaseController.add,
      onError: (Object e, StackTrace st) {
        debugPrint('Billing purchaseStream error: $e\n$st');
        _purchaseController.addError(e, st);
      },
    );
    return true;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _purchaseController.close();
  }

  Future<ProductDetailsResponse> queryProducts() {
    return _iap.queryProductDetails(BillingProducts.allProductIds);
  }

  Future<bool> buy(ProductDetails product, {PurchaseDetails? oldSubscription}) async {
    late final PurchaseParam param;
    if (Platform.isAndroid) {
      param = GooglePlayPurchaseParam(
        productDetails: product,
        changeSubscriptionParam: oldSubscription is GooglePlayPurchaseDetails
            ? ChangeSubscriptionParam(
                oldPurchaseDetails: oldSubscription,
                replacementMode: ReplacementMode.withTimeProration,
              )
            : null,
      );
    } else {
      param = PurchaseParam(productDetails: product);
    }
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Active subscription purchases owned by this Play account on Android.
  Future<List<PurchaseDetails>> queryOwnedSubscriptions() async {
    if (!_available) return const [];
    if (Platform.isAndroid) {
      final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        debugPrint('queryPastPurchases error: ${response.error}');
      }
      return response.pastPurchases
          .where((p) => BillingProducts.isPremiumProduct(p.productID))
          .where(_isActivePurchase)
          .toList();
    }
    // iOS path reserved for later — restorePurchases feeds purchaseStream.
    return const [];
  }

  bool _isActivePurchase(PurchaseDetails purchase) {
    if (purchase.status != PurchaseStatus.purchased && purchase.status != PurchaseStatus.restored) {
      return false;
    }
    if (Platform.isAndroid && purchase is GooglePlayPurchaseDetails) {
      final billing = purchase.billingClientPurchase;
      // 1 = purchased; still treat as active during Play grace when owned.
      return billing.purchaseState == PurchaseStateWrapper.purchased;
    }
    return true;
  }

  /// Whether this purchase grants Premium (client-side ownership check).
  /// Pending purchases do **not** unlock Premium until Play confirms purchase.
  bool grantsPremium(PurchaseDetails purchase) {
    if (!BillingProducts.isPremiumProduct(purchase.productID)) return false;
    return _isActivePurchase(purchase);
  }
}
