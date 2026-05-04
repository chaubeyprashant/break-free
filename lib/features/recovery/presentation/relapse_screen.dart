import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/streak_policy_provider.dart';
import 'package:break_free/core/models/habit.dart';

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
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Padding(
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
              Text(
                'What triggered you?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _commonTriggers.map((trigger) {
                  final isSelected = _selectedTrigger == trigger;
                  return Material(
                    color: isSelected ? const Color(0xFF238636) : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTrigger = isSelected ? null : trigger),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          trigger,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedTrigger == null
                    ? null
                    : () => _onLogRelapse(context),
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

    if (useFreeze) {
      final ok = await policyProvider.useFreeze();
      if (context.mounted && ok) {
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
      if (context.mounted && ok) {
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
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset streak?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will reset your $streakDays day streak for this habit. You can\'t undo this.',
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

    if (confirm != true || !context.mounted) return;

    if (habitId != null) {
      await habitProvider.logRelapse(habitId);
    }
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

class _ProtectionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProtectionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.06),
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
