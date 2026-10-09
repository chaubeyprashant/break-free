import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/urge_intervention.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/core/providers/urge_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/gamification/presentation/level_up_overlay.dart';

/// Route arguments for [UrgeInterventionScreen].
class UrgeInterventionArgs {
  const UrgeInterventionArgs({required this.urgeId, required this.intervention});

  /// Null when started from the recovery plan rather than a logged urge.
  final String? urgeId;
  final UrgeIntervention intervention;
}

/// Timed Breathe / Move / Distract session. On completion the urge is marked
/// handled, XP is awarded through the existing GameProvider, and the user is
/// sent back to the dashboard.
class UrgeInterventionScreen extends StatefulWidget {
  const UrgeInterventionScreen({super.key, required this.args});

  final UrgeInterventionArgs args;

  @override
  State<UrgeInterventionScreen> createState() => _UrgeInterventionScreenState();
}

class _UrgeInterventionScreenState extends State<UrgeInterventionScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _completing = false;
  bool _completed = false;
  bool _leveledUp = false;

  UrgeIntervention get _plan => widget.args.intervention;
  Duration get _remaining => _plan.duration - _elapsed;
  double get _progress => (_elapsed.inMilliseconds / _plan.duration.inMilliseconds).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (_completing) return;
    setState(() => _elapsed += const Duration(milliseconds: 250));
    if (_elapsed >= _plan.duration) {
      timer.cancel();
      _complete();
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    _completing = true;
    final urgeProvider = context.read<UrgeProvider>();
    final gameProvider = context.read<GameProvider>();

    final urgeId = widget.args.urgeId;
    if (urgeId != null) await urgeProvider.markHandled(urgeId, _plan);
    final leveledUp = await gameProvider.addXp(
      UrgeIntervention.xpReward,
      coinBonus: UrgeIntervention.coinReward,
    );
    if (!mounted) return;
    setState(() {
      _completed = true;
      _leveledUp = leveledUp;
    });
  }

  Future<void> _finish() async {
    if (_leveledUp) {
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
      if (!mounted) return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _completed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: BfColors.ink,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: BfColors.textPrimaryDark,
          automaticallyImplyLeading: false,
          title: Text(_completed ? '' : _plan.label),
          actions: [
            if (!_completed)
              TextButton(
                onPressed: _confirmLeave,
                child: const Text('Stop', style: TextStyle(color: BfColors.textTertiaryDark)),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BfSpacing.xl),
            child: AnimatedSwitcher(
              duration: 300.ms,
              child: _completed ? _buildCompleted(context) : _buildSession(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final prompt = _plan.promptAt(_elapsed);
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return Column(
      key: const ValueKey('session'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: BfColors.inkMuted,
                  color: BfColors.accent,
                ),
              ),
              if (_plan == UrgeIntervention.breathe)
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: BfColors.accentSoft,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(duration: 4.seconds, begin: const Offset(0.7, 0.7), end: const Offset(1.1, 1.1)),
              Text(
                '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: BfColors.textPrimaryDark,
                  fontSize: 44,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BfSpacing.xxxl),
        AnimatedSwitcher(
          duration: 300.ms,
          child: Text(
            prompt,
            key: ValueKey(prompt),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: BfColors.textPrimaryDark,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: BfSpacing.sm),
        Text(
          _plan.tagline,
          style: const TextStyle(color: BfColors.textSecondaryDark),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        const Text(
          'Stay with it. The urge peaks and passes.',
          style: TextStyle(color: BfColors.textTertiaryDark, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BfSpacing.md),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context) {
    return Column(
      key: const ValueKey('completed'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const Icon(Icons.check_circle_outline, size: 72, color: BfColors.accent)
            .animate()
            .scale(duration: 500.ms, curve: Curves.easeOutBack),
        const SizedBox(height: BfSpacing.xl),
        Text(
          'You rode it out.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: BfColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: BfSpacing.sm),
        Text(
          'Urge handled with ${_plan.label.toLowerCase()}.',
          style: const TextStyle(color: BfColors.textSecondaryDark, fontSize: 16),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: BfSpacing.xl),
        Center(
          child: BfXpChip(label: '+${UrgeIntervention.xpReward} XP'),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        const Spacer(),
        BfPrimaryButton(
          label: 'Back to home',
          onPressed: _finish,
        ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: BfSpacing.md),
      ],
    );
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BfColors.inkElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BfRadius.lg)),
        title: const Text(
          'Stop early?',
          style: TextStyle(color: BfColors.textPrimaryDark, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'The urge is logged either way, but XP is only awarded when you finish the timer.',
          style: TextStyle(color: BfColors.textSecondaryDark, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop', style: TextStyle(color: BfColors.danger)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _timer?.cancel();
      final urgeId = widget.args.urgeId;
      if (urgeId != null) await context.read<UrgeProvider>().markStoppedEarly(urgeId, _plan);
      if (mounted) context.go('/');
    }
  }
}
