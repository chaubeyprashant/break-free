import 'package:break_free/core/models/habit.dart';
import 'package:break_free/core/models/journal_entry.dart';
import 'package:break_free/core/models/urge_event.dart';

/// Rule-based insights from local urge, relapse, streak, and journal data.
/// Not AI — every figure is a count, average, or comparison over activity.
class ActivityInsights {
  const ActivityInsights({
    required this.mostCommonTriggers,
    required this.difficultHours,
    required this.averageUrgeIntensity,
    required this.urgesManaged,
    required this.urgeTotal,
    required this.relapseCount,
    required this.currentBestStreakDays,
    required this.longestStreakDays,
    required this.currentPeriodUrgeCount,
    required this.previousPeriodUrgeCount,
    required this.currentPeriodManaged,
    required this.previousPeriodManaged,
    required this.currentPeriodRelapses,
    required this.previousPeriodRelapses,
    required this.journalEntriesInPeriod,
    required this.periodDays,
  });

  /// Trigger label → count, sorted descending (top triggers first).
  final List<MapEntry<String, int>> mostCommonTriggers;

  /// Hour of day (0–23) → count for difficult times, sorted descending.
  final List<MapEntry<int, int>> difficultHours;

  final double? averageUrgeIntensity;
  final int urgesManaged;
  final int urgeTotal;
  final int relapseCount;

  /// Best *current* streak among habits.
  final int currentBestStreakDays;

  /// Longest historical streak reconstructed from start + relapse gaps.
  final int longestStreakDays;

  final int currentPeriodUrgeCount;
  final int previousPeriodUrgeCount;
  final int currentPeriodManaged;
  final int previousPeriodManaged;
  final int currentPeriodRelapses;
  final int previousPeriodRelapses;
  final int journalEntriesInPeriod;
  final int periodDays;

  /// Negative means fewer urges this period (improvement for urge count).
  int get urgeCountDelta => currentPeriodUrgeCount - previousPeriodUrgeCount;

  /// Positive means more successfully managed urges.
  int get managedDelta => currentPeriodManaged - previousPeriodManaged;

  int get relapseDelta => currentPeriodRelapses - previousPeriodRelapses;

  static ActivityInsights compute({
    required List<UrgeEvent> urges,
    required List<Habit> habits,
    required List<JournalEntry> journal,
    DateTime? now,
    int periodDays = 7,
  }) {
    final n = now ?? DateTime.now();
    final periodStart = DateTime(n.year, n.month, n.day).subtract(Duration(days: periodDays - 1));
    final previousStart = periodStart.subtract(Duration(days: periodDays));

    final triggerCounts = <String, int>{};
    final hourCounts = <int, int>{};
    var intensitySum = 0;
    var intensityN = 0;
    var managed = 0;

    for (final u in urges) {
      triggerCounts[u.trigger.label] = (triggerCounts[u.trigger.label] ?? 0) + 1;
      hourCounts[u.timestamp.hour] = (hourCounts[u.timestamp.hour] ?? 0) + 1;
      intensitySum += u.intensity;
      intensityN++;
      if (u.outcome == UrgeOutcome.rodeItOut || u.isHandled) managed++;
    }

    // Journal triggers supplement urge triggers (no double-count of same event).
    for (final j in journal) {
      for (final t in j.triggersIdentified) {
        if (t.trim().isEmpty) continue;
        triggerCounts[t] = (triggerCounts[t] ?? 0) + 1;
      }
      if (j.urgeIntensity > 0) {
        intensitySum += j.urgeIntensity.round();
        intensityN++;
      }
    }

    final sortedTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var relapseTotal = 0;
    var currentBest = 0;
    var longest = 0;
    for (final h in habits) {
      relapseTotal += h.relapseDates.length;
      if (h.currentStreakDays > currentBest) currentBest = h.currentStreakDays;
      longest = _max(longest, _longestStreakDays(h, n));
      if (h.currentStreakDays > longest) longest = h.currentStreakDays;
    }

    bool inRange(DateTime t, DateTime start, DateTime end) =>
        !t.isBefore(start) && t.isBefore(end);

    final periodEnd = periodStart.add(Duration(days: periodDays));
    final prevEnd = periodStart;

    final curUrges = urges.where((u) => inRange(u.timestamp, periodStart, periodEnd)).toList();
    final prevUrges = urges.where((u) => inRange(u.timestamp, previousStart, prevEnd)).toList();
    final curManaged = curUrges.where((u) => u.outcome == UrgeOutcome.rodeItOut || u.isHandled).length;
    final prevManaged = prevUrges.where((u) => u.outcome == UrgeOutcome.rodeItOut || u.isHandled).length;

    int countRelapses(DateTime start, DateTime end) {
      var c = 0;
      for (final h in habits) {
        for (final d in h.relapseDates) {
          if (inRange(d, start, end)) c++;
        }
      }
      return c;
    }

    final journalInPeriod = journal.where((j) => inRange(j.date, periodStart, periodEnd)).length;

    return ActivityInsights(
      mostCommonTriggers: sortedTriggers,
      difficultHours: sortedHours,
      averageUrgeIntensity: intensityN == 0 ? null : intensitySum / intensityN,
      urgesManaged: managed,
      urgeTotal: urges.length,
      relapseCount: relapseTotal,
      currentBestStreakDays: currentBest,
      longestStreakDays: longest,
      currentPeriodUrgeCount: curUrges.length,
      previousPeriodUrgeCount: prevUrges.length,
      currentPeriodManaged: curManaged,
      previousPeriodManaged: prevManaged,
      currentPeriodRelapses: countRelapses(periodStart, periodEnd),
      previousPeriodRelapses: countRelapses(previousStart, prevEnd),
      journalEntriesInPeriod: journalInPeriod,
      periodDays: periodDays,
    );
  }

  static int _max(int a, int b) => a > b ? a : b;

  /// Longest clean gap between start and successive relapses (and now).
  static int _longestStreakDays(Habit habit, DateTime now) {
    final points = <DateTime>[habit.startDate, ...habit.relapseDates, now]
      ..sort();
    var best = 0;
    for (var i = 1; i < points.length; i++) {
      final days = points[i].difference(points[i - 1]).inDays;
      if (days > best) best = days;
    }
    return best;
  }

  static String formatHour(int hour) {
    final h = hour % 24;
    final suffix = h < 12 ? 'AM' : 'PM';
    final display = h % 12 == 0 ? 12 : h % 12;
    return '$display:00 $suffix';
  }
}
