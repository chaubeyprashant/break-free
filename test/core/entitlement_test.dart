import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/features/subscription/data/billing_products.dart';
import 'package:break_free/features/subscription/data/entitlement_cache.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BillingProducts', () {
    test('weekly, monthly, semiannual, and annual are premium product ids', () {
      expect(BillingProducts.allProductIds, {
        BillingProducts.weekly,
        BillingProducts.monthly,
        BillingProducts.semiannual,
        BillingProducts.annual,
      });
      expect(BillingProducts.orderedProductIds.length, 4);
      expect(BillingProducts.isPremiumProduct(BillingProducts.weekly), isTrue);
      expect(BillingProducts.isPremiumProduct(BillingProducts.semiannual), isTrue);
      expect(BillingProducts.isPremiumProduct('other'), isFalse);
      expect(BillingProducts.isAnnual(BillingProducts.annual), isTrue);
      expect(BillingProducts.titleFor(BillingProducts.semiannual), '6 months');
    });
  });

  group('EntitlementCache', () {
    test('round-trips and enforces offline grace', () async {
      final cache = EntitlementCache();
      await cache.write(
        CachedEntitlement(
          isPremium: true,
          verifiedAt: DateTime.now().subtract(const Duration(days: 1)),
          productId: BillingProducts.monthly,
        ),
      );
      final fresh = await cache.read();
      expect(fresh, isNotNull);
      expect(fresh!.isPremium, isTrue);
      expect(fresh.isWithinGrace, isTrue);

      await cache.write(
        CachedEntitlement(
          isPremium: true,
          verifiedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      );
      final stale = await cache.read();
      expect(stale!.isWithinGrace, isFalse);
    });
  });

  group('Free vs Premium tiers', () {
    test('premium raises freeze/shield caps and habit limit', () {
      expect(FreeTier.maxHabits, 1);
      expect(FreeTier.freezesPerWeek, 1);
      expect(PremiumTiers.freezesPerWeek, greaterThan(FreeTier.freezesPerWeek));
      expect(PremiumTiers.shieldsPerWeek, greaterThan(FreeTier.shieldsPerWeek));
      expect(PremiumFeature.values, isNotEmpty);
    });
  });
}
