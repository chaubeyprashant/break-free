import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/daily_quest.dart';
import 'package:break_free/core/providers/daily_quest_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

/// Today's quests — quiet rows, thin progress, no coin emoji.
class DailyQuestsCard extends StatefulWidget {
  const DailyQuestsCard({super.key, this.embedded = false});

  /// When true, omits outer padding (for Progress tab).
  final bool embedded;

  @override
  State<DailyQuestsCard> createState() => _DailyQuestsCardState();
}

class _DailyQuestsCardState extends State<DailyQuestsCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) context.read<DailyQuestProvider>().tick();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DailyQuestProvider>().tick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyQuestProvider>(
      builder: (context, provider, _) {
        final quests = provider.quests;
        if (quests.isEmpty) return const SizedBox.shrink();

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BfSectionLabel('Daily quests'),
                const Spacer(),
                Text(
                  '${provider.completedCount}/${quests.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: BfSpacing.sm),
            for (final (index, quest) in quests.indexed) ...[
              _QuestRow(quest: quest),
              if (index < quests.length - 1) const SizedBox(height: BfSpacing.md),
            ],
          ],
        );

        if (widget.embedded) return content;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: BfSpacing.screenH, vertical: BfSpacing.xs),
          child: content,
        );
      },
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.quest});
  final DailyQuest quest;

  @override
  Widget build(BuildContext context) {
    final done = quest.isCompleted;
    final progressText = quest.type.isTimed
        ? '${quest.progress ~/ 60}h ${(quest.progress % 60).toString().padLeft(2, '0')}m / ${quest.target ~/ 60}h'
        : '${quest.progress}/${quest.target}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              done ? Icons.check_rounded : Icons.circle_outlined,
              size: 18,
              color: done ? BfColors.success : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: BfSpacing.sm),
            Expanded(
              child: Text(
                quest.type.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done
                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                          : null,
                    ),
              ),
            ),
            Text(
              '+${quest.type.xp} XP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: BfColors.accent),
            ),
          ],
        ),
        const SizedBox(height: BfSpacing.xxs),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(quest.type.description, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: BfSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: quest.fraction,
                    minHeight: 3,
                    backgroundColor: BfColors.accentSoft,
                    color: done ? BfColors.success : BfColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: BfSpacing.xs),
              Text(progressText, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}
