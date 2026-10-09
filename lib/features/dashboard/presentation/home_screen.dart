import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/habit.dart';
import 'package:break_free/core/providers/achievement_provider.dart';
import 'package:break_free/core/providers/check_in_provider.dart';
import 'package:break_free/core/providers/daily_quest_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/providers/urge_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/achievements/presentation/achievement_toast.dart';
import 'package:break_free/features/companion/data/companion_repository.dart';

/// Calm primary home — streak, today, support CTA. Not a feature dump.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AchievementProvider? _achievements;

  @override
  void initState() {
    super.initState();
    companionRepository.updateFcmToken();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPendingAchievementToasts());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AchievementProvider>();
    if (!identical(provider, _achievements)) {
      _achievements?.removeListener(_showPendingAchievementToasts);
      _achievements = provider..addListener(_showPendingAchievementToasts);
    }
  }

  @override
  void dispose() {
    _achievements?.removeListener(_showPendingAchievementToasts);
    super.dispose();
  }

  void _showPendingAchievementToasts() {
    final provider = _achievements;
    if (provider == null || !mounted || !provider.hasPendingToasts) return;
    for (final id in provider.takeToasts()) {
      AchievementToast.show(context, id);
    }
  }

  Habit? _primaryHabit(List<Habit> habits) {
    if (habits.isEmpty) return null;
    return habits.reduce(
      (a, b) => a.currentStreakDays >= b.currentStreakDays ? a : b,
    );
  }

  Future<void> _checkIn(BuildContext context, Habit habit) async {
    final checkIns = context.read<CheckInProvider>();
    if (checkIns.hasCheckedInToday(habit.id)) return;
    final ok = await checkIns.recordCheckIn(habit.id);
    if (!ok || !context.mounted) return;
    final game = context.read<GameProvider>();
    final quests = context.read<DailyQuestProvider>();
    await game.addXp(25, coinBonus: 5);
    await quests.recordCheckIn();
    if (!context.mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in saved  ·  +25 XP')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;
    final primary = _primaryHabit(habits);
    final checkIns = context.watch<CheckInProvider>();
    final quests = context.watch<DailyQuestProvider>();
    final game = context.watch<GameProvider>().progress;
    final policy = context.watch<StreakPolicyProvider>();
    final urges = context.watch<UrgeProvider>().urges;
    final today = DateTime.now();
    final urgesToday = urges.where((u) {
      return u.timestamp.year == today.year &&
          u.timestamp.month == today.month &&
          u.timestamp.day == today.day;
    }).length;

    final checkedCount = habits.where((h) => checkIns.hasCheckedInToday(h.id)).length;
    final questDone = quests.quests.where((q) => q.isCompleted).length;
    final questTotal = quests.quests.length;

    final streak = primary?.currentStreakDays ?? 0;
    final momentum = streak == 0
        ? 'Start today. One clean day begins the streak.'
        : streak < 7
            ? 'You\'re building momentum.'
            : streak < 30
                ? 'Consistency is compounding.'
                : 'This streak is hard-won. Protect it.';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                BfSpacing.screenH,
                BfSpacing.md,
                BfSpacing.screenH,
                BfSpacing.huge,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'BREAK FREE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 2,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                  ),
                  const SizedBox(height: BfSpacing.xl),

                  // Streak hero
                  if (primary == null)
                    BfEmptyState(
                      title: 'Choose a habit to protect',
                      body: 'Pick what you\'re working on. Your streak starts here.',
                      actionLabel: 'Add habit',
                      onAction: () => context.push('/habit-selection'),
                    )
                  else ...[
                    BfMetric(value: '$streak', label: 'Day streak'),
                    const SizedBox(height: BfSpacing.sm),
                    Text(momentum, style: Theme.of(context).textTheme.bodyLarge),
                    if (habits.length > 1) ...[
                      const SizedBox(height: BfSpacing.xs),
                      Text(
                        primary.title,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: BfSpacing.md),
                    Wrap(
                      spacing: BfSpacing.xs,
                      runSpacing: BfSpacing.xs,
                      children: [
                        if (policy.freezesRemaining > 0)
                          BfXpChip(label: '${policy.freezesRemaining} freeze'),
                        if (policy.shieldsRemaining > 0)
                          BfXpChip(label: '${policy.shieldsRemaining} shield'),
                      ],
                    ),
                  ],

                  const SizedBox(height: BfSpacing.sectionGap),
                  const BfSectionLabel('Today'),
                  const SizedBox(height: BfSpacing.sm),
                  if (habits.isEmpty)
                    const Text('No habits yet.', style: TextStyle(height: 1.4))
                  else ...[
                    ...habits.map((habit) {
                      final done = checkIns.hasCheckedInToday(habit.id);
                      return BfListRow(
                        title: habit.title,
                        subtitle: '${habit.currentStreakDays} day streak',
                        trailing: done
                            ? Icon(Icons.check_rounded, color: BfColors.success, size: 20)
                            : TextButton(
                                onPressed: () => _checkIn(context, habit),
                                child: const Text('Check in'),
                              ),
                        onTap: done
                            ? null
                            : () => _checkIn(context, habit),
                        showDivider: habit != habits.last,
                      );
                    }),
                    const SizedBox(height: BfSpacing.sm),
                    Text(
                      'Check-in  $checkedCount/${habits.length}'
                      '${questTotal > 0 ? '   ·   Quests  $questDone/$questTotal' : ''}'
                      '${urgesToday > 0 ? '   ·   Urges logged  $urgesToday' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  const SizedBox(height: BfSpacing.sectionGap),
                  const BfSectionLabel('Need support?'),
                  const SizedBox(height: BfSpacing.sm),
                  Text(
                    'Urges pass. Give yourself ninety seconds.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: BfSpacing.md),
                  BfPrimaryButton(
                    label: 'I\'m having an urge',
                    icon: Icons.self_improvement_outlined,
                    onPressed: () => context.push('/urge'),
                  ),
                  const SizedBox(height: BfSpacing.xs),
                  BfSecondaryButton(
                    label: 'Recovery plan',
                    onPressed: () => context.push('/help'),
                  ),

                  const SizedBox(height: BfSpacing.sectionGap),
                  const BfSectionLabel('Level'),
                  const SizedBox(height: BfSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Level ${game.level}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(width: BfSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          game.levelTitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${game.xp} XP',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: BfSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(BfRadius.sm),
                    child: LinearProgressIndicator(
                      value: game.xpToNextLevel == 0
                          ? 0
                          : (game.xp / game.xpToNextLevel).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: BfColors.accentSoft,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
