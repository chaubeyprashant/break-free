import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mukti/core/providers/habit_provider.dart';
import 'package:mukti/core/providers/game_provider.dart';
import 'package:mukti/core/providers/streak_policy_provider.dart';
import 'package:mukti/core/theme/app_theme.dart';
import 'package:mukti/core/models/streak_milestone.dart';
import 'package:mukti/core/models/habit.dart';
import 'package:mukti/features/gamification/presentation/level_up_overlay.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildStreakProtectionBar(context)),
            SliverToBoxAdapter(child: _buildHabitList(context)),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/panic'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
        icon: const Icon(Icons.warning_rounded),
        label: const Text('Panic Button'),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        onDestinationSelected: (index) {
          if (index == 0) return;
          if (index == 1) context.push('/city');
          if (index == 2) context.push('/reflection');
          if (index == 3) context.push('/settings');
        },
        selectedIndex: 0,
        elevation: 0,
        height: 70,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.location_city_rounded), label: 'City'),
          NavigationDestination(icon: Icon(Icons.book_rounded), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final progress = gameProvider.progress;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppTheme.primaryDark.withOpacity(0.9),
                      const Color(0xFF2A9D8F),
                    ]
                  : [
                      const Color(0xFF1A535C),
                      const Color(0xFF2A9D8F),
                    ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.levelTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Level ${progress.level}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '${progress.coins}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress.xp / progress.xpToNextLevel,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      color: const Color(0xFFFFD700),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🦸', style: TextStyle(fontSize: 44)),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${progress.xp} / ${progress.xpToNextLevel} XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildStreakProtectionBar(BuildContext context) {
    return Consumer<StreakPolicyProvider>(
      builder: (context, policyProvider, _) {
        if (policyProvider.freezesRemaining == 0 && policyProvider.shieldsRemaining == 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (policyProvider.freezesRemaining > 0)
                _ProtectionChip(
                  icon: Icons.ac_unit_rounded,
                  label: '${policyProvider.freezesRemaining} freeze',
                ),
              if (policyProvider.freezesRemaining > 0 && policyProvider.shieldsRemaining > 0)
                const SizedBox(width: 10),
              if (policyProvider.shieldsRemaining > 0)
                _ProtectionChip(
                  icon: Icons.shield_rounded,
                  label: '${policyProvider.shieldsRemaining} shield',
                ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),
        );
      },
    );
  }

  Widget _buildHabitList(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habits = habitProvider.habits;
        if (habits.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No habits set yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/habit-selection'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Habits'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              ...habits.asMap().entries.map((entry) {
                final index = entry.key;
                final habit = entry.value;
                final milestone = StreakMilestone.reached(habit.currentStreakDays);
                final nextMilestone = StreakMilestone.next(habit.currentStreakDays);
                return _HabitCard(
                  key: ValueKey(habit.id),
                  habit: habit,
                  milestone: milestone,
                  nextMilestone: nextMilestone,
                  onCheckIn: () => _onCheckIn(context, habit.id),
                  onSlip: () => _showHabitOptions(context, habit.id),
                )
                    .animate()
                    .fadeIn(delay: (80 * index).ms)
                    .slideX(begin: 0.04, end: 0, delay: (80 * index).ms, curve: Curves.easeOutCubic);
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onCheckIn(BuildContext context, String habitId) async {
    final gameProvider = context.read<GameProvider>();
    final leveledUp = await gameProvider.addXp(25, coinBonus: 5);
    if (!context.mounted) return;
    // Success animation: show brief overlay then level-up if applicable
    await _showCheckInSuccess(context);
    if (!context.mounted) return;
    if (leveledUp) {
      await _showLevelUpOverlay(context);
    }
  }

  Future<void> _showCheckInSuccess(BuildContext context) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => _CheckInSuccessOverlay(onDismiss: () => Navigator.of(ctx).pop()),
    );
  }

  Future<void> _showLevelUpOverlay(BuildContext context) async {
    final progress = context.read<GameProvider>().progress;
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) => LevelUpOverlay(
        newLevel: progress.level,
        levelTitle: progress.levelTitle,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showHabitOptions(BuildContext context, String habitId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
              ),
              title: const Text('Check-in (Clean Day)'),
              subtitle: const Text('+25 XP, +5 coins'),
              onTap: () {
                Navigator.pop(context);
                _onCheckIn(context, habitId);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.broken_image_rounded, color: Colors.red, size: 26),
              ),
              title: const Text('I Slipped (Log Relapse)'),
              onTap: () {
                Navigator.pop(context);
                context.push('/relapse', extra: habitId);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProtectionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProtectionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final StreakMilestone? milestone;
  final StreakMilestone? nextMilestone;
  final VoidCallback onCheckIn;
  final VoidCallback onSlip;

  const _HabitCard({
    super.key,
    required this.habit,
    required this.milestone,
    required this.nextMilestone,
    required this.onCheckIn,
    required this.onSlip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSlip,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(habit.iconPath, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 18,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreakDays} day streak',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (milestone != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              milestone!.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                      if (nextMilestone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${nextMilestone!.days - habit.currentStreakDays} days to ${nextMilestone!.emoji} ${nextMilestone!.label}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: onCheckIn,
                  icon: const Icon(Icons.check_rounded, size: 26),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckInSuccessOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const _CheckInSuccessOverlay({required this.onDismiss});

  @override
  State<_CheckInSuccessOverlay> createState() => _CheckInSuccessOverlayState();
}

class _CheckInSuccessOverlayState extends State<_CheckInSuccessOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, size: 64, color: Colors.white),
            )
                .animate()
                .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.elasticOut, duration: 500.ms),
            const SizedBox(height: 20),
            Text(
              '+25 XP',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            Text(
              'Great job!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }
}
