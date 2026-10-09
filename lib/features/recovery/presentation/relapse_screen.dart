import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/journal_provider.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/models/habit.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class RelapseScreen extends StatefulWidget {
  final String? habitId;
  const RelapseScreen({super.key, this.habitId});

  @override
  State<RelapseScreen> createState() => _RelapseScreenState();
}

class _RelapseScreenState extends State<RelapseScreen> {
  String? _selectedTrigger;
  final List<String> _commonTriggers = [
    'Stress',
    'Boredom',
    'Loneliness',
    'Anxiety',
    'Celebration',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BfColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BfSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: BfSpacing.xxl),
              Text(
                'What happened?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: BfColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 200.ms),
              const SizedBox(height: BfSpacing.sm),
              Text(
                'Understanding the trigger helps you prepare for next time.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BfColors.textSecondaryDark,
                      height: 1.45,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: BfSpacing.xxxl),
              const BfSectionLabel('Trigger'),
              const SizedBox(height: BfSpacing.md),
              Wrap(
                spacing: BfSpacing.sm,
                runSpacing: BfSpacing.sm,
                children: _commonTriggers.map((trigger) {
                  final isSelected = _selectedTrigger == trigger;
                  return Material(
                    color: isSelected ? BfColors.accent : BfColors.inkSoft,
                    borderRadius: BorderRadius.circular(BfRadius.md),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTrigger = isSelected ? null : trigger),
                      borderRadius: BorderRadius.circular(BfRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: BfSpacing.md, vertical: BfSpacing.sm),
                        child: Text(
                          trigger,
                          style: TextStyle(
                            color: isSelected ? BfColors.textPrimaryDark : BfColors.textSecondaryDark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              _buildProtectionOptions(context),
              const SizedBox(height: BfSpacing.md),
              BfPrimaryButton(
                label: 'Continue recovery',
                onPressed: _selectedTrigger == null ? null : () => _onLogRelapse(context),
              ),
              const SizedBox(height: BfSpacing.xs),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel', style: TextStyle(color: BfColors.textTertiaryDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionOptions(BuildContext context) {
    return Consumer3<StreakPolicyProvider, GameProvider, HabitProvider>(
      builder: (context, policyProvider, gameProvider, habitProvider, _) {
        Habit? habit;
        if (widget.habitId != null) {
          final list = habitProvider.habits.where((h) => h.id == widget.habitId).toList();
          habit = list.isEmpty ? null : list.first;
        }
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: BfColors.textSecondaryDark),
            ),
            const SizedBox(height: BfSpacing.sm),
            if (canFreeze)
              _ProtectionChip(
                icon: Icons.ac_unit_rounded,
                label: 'Use freeze (${policyProvider.freezesRemaining} left this week)',
                onTap: () => _useProtection(context, useFreeze: true),
              ),
            if (canFreeze && canShield) const SizedBox(height: BfSpacing.xs),
            if (canShield)
              _ProtectionChip(
                icon: Icons.shield_rounded,
                label: 'Use streak shield (Level $level)',
                onTap: () => _useProtection(context, useShield: true),
              ),
            const SizedBox(height: BfSpacing.md),
          ],
        ).animate().fadeIn().slideY(begin: 0.1, end: 0);
      },
    );
  }

  void _useProtection(BuildContext context, {bool useFreeze = false, bool useShield = false}) async {
    final policyProvider = context.read<StreakPolicyProvider>();
    final gameProvider = context.read<GameProvider>();

    if (useFreeze) {
      final ok = await policyProvider.useFreeze();
      if (context.mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Freeze used. Your streak is safe.'),
            backgroundColor: BfColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } else if (useShield) {
      final ok = await policyProvider.useShield(gameProvider.progress.level);
      if (context.mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shield used. Streak protected.'),
            backgroundColor: BfColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _onLogRelapse(BuildContext context) async {
    final habitProvider = context.read<HabitProvider>();
    final habitId = widget.habitId;
    Habit? habit;
    if (habitId != null) {
      final list = habitProvider.habits.where((h) => h.id == habitId).toList();
      habit = list.isEmpty ? null : list.first;
    }
    final streakDays = habit?.currentStreakDays ?? 0;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: BfColors.inkElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BfRadius.lg)),
        title: const Text(
          'Reset streak?',
          style: TextStyle(color: BfColors.textPrimaryDark, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will reset your $streakDays day streak for this habit. You can\'t undo this.',
          style: const TextStyle(color: BfColors.textSecondaryDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: BfColors.textSecondaryDark)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: BfColors.danger),
            child: const Text('Yes, log slip'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    if (habitId != null) {
      await habitProvider.logRelapse(habitId);
    }
    if (context.mounted) {
      try {
        await context.read<JournalProvider>().create(
              note: 'Slip logged from relapse screen.',
              moodRating: 2.0,
              urgeIntensity: 0,
              triggers: _selectedTrigger == null ? const [] : [_selectedTrigger!],
              isRelapse: true,
              habitId: habitId,
            );
      } catch (_) {}
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged. Let\'s start fresh.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
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
      color: BfColors.inkSoft,
      borderRadius: BorderRadius.circular(BfRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BfRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BfSpacing.md, vertical: BfSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: BfColors.accent, size: 22),
              const SizedBox(width: BfSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: BfColors.textPrimaryDark,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
