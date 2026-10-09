import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';

/// Consistent sheet when a free user taps a Premium feature.
Future<void> showPremiumLockSheet(
  BuildContext context, {
  required PremiumFeature feature,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(BfSpacing.xl, BfSpacing.xs, BfSpacing.xl, BfSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: BfColors.accent, size: 24),
                const SizedBox(width: BfSpacing.sm),
                Text(
                  'Premium feature',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: BfSpacing.md),
            Text(
              feature.title,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: BfSpacing.xs),
            Text(
              feature.benefit,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: BfSpacing.xs),
            Text(
              'Your existing progress stays on this device. Premium adds deeper support — it does not reset your streaks.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: BfSpacing.xl),
            BfPrimaryButton(
              label: 'Upgrade to Break Free Premium',
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/subscription');
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not now'),
            ),
          ],
        ),
      );
    },
  );
}
