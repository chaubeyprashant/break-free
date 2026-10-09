import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/recovery_action.dart';
import 'package:break_free/core/models/urge_intervention.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/recovery_plan_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/async_state_view.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';
import 'package:break_free/features/subscription/presentation/premium_lock_sheet.dart';
import 'package:break_free/features/urge/presentation/urge_intervention_screen.dart';

/// Calm checklist of the user's recovery steps. Session ticks only — no persistence change.
class RecoveryPlanScreen extends StatefulWidget {
  const RecoveryPlanScreen({super.key});

  @override
  State<RecoveryPlanScreen> createState() => _RecoveryPlanScreenState();
}

class _RecoveryPlanScreenState extends State<RecoveryPlanScreen> {
  final Set<String> _done = {};

  void _open(BuildContext context, RecoveryAction action) {
    switch (action.kind) {
      case RecoveryActionKind.checklist:
        setState(() => _done.contains(action.id) ? _done.remove(action.id) : _done.add(action.id));
      case RecoveryActionKind.breathing:
        setState(() => _done.add(action.id));
        context.push(
          '/urge/intervention',
          extra: const UrgeInterventionArgs(urgeId: null, intervention: UrgeIntervention.breathe),
        );
      case RecoveryActionKind.urgeSurfing:
        setState(() => _done.add(action.id));
        context.push('/panic');
      case RecoveryActionKind.contactCompanion:
        setState(() => _done.add(action.id));
        if (!context.read<EntitlementProvider>().isPremium) {
          showPremiumLockSheet(context, feature: PremiumFeature.companionSync);
          return;
        }
        context.push('/companion');
      case RecoveryActionKind.replaceHabit:
        setState(() => _done.add(action.id));
        context.push('/replace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BfColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: BfColors.textPrimaryDark,
        title: const Text('Recovery plan'),
        actions: [
          TextButton(
            onPressed: () => context.push('/help/edit'),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<RecoveryPlanProvider>(
          builder: (context, provider, _) {
            if (!provider.isLoaded) {
              return const AsyncLoadingView(message: 'Loading your plan…');
            }
            final actions = provider.activeActions;
            if (actions.isEmpty) {
              return AsyncEmptyView(
                icon: Icons.support_outlined,
                title: 'No active steps',
                subtitle: 'Enable or add steps in the plan editor.',
                actionLabel: 'Edit plan',
                onAction: () => context.push('/help/edit'),
              );
            }
            final allDone = actions.every((a) => _done.contains(a.id));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allDone ? 'Plan complete' : 'One step at a time',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: BfColors.textPrimaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: BfSpacing.xs),
                      Text(
                        allDone
                            ? 'You worked through every step.'
                            : 'Tap a step when it is done. Some open a tool.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BfColors.textSecondaryDark,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, 0, BfSpacing.screenH, BfSpacing.md),
                    itemCount: actions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: BfColors.borderDark),
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return _ActionRow(
                        index: index + 1,
                        action: action,
                        done: _done.contains(action.id),
                        onTap: () => _open(context, action),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, 0, BfSpacing.screenH, BfSpacing.xl),
                  child: BfPrimaryButton(
                    label: allDone ? 'Back to home' : "I'm okay now",
                    onPressed: () => context.go('/'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.index,
    required this.action,
    required this.done,
    required this.onTap,
  });

  final int index;
  final RecoveryAction action;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opensScreen = action.kind != RecoveryActionKind.checklist;
    final hint = switch (action.kind) {
      RecoveryActionKind.checklist => null,
      RecoveryActionKind.breathing => 'Opens breathing',
      RecoveryActionKind.urgeSurfing => 'Opens 90s session',
      RecoveryActionKind.contactCompanion => 'Opens companion',
      RecoveryActionKind.replaceHabit => 'Opens activities',
    };

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BfSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                done ? '✓' : '$index',
                style: TextStyle(
                  color: done ? BfColors.success : BfColors.textSecondaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: BfColors.textPrimaryDark,
                          decoration: done && !opensScreen ? TextDecoration.lineThrough : null,
                          decorationColor: BfColors.textTertiaryDark,
                        ),
                  ),
                  if (hint != null)
                    Text(
                      hint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BfColors.textTertiaryDark,
                          ),
                    ),
                ],
              ),
            ),
            if (opensScreen)
              const Icon(Icons.chevron_right, size: 20, color: BfColors.textTertiaryDark),
          ],
        ),
      ),
    );
  }
}
