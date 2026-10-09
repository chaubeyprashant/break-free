import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/subscription/data/billing_products.dart';
import 'package:break_free/features/subscription/domain/entitlement.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final e = context.read<EntitlementProvider>();
      if (e.products.isEmpty && e.storeAvailable) {
        e.loadProducts();
      }
    });
  }

  Future<void> _openManageSubscriptions() async {
    final uri = Uri.parse('https://play.google.com/store/account/subscriptions');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=app.breakfree.mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _ctaLabel(EntitlementProvider e) {
    return switch (e.flowStatus) {
      PurchaseFlowStatus.purchasing || PurchaseFlowStatus.processing => 'Processing…',
      PurchaseFlowStatus.restoring => 'Checking your purchases…',
      PurchaseFlowStatus.pending => 'Purchase pending',
      _ when e.isPremium => 'You have Premium',
      _ => 'Continue to Google Play',
    };
  }

  bool _ctaEnabled(EntitlementProvider e) {
    if (e.isPremium) return false;
    if (e.selectedProduct == null) return false;
    return switch (e.flowStatus) {
      PurchaseFlowStatus.purchasing ||
      PurchaseFlowStatus.processing ||
      PurchaseFlowStatus.restoring ||
      PurchaseFlowStatus.pending =>
        false,
      _ => true,
    };
  }

  String? _badgeFor(String productId, EntitlementProvider e) {
    if (BillingProducts.isAnnual(productId)) {
      return _savingsVsMonthly(e.monthlyProduct, e.annualProduct, months: 12) ?? 'Best value';
    }
    if (BillingProducts.isSemiannual(productId)) {
      return _savingsVsMonthly(e.monthlyProduct, e.semiannualProduct, months: 6);
    }
    return null;
  }

  String? _savingsVsMonthly(ProductDetails? monthly, ProductDetails? plan, {required int months}) {
    if (monthly == null || plan == null) return null;
    final m = monthly.rawPrice;
    final p = plan.rawPrice;
    if (m <= 0 || p <= 0) return null;
    final full = m * months;
    if (full <= p) return null;
    final pct = (((full - p) / full) * 100).round();
    if (pct <= 0) return null;
    return 'Save $pct%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Break Free Premium')),
      body: Consumer<EntitlementProvider>(
        builder: (context, entitlement, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              BfSpacing.screenH,
              BfSpacing.sm,
              BfSpacing.screenH,
              BfSpacing.huge,
            ),
            children: [
              Text(
                'Break Free Premium',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BfSpacing.xs),
              Text(
                'More control.\nMore protection.\nDeeper insights.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (entitlement.isPremium) ...[
                const SizedBox(height: BfSpacing.md),
                BfSurface(
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: BfColors.accent, size: 22),
                      const SizedBox(width: BfSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Premium unlocked', style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              BillingProducts.titleFor(
                                entitlement.entitlement.activeProductId ?? BillingProducts.annual,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (entitlement.flowMessage != null) ...[
                const SizedBox(height: BfSpacing.sm),
                _StatusBanner(
                  status: entitlement.flowStatus,
                  message: entitlement.flowMessage!,
                  onDismiss: entitlement.acknowledgeFlow,
                ),
              ],
              const SizedBox(height: BfSpacing.lg),
              const BfSectionLabel('Plans'),
              const SizedBox(height: BfSpacing.xs),
              if (entitlement.flowStatus == PurchaseFlowStatus.loadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: BfSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                for (final id in BillingProducts.orderedProductIds) ...[
                  _PlanCard(
                    title: BillingProducts.titleFor(id),
                    product: switch (id) {
                      BillingProducts.weekly => entitlement.weeklyProduct,
                      BillingProducts.monthly => entitlement.monthlyProduct,
                      BillingProducts.semiannual => entitlement.semiannualProduct,
                      _ => entitlement.annualProduct,
                    },
                    selected: entitlement.selectedProductId == id,
                    fallbackId: id,
                    fallbackHint: BillingProducts.fallbackPriceHint(id),
                    badge: _badgeFor(id, entitlement),
                    onTap: () => entitlement.selectPlan(id),
                  ),
                  const SizedBox(height: BfSpacing.sm),
                ],
              ],
              const SizedBox(height: BfSpacing.md),
              BfPrimaryButton(
                label: _ctaLabel(entitlement),
                onPressed: _ctaEnabled(entitlement) ? entitlement.purchaseSelected : null,
              ),
              const SizedBox(height: BfSpacing.xs),
              BfSecondaryButton(
                label: 'Restore purchases',
                onPressed: entitlement.flowStatus == PurchaseFlowStatus.restoring
                    ? null
                    : entitlement.restorePurchases,
              ),
              const SizedBox(height: BfSpacing.sectionGap),
              const BfSectionLabel('Free vs Premium'),
              const SizedBox(height: BfSpacing.xs),
              const _CompareTable(),
              const SizedBox(height: BfSpacing.sectionGap),
              const BfSectionLabel('Subscription info'),
              const SizedBox(height: BfSpacing.xs),
              Text(
                'Subscriptions renew automatically through Google Play until you cancel. '
                'Prices shown are from Google Play for your account and region. '
                'Suggested list prices (INR): Weekly ₹79 · Monthly ₹199 · 6 months ₹799 · Yearly ₹1,299.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: BfSpacing.sm),
              Wrap(
                spacing: BfSpacing.xs,
                children: [
                  TextButton(onPressed: _openManageSubscriptions, child: const Text('Manage subscription')),
                  TextButton(onPressed: _openPrivacy, child: const Text('Privacy')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.message, required this.onDismiss});
  final PurchaseFlowStatus status;
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PurchaseFlowStatus.success => BfColors.success,
      PurchaseFlowStatus.failed || PurchaseFlowStatus.cancelled => BfColors.danger,
      PurchaseFlowStatus.offline || PurchaseFlowStatus.pending => BfColors.warning,
      _ => BfColors.accent,
    };
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(BfRadius.md),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: BfSpacing.md),
        title: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: IconButton(icon: const Icon(Icons.close, size: 20), onPressed: onDismiss),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.product,
    required this.selected,
    required this.fallbackId,
    required this.fallbackHint,
    required this.onTap,
    this.badge,
  });

  final String title;
  final ProductDetails? product;
  final bool selected;
  final String fallbackId;
  final String fallbackHint;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final price = product?.price;
    return Material(
      color: selected
          ? BfColors.accentSoft
          : (dark ? BfColors.inkElevated : BfColors.paperElevated),
      borderRadius: BorderRadius.circular(BfRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BfRadius.md),
        child: Container(
          padding: const EdgeInsets.all(BfSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BfRadius.md),
            border: Border.all(
              color: selected ? BfColors.accent : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? BfColors.accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                size: 22,
              ),
              const SizedBox(width: BfSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        if (badge != null) ...[
                          const SizedBox(width: BfSpacing.xs),
                          BfXpChip(label: badge!),
                        ],
                      ],
                    ),
                    const SizedBox(height: BfSpacing.xxs),
                    Text(
                      price ?? fallbackHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: price == null
                                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (product == null)
                      Text(
                        'Product ID: $fallbackId',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable();

  @override
  Widget build(BuildContext context) {
    final rows = <(String, bool, bool)>[
      ('Habit tracking & streaks', true, true),
      ('Cloud backup (signed in)', true, true),
      ('Urge logging & interventions', true, true),
      ('Recovery plan & panic surfing', true, true),
      ('Protection Center setup & app blocking', true, true),
      ('Multiple habits', false, true),
      ('Journal insights & weekly trends', false, true),
      ('Extra Freeze & Shield each week', false, true),
      ('Accountability Companion', false, true),
      ('Advanced schedules & custom domains', false, true),
      ('Companion protection alerts', false, true),
      ('Transaction Scanner', false, true),
      ('Full protection history', false, true),
    ];

    return BfSurface(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 3, child: Text('')),
              Expanded(
                child: Text('Free', style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text('Premium', style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
              ),
            ],
          ),
          const SizedBox(height: BfSpacing.xs),
          const BfDivider(),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: BfSpacing.xs),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(row.$1, style: Theme.of(context).textTheme.bodySmall)),
                  Expanded(
                    child: Icon(
                      row.$2 ? Icons.check : Icons.close,
                      size: 18,
                      color: row.$2 ? BfColors.success : BfColors.textTertiaryDark,
                    ),
                  ),
                  Expanded(
                    child: Icon(
                      row.$3 ? Icons.check : Icons.close,
                      size: 18,
                      color: row.$3 ? BfColors.success : BfColors.textTertiaryDark,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: BfSpacing.xxs),
          Text(
            'Free includes ${FreeTier.maxHabits} habit, ${FreeTier.freezesPerWeek} freeze/week, and ${FreeTier.shieldsPerWeek} shield/week (Level 3+).',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
