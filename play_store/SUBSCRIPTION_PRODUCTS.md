# Google Play subscription products

Configure these **exact** product IDs in Play Console before Premium prices load in the app.

| Product ID | Billing period | Suggested INR | Suggested USD |
|------------|----------------|---------------|---------------|
| `breakfree_premium_weekly` | 1 week | ₹79 | $2.99 |
| `breakfree_premium_monthly` | 1 month | ₹199 | $6.99 |
| `breakfree_premium_semiannual` | 6 months | ₹799 | $29.99 |
| `breakfree_premium_annual` | 1 year | ₹1,299 | $49.99 |

Defined in code: `lib/features/subscription/data/billing_products.dart`.

## Console checklist

1. Create one subscription (or four) with base plans whose product IDs match the table exactly.
2. Activate products for package `app.breakfree.mobile`.
3. Set prices per country (use the suggested list above as a starting point).
4. Add license testers for sandbox purchases.
5. Publish the app to an **internal/closed testing** track so products resolve.
6. Install from the Play testing link (sideloaded debug builds often cannot see products).

## Manage URL

Users manage billing at: https://play.google.com/store/account/subscriptions
