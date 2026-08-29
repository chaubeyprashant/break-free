import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:break_free/core/data/activity_log_repository.dart';
import 'package:break_free/core/data/relapse_log_repository.dart';
import 'package:break_free/core/models/activity_event.dart';
import 'package:break_free/core/models/relapse_record.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/models/habit.dart';
import 'package:break_free/features/dashboard/presentation/streak_provider.dart';

class RelapseScreen extends StatefulWidget {
  final String? habitId;
  const RelapseScreen({super.key, this.habitId});

  @override
  State<RelapseScreen> createState() => _RelapseScreenState();
}

class _RelapseScreenState extends State<RelapseScreen> {
  String? _selectedTrigger;
  String? _selectedHabitId;
  final List<String> _commonTriggers = [
    'Stress',
    'Boredom',
    'Loneliness',
    'Anxiety',
    'Celebration',
    'Other',
  ];

  /// The habit this slip belongs to: the one we were routed with, the one the
  /// user picked, or the only one they track.
  String? _resolveHabitId(List<Habit> habits) {
    if (widget.habitId != null) return widget.habitId;
    if (_selectedHabitId != null) return _selectedHabitId;
    if (habits.length == 1) return habits.first.id;
    return null;
  }

  Habit? _habitById(List<Habit> habits, String? id) {
    if (id == null) return null;
    final matches = habits.where((h) => h.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;
    final habitId = _resolveHabitId(habits);
    final needsHabitChoice = widget.habitId == null && habits.length > 1;
    final canLog =
        _selectedTrigger != null && (habits.isEmpty || habitId != null);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.broken_image_outlined,
                size: 72,
                color: Colors.white24,
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'It happens.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 12),
              Text(
                'A slip doesn\'t erase your progress. It\'s just a stumble on the journey.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.4),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 40),
              if (needsHabitChoice) ...[
                Text(
                  'Which habit?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: habits.map((habit) {
                    return _SelectableChip(
                      label: '${habit.iconPath} ${habit.title}',
                      isSelected: habitId == habit.id,
                      onTap: () => setState(
                        () => _selectedHabitId =
                            habitId == habit.id ? null : habit.id,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
              Text(
                'What triggered you?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _commonTriggers.map((trigger) {
                  return _SelectableChip(
                    label: trigger,
                    isSelected: _selectedTrigger == trigger,
                    onTap: () => setState(
                      () => _selectedTrigger =
                          _selectedTrigger == trigger ? null : trigger,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              _buildProtectionOptions(context, habits, habitId),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: canLog ? () => _onLogRelapse(context, habits, habitId) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Log slip & restart'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionOptions(
    BuildContext context,
    List<Habit> habits,
    String? habitId,
  ) {
    return Consumer2<StreakPolicyProvider, GameProvider>(
      builder: (context, policyProvider, gameProvider, _) {
        final habit = _habitById(habits, habitId);
        final streakDays = habit?.currentStreakDays ?? 0;
        final level = gameProvider.progress.level;
        final canFreeze = policyProvider.canUseFreeze;
        final canShield = policyProvider.canUseShieldAtLevel(level);

        if (!canFreeze && !canShield) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Protect your $streakDays day streak',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (canFreeze)
              _ProtectionChip(
                icon: Icons.ac_unit_rounded,
                label: 'Use freeze (${policyProvider.freezesRemaining} left this week)',
                onTap: () => _useProtection(context, useFreeze: true),
              ),
            if (canFreeze && canShield) const SizedBox(height: 8),
            if (canShield)
              _ProtectionChip(
                icon: Icons.shield_rounded,
                label: 'Use streak shield (Level $level)',
                onTap: () => _useProtection(context, useShield: true),
              ),
            const SizedBox(height: 16),
          ],
        ).animate().fadeIn().slideY(begin: 0.1, end: 0);
      },
    );
  }

  void _useProtection(BuildContext context, {bool useFreeze = false, bool useShield = false}) async {
    final policyProvider = context.read<StreakPolicyProvider>();
    final gameProvider = context.read<GameProvider>();
    final activityLog = context.read<ActivityLogRepository>();

    if (useFreeze) {
      final ok = await policyProvider.useFreeze();
      if (!ok) return;
      await activityLog.record(
        ActivityEvent.now(
          type: ActivityEvent.achievement,
          title: 'Streak frozen',
          description: 'Used a freeze to protect your streak',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Freeze used. Your streak is safe.'),
            backgroundColor: const Color(0xFF238636),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } else if (useShield) {
      final ok = await policyProvider.useShield(gameProvider.progress.level);
      if (!ok) return;
      await activityLog.record(
        ActivityEvent.now(
          type: ActivityEvent.achievement,
          title: 'Shield used',
          description: 'Streak protected',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Shield used. Streak protected.'),
            backgroundColor: const Color(0xFF1F6FEB),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _onLogRelapse(
    BuildContext context,
    List<Habit> habits,
    String? habitId,
  ) async {
    final habitProvider = context.read<HabitProvider>();
    final streakProvider = context.read<StreakProvider>();
    final activityLog = context.read<ActivityLogRepository>();
    final relapseLog = context.read<RelapseLogRepository>();

    final habit = _habitById(habits, habitId);
    final streakDays = habit?.currentStreakDays ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset streak?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This restarts your $streakDays day streak. Your level, XP and coins stay with you.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, log slip'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (habitId != null) {
      await habitProvider.logRelapse(habitId);
    }
    // The dashboard streak counts from this moment too, or it would keep
    // climbing after a slip the user just told us about.
    await streakProvider.resetStreak();
    await activityLog.record(
      ActivityEvent.now(
        type: ActivityEvent.relapse,
        title: 'Logged a slip',
        description: habit == null
            ? 'Trigger: $_selectedTrigger'
            : '${habit.title} — trigger: $_selectedTrigger',
      ),
    );
    // Structured copy, so the Journal can find patterns in it later.
    await relapseLog.record(
      RelapseRecord.now(
        trigger: _selectedTrigger ?? '',
        habitId: habitId,
        habitTitle: habit?.title,
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logged. Let\'s start fresh.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF238636) : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProtectionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProtectionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF58A6FF), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
