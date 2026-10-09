import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/models/urge_stats.dart';
import 'package:break_free/core/providers/urge_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/danger_window/presentation/danger_window_card.dart';

/// Offline history of logged urges with range filters and summaries. Every
/// number comes from [UrgeStats.compute] over the locally stored events.
class UrgeHistoryScreen extends StatefulWidget {
  const UrgeHistoryScreen({super.key});

  @override
  State<UrgeHistoryScreen> createState() => _UrgeHistoryScreenState();
}

class _UrgeHistoryScreenState extends State<UrgeHistoryScreen> {
  UrgeRange _range = UrgeRange.week;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Urge history')),
      body: Consumer<UrgeProvider>(
        builder: (context, provider, _) {
          final stats = UrgeStats.compute(provider.urges, _range);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.xxs, BfSpacing.screenH, BfSpacing.xs),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<UrgeRange>(
                    segments: [
                      for (final r in UrgeRange.values) ButtonSegment(value: r, label: Text(r.label)),
                    ],
                    selected: {_range},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _range = s.first),
                  ),
                ),
              ),
              Expanded(
                child: stats.total == 0
                    ? _EmptyState(range: _range)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          BfSpacing.screenH,
                          BfSpacing.xs,
                          BfSpacing.screenH,
                          BfSpacing.xl,
                        ),
                        children: [
                          _SummaryGrid(stats: stats),
                          const SizedBox(height: BfSpacing.sm),
                          const DangerWindowCard(),
                          const SizedBox(height: BfSpacing.lg),
                          const BfSectionLabel('Entries'),
                          const SizedBox(height: BfSpacing.xs),
                          for (final (index, event) in stats.events.indexed)
                            _UrgeTile(event: event)
                                .animate()
                                .fadeIn(delay: (40 * index).ms)
                                .slideY(begin: 0.05, end: 0),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});
  final UrgeStats stats;

  @override
  Widget build(BuildContext context) {
    final share = stats.handledShare;
    return GridView.extent(
      maxCrossAxisExtent: 260,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: BfSpacing.sm,
      crossAxisSpacing: BfSpacing.sm,
      childAspectRatio: 1.6,
      children: [
        _StatTile(label: 'Total urges', value: '${stats.total}', icon: Icons.bolt_rounded),
        _StatTile(
          label: 'Handled',
          value: '${stats.handled}',
          detail: share == null ? null : '${(share * 100).round()}%',
          icon: Icons.check_circle_rounded,
        ),
        _StatTile(
          label: 'Top trigger',
          value: stats.mostCommonTrigger?.label ?? '–',
          icon: Icons.flash_on_rounded,
          small: true,
        ),
        _StatTile(
          label: 'Avg intensity',
          value: stats.averageIntensity == null ? '–' : stats.averageIntensity!.toStringAsFixed(1),
          detail: '/ 10',
          icon: Icons.speed_rounded,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, this.detail, this.small = false});
  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(BfSpacing.md),
      decoration: BoxDecoration(
        color: dark ? BfColors.inkElevated : BfColors.paperElevated,
        borderRadius: BorderRadius.circular(BfRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: BfColors.accent),
              const SizedBox(width: BfSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: small ? 18 : 24,
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(width: BfSpacing.xs),
                Text(
                  detail!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UrgeTile extends StatelessWidget {
  const _UrgeTile({required this.event});
  final UrgeEvent event;

  @override
  Widget build(BuildContext context) {
    final (outcomeColor, outcomeIcon) = switch (event.outcome) {
      UrgeOutcome.rodeItOut => (BfColors.success, Icons.check_circle_rounded),
      UrgeOutcome.stoppedEarly => (BfColors.warning, Icons.pause_circle_rounded),
      UrgeOutcome.unresolved => (
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
          Icons.radio_button_unchecked_rounded,
        ),
    };
    final intensityT = (event.intensity - 1) / 9;
    final intensityColor = Color.lerp(BfColors.accent, BfColors.danger, intensityT)!;
    final intervention = event.intervention;
    final outcomeText = switch (event.outcome) {
      UrgeOutcome.rodeItOut => 'Rode it out with ${intervention?.label.toLowerCase() ?? 'an intervention'}',
      UrgeOutcome.stoppedEarly => 'Started ${intervention?.label.toLowerCase() ?? 'an intervention'}, stopped early',
      UrgeOutcome.unresolved => 'No intervention completed',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: BfSpacing.sm),
      child: BfSurface(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: intensityColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${event.intensity}',
                  style: TextStyle(color: intensityColor, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: BfSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.trigger.label, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEE, d MMM · h:mm a').format(event.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: BfSpacing.xs),
                  Row(
                    children: [
                      Icon(outcomeIcon, size: 14, color: outcomeColor),
                      const SizedBox(width: BfSpacing.xs),
                      Expanded(
                        child: Text(
                          outcomeText,
                          style: TextStyle(fontSize: 13, color: outcomeColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.range});
  final UrgeRange range;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BfEmptyState(
        title: range == UrgeRange.all ? 'No urges logged yet' : 'No urges logged in this period',
        body: 'Tap “I have an urge” on Home when one shows up. Everything stays on this device.',
      ),
    );
  }
}
