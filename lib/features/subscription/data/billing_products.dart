/// Single source of truth for Google Play subscription product IDs.
///
/// Create matching subscriptions (or base plans) in Play Console before
/// purchases will load prices. IDs must match exactly.
///
/// Suggested INR launch prices (set in Play Console, not in code):
/// - weekly ₹79 · monthly ₹199 · 6 months ₹799 · yearly ₹1,299
class BillingProducts {
  BillingProducts._();

  /// Logical entitlement shared by all paid plans.
  static const String premiumEntitlement = 'premium';

  static const String weekly = 'breakfree_premium_weekly';
  static const String monthly = 'breakfree_premium_monthly';
  static const String semiannual = 'breakfree_premium_semiannual';
  static const String annual = 'breakfree_premium_annual';

  /// Display order on the Premium screen (impulse → best value).
  static const List<String> orderedProductIds = [
    weekly,
    monthly,
    semiannual,
    annual,
  ];

  static const Set<String> allProductIds = {
    weekly,
    monthly,
    semiannual,
    annual,
  };

  static bool isPremiumProduct(String productId) => allProductIds.contains(productId);

  static bool isWeekly(String productId) => productId == weekly;
  static bool isMonthly(String productId) => productId == monthly;
  static bool isSemiannual(String productId) => productId == semiannual;
  static bool isAnnual(String productId) => productId == annual;

  static String titleFor(String productId) => switch (productId) {
        weekly => 'Weekly',
        monthly => 'Monthly',
        semiannual => '6 months',
        annual => 'Yearly',
        _ => 'Premium',
      };

  /// Short marketing hint when Play has not returned a price yet.
  static String fallbackPriceHint(String productId) => switch (productId) {
        weekly => '≈ ₹79 / week',
        monthly => '≈ ₹199 / month',
        semiannual => '≈ ₹799 / 6 months',
        annual => '≈ ₹1,299 / year',
        _ => 'Price from Google Play',
      };
}
