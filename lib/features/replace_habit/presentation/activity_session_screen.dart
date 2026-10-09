import 'dart:async';
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

/// Timed replacement activity. Completion awards tier XP via GameProvider.
class ActivitySessionScreen extends StatefulWidget {
  const ActivitySessionScreen({super.key, required this.activity});

  final ReplacementActivity activity;

  @override
  State<ActivitySessionScreen> createState() => _ActivitySessionScreenState();
}

class _ActivitySessionScreenState extends State<ActivitySessionScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _completing = false;
  bool _completed = false;
  bool _leveledUp = false;

  ReplacementActivity get _activity => widget.activity;
  Duration get _remaining => _activity.tier.duration - _elapsed;
  double get _progress =>
      (_elapsed.inMilliseconds / _activity.tier.duration.inMilliseconds).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (_completing) return;
    setState(() => _elapsed += const Duration(milliseconds: 500));
    if (_elapsed >= _activity.tier.duration) {
      timer.cancel();
      _complete();
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    _completing = true;
    final xp = _activity.tier.xpReward;
    await context.read<ActivityProvider>().recordCompletion(_activity, xpAwarded: xp);
    if (!mounted) return;
    final leveledUp = await context.read<GameProvider>().addXp(xp, coinBonus: _activity.tier.coinReward);
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
    context.pop();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop early?'),
        content: const Text('Nothing is recorded unless you finish the timer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Stop', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _timer?.cancel();
      context.pop();
    }
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
          title: Text(_completed ? '' : _activity.title),
          actions: [
            if (!_completed)
              TextButton(
                onPressed: _confirmLeave,
                child: const Text('Stop'),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BfSpacing.xl),
            child: _completed ? _buildCompleted(context) : _buildSession(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSession(BuildContext context) {
    final prompt = _activity.promptAt(_elapsed) ?? _activity.description;
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          '$minutes:${seconds.toString().padLeft(2, '0')}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: BfColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: BfSpacing.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 3,
            backgroundColor: BfColors.accentSoft,
            color: BfColors.accent,
          ),
        ),
        const SizedBox(height: BfSpacing.xxl),
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: BfColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: BfSpacing.sm),
        Text(
          '${_activity.tier.label}  ·  +${_activity.tier.xpReward} XP when done',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BfColors.textSecondaryDark),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          'Done',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: BfColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: BfSpacing.sm),
        Text(
          '${_activity.title}  ·  ${_activity.tier.label}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: BfColors.textSecondaryDark),
        ),
        const SizedBox(height: BfSpacing.lg),
        Text(
          '+${_activity.tier.xpReward} XP',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: BfColors.accent),
        ),
        const Spacer(),
        BfPrimaryButton(label: 'Continue', onPressed: _finish),
        const SizedBox(height: BfSpacing.md),
      ],
    );
  }
}
