import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/activity_insights.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/journal_provider.dart';
import 'package:break_free/core/providers/urge_provider.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/async_state_view.dart';
import 'package:break_free/core/widgets/bf_components.dart';

/// Rule-based activity insights. Explicitly labeled — not AI.
class JournalInsightsPanel extends StatelessWidget {
  const JournalInsightsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final urges = context.watch<UrgeProvider>().urges;
    final habits = context.watch<HabitProvider>().habits;
    final journal = context.watch<JournalProvider>();

    if (!journal.isLoaded) {
      return const AsyncLoadingView(message: 'Calculating insights…');
    }

    final hasData = urges.isNotEmpty || habits.isNotEmpty || journal.entries.isNotEmpty;
    if (!hasData) {
      return const AsyncEmptyView(
        icon: Icons.insights_outlined,
        title: 'No activity yet',
        subtitle: 'Log urges, check in, or write a journal entry to see insights based on your activity.',
      );
    }

    final insights = ActivityInsights.compute(
      urges: urges,
      habits: habits,
      journal: journal.entries,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.huge),
      children: [
        Text(
          'Based on your activity — calculated on this device, not AI.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: BfSpacing.xl),
        const BfSectionLabel('Your week'),
        const SizedBox(height: BfSpacing.md),
        Row(
          children: [
            Expanded(
              child: BfMetric(
                value: '${insights.currentPeriodUrgeCount}',
                label: 'Urges logged',
                align: TextAlign.center,
              ),
            ),
            Expanded(
              child: BfMetric(
                value: '${insights.currentPeriodManaged}',
                label: 'Managed',
                align: TextAlign.center,
              ),
            ),
            Expanded(
              child: BfMetric(
                value: '${insights.currentPeriodRelapses}',
                label: 'Slips',
                align: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: BfSpacing.sm),
        Text(
          [
            _deltaLabel(insights.urgeCountDelta, invertGood: true, noun: 'urges'),
            _deltaLabel(insights.managedDelta, noun: 'managed'),
          ].whereType<String>().join('  ·  '),
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BfSpacing.sectionGap),
        const BfSectionLabel('Streaks'),
        const SizedBox(height: BfSpacing.sm),
        BfListRow(
          title: 'Current best',
          trailing: Text('${insights.currentBestStreakDays} days'),
        ),
        BfListRow(
          title: 'Best ever',
          trailing: Text('${insights.longestStreakDays} days'),
          showDivider: false,
        ),
        const SizedBox(height: BfSpacing.sectionGap),
        const BfSectionLabel('Patterns'),
        const SizedBox(height: BfSpacing.sm),
        if (insights.mostCommonTriggers.isEmpty)
          Text('Not enough trigger data yet.', style: Theme.of(context).textTheme.bodyMedium)
        else
          Text(
            '${insights.mostCommonTriggers.first.key} is your most common trigger.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        const SizedBox(height: BfSpacing.md),
        if (insights.difficultHours.isNotEmpty)
          Text(
            'Stronger urges often land around ${ActivityInsights.formatHour(insights.difficultHours.first.key)}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const SizedBox(height: BfSpacing.lg),
        if (insights.averageUrgeIntensity != null)
          BfListRow(
            title: 'Average urge intensity',
            trailing: Text(insights.averageUrgeIntensity!.toStringAsFixed(1)),
            showDivider: false,
          ),
      ],
    );
  }

  static String? _deltaLabel(int delta, {bool invertGood = false, required String noun}) {
    if (delta == 0) return null;
    final improved = invertGood ? delta < 0 : delta > 0;
    final arrow = delta > 0 ? '↑' : '↓';
    return '$arrow${delta.abs()} $noun${improved ? '' : ''}';
  }
}
