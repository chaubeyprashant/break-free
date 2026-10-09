import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/replacement_activity.dart';
import 'package:break_free/core/providers/activity_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/gamification/presentation/level_up_overlay.dart';

/// Pick something to do instead, grouped by duration.
class ReplaceHabitScreen extends StatefulWidget {
  const ReplaceHabitScreen({super.key});

  @override
  State<ReplaceHabitScreen> createState() => _ReplaceHabitScreenState();
}

class _ReplaceHabitScreenState extends State<ReplaceHabitScreen> {
  ActivityTier _tier = ActivityTier.five;

  Future<void> _start(ReplacementActivity activity) async {
    if (activity.kind == ActivityKind.miniGame) {
      final won = await context.push<bool>('/bubble-game');
      if (won != true || !mounted) return;
      final xp = activity.tier.xpReward;
      await context.read<ActivityProvider>().recordCompletion(activity, xpAwarded: xp);
      if (!mounted) return;
      final leveledUp = await context.read<GameProvider>().addXp(xp, coinBonus: activity.tier.coinReward);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${activity.title} done  ·  +$xp XP')),
      );
      if (leveledUp) {
        final progress = context.read<GameProvider>().progress;
        await showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (ctx) => LevelUpOverlay(
            newLevel: progress.level,
            levelTitle: progress.levelTitle,
            onDismiss: () => Navigator.of(ctx).pop(),
          ),
        );
      }
      return;
    }
    await context.push('/replace/session', extra: activity);
  }

  @override
  Widget build(BuildContext context) {
    final activities = ActivityCatalog.forTier(_tier);
    return Scaffold(
      appBar: AppBar(title: const Text('Replace the habit')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.xs, BfSpacing.screenH, BfSpacing.sm),
            child: Consumer<ActivityProvider>(
              builder: (context, provider, _) => Text(
                provider.completions.isEmpty
                    ? 'How much time do you have?'
                    : '${provider.completions.length} activities  ·  ${provider.totalMinutes} minutes redirected',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BfSpacing.screenH),
            child: SegmentedButton<ActivityTier>(
              segments: [
                for (final t in ActivityTier.values)
                  ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {_tier},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tier = s.first),
            ),
          ),
          const SizedBox(height: BfSpacing.sm),
          Expanded(
            child: ListView.separated(
              key: ValueKey(_tier),
              padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.xs, BfSpacing.screenH, BfSpacing.huge),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const BfDivider(),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(activity.title, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(activity.description),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${activity.tier.xpReward} XP',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: BfColors.accent),
                      ),
                      if (activity.kind == ActivityKind.miniGame)
                        Text('Game', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                  onTap: () => _start(activity),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
