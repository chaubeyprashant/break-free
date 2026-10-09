import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/achievement.dart';
import 'package:break_free/core/providers/achievement_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              BfSpacing.screenH,
              BfSpacing.sm,
              BfSpacing.screenH,
              BfSpacing.huge,
            ),
            children: [
              Text(
                '${provider.unlockedCount} of ${provider.totalCount} unlocked',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: BfSpacing.xs),
              Text(
                'Earned from what you actually did in the app — not purchased unlocks.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: BfSpacing.xl),
              const BfSectionLabel('Milestones'),
              const SizedBox(height: BfSpacing.xs),
              for (final id in AchievementId.values)
                _AchievementRow(id: id, unlock: provider.unlockFor(id)),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.id, required this.unlock});

  final AchievementId id;
  final UnlockedAchievement? unlock;

  @override
  Widget build(BuildContext context) {
    final unlocked = unlock != null;
    return BfListRow(
      title: id.title,
      subtitle: unlocked
          ? '${id.description}\n${DateFormat('d MMM yyyy').format(unlock!.unlockedAt)}'
          : id.description,
      leading: Icon(
        unlocked ? Icons.check_circle_outline : Icons.circle_outlined,
        size: 22,
        color: unlocked
            ? BfColors.accent
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      trailing: Text(
        unlocked ? 'Done' : '+${id.xp} XP',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: unlocked ? BfColors.success : BfColors.accent,
            ),
      ),
      showDivider: id != AchievementId.values.last,
    );
  }
}
