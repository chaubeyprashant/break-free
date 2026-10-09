import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/streak_milestone.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/providers/entitlement_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/journal_provider.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/providers/urge_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/quests/presentation/daily_quests_card.dart';
import 'package:break_free/features/subscription/domain/premium_feature.dart';
import 'package:break_free/features/subscription/presentation/premium_lock_sheet.dart';

/// Progress tab — streaks, week summary, patterns. Calm analytics, not a scoreboard.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;
    final urges = context.watch<UrgeProvider>().urges;
    final policy = context.watch<StreakPolicyProvider>();
    final game = context.watch<GameProvider>().progress;
    final journal = context.watch<JournalProvider>();

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekUrges = urges.where((u) => u.timestamp.isAfter(weekStart)).toList();
    final avgIntensity = weekUrges.isEmpty
        ? 0.0
        : weekUrges.map((u) => u.intensity).reduce((a, b) => a + b) / weekUrges.length;

    UrgeTrigger? topTrigger;
    if (weekUrges.isNotEmpty) {
      final counts = <UrgeTrigger, int>{};
      for (final u in weekUrges) {
        counts[u.trigger] = (counts[u.trigger] ?? 0) + 1;
      }
      topTrigger = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    final bestStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.currentStreakDays).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            tooltip: 'Achievements',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => context.push('/achievements'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BfSpacing.screenH,
          BfSpacing.xs,
          BfSpacing.screenH,
          BfSpacing.huge,
        ),
        children: [
          const BfSectionLabel('Streaks'),
          const SizedBox(height: BfSpacing.sm),
          if (habits.isEmpty)
            BfEmptyState(
              title: 'No habits yet',
              body: 'Add a habit to start tracking streaks.',
              actionLabel: 'Add habit',
              onAction: () => context.push('/habit-selection'),
            )
          else ...[
            Row(
              children: [
                Expanded(child: BfMetric(value: '$bestStreak', label: 'Current best')),
                Expanded(
                  child: BfMetric(
                    value: '${policy.freezesRemaining}',
                    label: 'Freezes left',
                  ),
                ),
              ],
            ),
            const SizedBox(height: BfSpacing.md),
            ...habits.map((habit) {
              final next = StreakMilestone.next(habit.currentStreakDays);
              return BfListRow(
                title: habit.title,
                subtitle: next == null
                    ? '${habit.currentStreakDays} days · all milestones reached'
                    : '${habit.currentStreakDays} days · next ${next.days}-day mark',
                trailing: TextButton(
                  onPressed: () => context.push('/relapse', extra: habit.id),
                  child: Text(
                    'Log slip',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                showDivider: habit != habits.last,
              );
            }),
          ],

          const SizedBox(height: BfSpacing.sectionGap),
          const DailyQuestsCard(embedded: true),

          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('Your week'),
          const SizedBox(height: BfSpacing.sm),
          Row(
            children: [
              Expanded(
                child: BfMetric(
                  value: '${weekUrges.length}',
                  label: 'Urges logged',
                  align: TextAlign.center,
                ),
              ),
              Expanded(
                child: BfMetric(
                  value: avgIntensity == 0 ? '—' : avgIntensity.toStringAsFixed(1),
                  label: 'Avg intensity',
                  align: TextAlign.center,
                ),
              ),
              Expanded(
                child: BfMetric(
                  value: '${game.level}',
                  label: 'Level',
                  align: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: BfSpacing.lg),
          _WeekBars(urges: weekUrges, weekStart: weekStart),

          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('Patterns'),
          const SizedBox(height: BfSpacing.sm),
          if (topTrigger == null)
            Text(
              'Log a few urges this week to see patterns.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Text(
              '${topTrigger.label} is your most common trigger this week.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: BfSpacing.md),
          BfListRow(
            title: 'Urge history',
            subtitle: 'Intensity, triggers, and timing',
            onTap: () => context.push('/urge/history'),
          ),
          BfListRow(
            title: 'Journal',
            subtitle: journal.entries.isEmpty
                ? 'Start a reflection'
                : '${journal.entries.length} reflections',
            onTap: () => context.push('/reflection'),
          ),
          BfListRow(
            title: 'Journal insights',
            subtitle: 'Triggers and hard times of day',
            onTap: () {
              if (!context.read<EntitlementProvider>().isPremium) {
                showPremiumLockSheet(context, feature: PremiumFeature.journalInsights);
                return;
              }
              context.push('/reflection');
            },
            showDivider: false,
          ),

          const SizedBox(height: BfSpacing.sectionGap),
          const BfSectionLabel('Mind City'),
          const SizedBox(height: BfSpacing.sm),
          BfListRow(
            title: 'Visit Mind City',
            subtitle: 'Atmospheric progress space',
            onTap: () => context.push('/city'),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.urges, required this.weekStart});

  final List<UrgeEvent> urges;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final counts = List<int>.filled(7, 0);
    for (final u in urges) {
      final day = u.timestamp.difference(DateTime(weekStart.year, weekStart.month, weekStart.day)).inDays;
      if (day >= 0 && day < 7) counts[day]++;
    }
    final max = counts.fold<int>(1, (a, b) => a > b ? a : b);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final h = 8.0 + (counts[i] / max) * 64;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: counts[i] == 0
                          ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.35)
                          : BfColors.accent.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i], style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
