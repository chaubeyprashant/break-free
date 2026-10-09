import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/models/urge_intervention.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/urge/presentation/urge_intervention_screen.dart';
import 'package:break_free/core/providers/urge_provider.dart';

/// Two-step flow opened from the dashboard's "I have an urge" action:
/// intensity (1-10), then trigger. The completed event is persisted locally
/// through [UrgeProvider]; nothing about it affects streaks or XP.
class UrgeFlowScreen extends StatefulWidget {
  const UrgeFlowScreen({super.key});

  @override
  State<UrgeFlowScreen> createState() => _UrgeFlowScreenState();
}

class _UrgeFlowScreenState extends State<UrgeFlowScreen> {
  int _step = 0;
  int? _intensity;
  UrgeTrigger? _trigger;
  bool _saving = false;
  bool _saved = false;
  String? _savedUrgeId;

  Future<void> _save() async {
    final intensity = _intensity;
    final trigger = _trigger;
    if (intensity == null || trigger == null || _saving) return;
    setState(() => _saving = true);
    try {
      final event = await context.read<UrgeProvider>().logUrge(intensity: intensity, trigger: trigger);
      if (!mounted) return;
      setState(() {
        _saved = true;
        _savedUrgeId = event.id;
        _step = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save that. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BfColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: BfColors.textPrimaryDark,
        leading: _step == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step = 0),
              )
            : null,
        title: Text(
          _saved ? 'Ride it out' : 'Riding out the urge',
          style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.2),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BfSpacing.xl),
          child: AnimatedSwitcher(
            duration: 220.ms,
            child: switch (_step) {
              0 => _buildIntensityStep(context),
              1 => _buildTriggerStep(context),
              _ => _buildInterventionStep(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityStep(BuildContext context) {
    return Column(
      key: const ValueKey('intensity'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BfSpacing.md),
        Text(
          'How strong is it?',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: BfColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 200.ms),
        const SizedBox(height: BfSpacing.xs),
        const Text(
          '1 — barely there    ·    10 — overwhelming',
          style: TextStyle(color: BfColors.textSecondaryDark, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BfSpacing.xxxl),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: BfSpacing.sm,
          runSpacing: BfSpacing.sm,
          children: [
            for (int i = UrgeEvent.minIntensity; i <= UrgeEvent.maxIntensity; i++)
              _IntensityDot(
                value: i,
                selected: _intensity == i,
                onTap: () => setState(() => _intensity = i),
              ),
          ],
        ),
        const Spacer(),
        BfPrimaryButton(
          label: 'Next',
          onPressed: _intensity == null ? null : () => setState(() => _step = 1),
        ),
        const SizedBox(height: BfSpacing.xs),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel', style: TextStyle(color: BfColors.textTertiaryDark)),
        ),
      ],
    );
  }

  Widget _buildTriggerStep(BuildContext context) {
    return Column(
      key: const ValueKey('trigger'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BfSpacing.xl),
        Text(
          'What triggered it?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: BfColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(),
        const SizedBox(height: BfSpacing.xxxl),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: BfSpacing.sm,
          runSpacing: BfSpacing.sm,
          children: UrgeTrigger.values.map((trigger) {
            final isSelected = _trigger == trigger;
            return Material(
              color: isSelected ? BfColors.accent : BfColors.inkSoft,
              borderRadius: BorderRadius.circular(BfRadius.md),
              child: InkWell(
                onTap: () => setState(() => _trigger = trigger),
                borderRadius: BorderRadius.circular(BfRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BfSpacing.md, vertical: BfSpacing.sm),
                  child: Text(
                    trigger.label,
                    style: TextStyle(
                      color: isSelected ? BfColors.textPrimaryDark : BfColors.textSecondaryDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Spacer(),
        BfPrimaryButton(
          label: _saving ? 'Saving...' : 'Save urge',
          onPressed: _trigger == null || _saving ? null : _save,
        ),
        const SizedBox(height: BfSpacing.xs),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Cancel', style: TextStyle(color: BfColors.textTertiaryDark)),
        ),
      ],
    );
  }

  Widget _buildInterventionStep(BuildContext context) {
    return Column(
      key: const ValueKey('intervention'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BfSpacing.xs),
        Text(
          'Logged.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: BfColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BfSpacing.xs),
        Text(
          'Intensity ${_intensity ?? '—'}  ·  ${_trigger?.label ?? '—'}\n'
          'Choose how you want to ride this out. +${UrgeIntervention.xpReward} XP when you finish.',
          style: const TextStyle(color: BfColors.textSecondaryDark, fontSize: 15, height: 1.45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BfSpacing.xl),
        for (final (index, plan) in UrgeIntervention.values.indexed) ...[
          _InterventionCard(
            plan: plan,
            icon: switch (plan) {
              UrgeIntervention.breathe => Icons.air_rounded,
              UrgeIntervention.move => Icons.directions_run_rounded,
              UrgeIntervention.distract => Icons.psychology_alt_rounded,
            },
            onTap: () => _startIntervention(plan),
          ).animate().fadeIn(delay: (80 * index).ms),
          const SizedBox(height: BfSpacing.sm),
        ],
        TextButton.icon(
          onPressed: () => context.pushReplacement('/replace'),
          icon: const Icon(Icons.swap_horiz_rounded, color: BfColors.textSecondaryDark, size: 20),
          label: const Text(
            'More activities, 2 to 30 minutes',
            style: TextStyle(color: BfColors.textSecondaryDark, fontSize: 15),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Not now', style: TextStyle(color: BfColors.textTertiaryDark)),
        ),
      ],
    );
  }

  void _startIntervention(UrgeIntervention plan) {
    final urgeId = _savedUrgeId;
    if (urgeId == null) return;
    context.pushReplacement(
      '/urge/intervention',
      extra: UrgeInterventionArgs(urgeId: urgeId, intervention: plan),
    );
  }
}

class _IntensityDot extends StatelessWidget {
  const _IntensityDot({required this.value, required this.selected, required this.onTap});

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = (value - 1) / 9;
    final color = Color.lerp(BfColors.accent, BfColors.danger, t)!;
    return Material(
      color: selected ? color : BfColors.inkSoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: selected ? BfColors.textPrimaryDark : BfColors.textSecondaryDark,
                fontSize: 20,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InterventionCard extends StatelessWidget {
  const _InterventionCard({required this.plan, required this.icon, required this.onTap});

  final UrgeIntervention plan;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BfColors.inkElevated,
      borderRadius: BorderRadius.circular(BfRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BfRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(BfSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(BfSpacing.sm),
                decoration: const BoxDecoration(color: BfColors.accentSoft, shape: BoxShape.circle),
                child: Icon(icon, color: BfColors.accent, size: 24),
              ),
              const SizedBox(width: BfSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.label,
                      style: const TextStyle(
                        color: BfColors.textPrimaryDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: BfSpacing.xxs),
                    Text(
                      plan.tagline,
                      style: const TextStyle(color: BfColors.textSecondaryDark, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BfColors.textTertiaryDark, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
