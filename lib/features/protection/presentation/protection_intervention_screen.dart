import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class ProtectionInterventionArgs {
  const ProtectionInterventionArgs({
    required this.kind,
    this.packageName,
    this.appName,
    this.url,
    this.category,
    this.reasonText,
  });

  final String kind; // app | website | notification
  final String? packageName;
  final String? appName;
  final String? url;
  final String? category;
  final String? reasonText;
}

/// Compassionate shared intervention for app / website / notification blocks.
class ProtectionInterventionScreen extends StatelessWidget {
  const ProtectionInterventionScreen({super.key, required this.args});

  final ProtectionInterventionArgs args;

  @override
  Widget build(BuildContext context) {
    final protection = context.watch<ProtectionProvider>();
    final allowContinue = protection.config.allowContinueAnyway;

    return Scaffold(
      backgroundColor: BfColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BfSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.self_improvement, size: 72, color: BfColors.accent),
              const SizedBox(height: BfSpacing.xl),
              Text(
                'Take a breath.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: BfColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: BfSpacing.sm),
              Text(
                'This is one of the moments\nyou\'re trying to change.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BfColors.textSecondaryDark,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
              ),
              const SizedBox(height: BfSpacing.lg),
              if (args.reasonText != null || args.appName != null || args.category != null)
                Container(
                  padding: const EdgeInsets.all(BfSpacing.md),
                  decoration: BoxDecoration(
                    color: BfColors.inkElevated,
                    borderRadius: BorderRadius.circular(BfRadius.md),
                    border: Border.all(color: BfColors.borderDark),
                  ),
                  child: Text(
                    args.reasonText ??
                        (args.appName != null
                            ? 'Trying to open ${args.appName}'
                            : 'Matched ${args.category ?? 'protected content'}'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BfColors.textSecondaryDark),
                  ),
                ),
              const Spacer(),
              BfPrimaryButton(
                label: 'Ride out this urge',
                onPressed: () => context.go('/urge'),
              ),
              const SizedBox(height: BfSpacing.sm),
              BfSecondaryButton(
                label: 'Start 90s breathing',
                onPressed: () => context.push('/panic'),
              ),
              const SizedBox(height: BfSpacing.sm),
              BfSecondaryButton(
                label: 'Recovery plan',
                onPressed: () => context.push('/help'),
              ),
              if (allowContinue) ...[
                const SizedBox(height: BfSpacing.sm),
                TextButton(
                  onPressed: () async {
                    await context.read<ProtectionProvider>().grantContinueAnyway(
                          packageName: args.packageName,
                          domain: args.url,
                        );
                    if (context.mounted) context.go('/');
                  },
                  child: Text(
                    'Continue anyway (${protection.config.continueAnywayMinutes} min)',
                    style: const TextStyle(color: BfColors.textTertiaryDark),
                  ),
                ),
              ] else ...[
                const SizedBox(height: BfSpacing.sm),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text(
                    'Return home',
                    style: TextStyle(color: BfColors.textTertiaryDark),
                  ),
                ),
              ],
              const SizedBox(height: BfSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
