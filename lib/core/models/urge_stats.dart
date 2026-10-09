import 'package:break_free/core/models/urge_event.dart';

/// Time windows offered by the history screen.
enum UrgeRange {
  today('Today'),
  week('7 days'),
  month('30 days'),
  all('All time');

  const UrgeRange(this.label);
  final String label;

  /// Earliest timestamp included, or null for everything.
  DateTime? startFrom(DateTime now) {
    final midnight = DateTime(now.year, now.month, now.day);
    return switch (this) {
      UrgeRange.today => midnight,
      UrgeRange.week => midnight.subtract(const Duration(days: 6)),
      UrgeRange.month => midnight.subtract(const Duration(days: 29)),
      UrgeRange.all => null,
    };
  }
}

/// Summary numbers computed from real events only. Fields are null when
/// there is nothing to compute from, so the UI can show a dash instead of a
/// made-up zero.
class UrgeStats {
  const UrgeStats._({
    required this.events,
    required this.total,
    required this.handled,
    required this.mostCommonTrigger,
    required this.averageIntensity,
  });

  /// Events inside the range, newest first.
  final List<UrgeEvent> events;
  final int total;
  final int handled;
  final UrgeTrigger? mostCommonTrigger;
  final double? averageIntensity;

  double? get handledShare => total == 0 ? null : handled / total;

  static UrgeStats compute(List<UrgeEvent> all, UrgeRange range, {DateTime? now}) {
    final start = range.startFrom(now ?? DateTime.now());
    final inRange = all.where((e) => start == null || !e.timestamp.isBefore(start)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    UrgeTrigger? topTrigger;
    if (inRange.isNotEmpty) {
      final counts = <UrgeTrigger, int>{};
      for (final e in inRange) {
        counts[e.trigger] = (counts[e.trigger] ?? 0) + 1;
      }
      // Highest count wins; ties go to the trigger listed first in the enum.
      for (final t in UrgeTrigger.values) {
        final c = counts[t];
        if (c != null && (topTrigger == null || c > counts[topTrigger]!)) topTrigger = t;
      }
    }

    return UrgeStats._(
      events: inRange,
      total: inRange.length,
      handled: inRange.where((e) => e.isHandled).length,
      mostCommonTrigger: topTrigger,
      averageIntensity: inRange.isEmpty
          ? null
          : inRange.fold<int>(0, (sum, e) => sum + e.intensity) / inRange.length,
    );
  }
}
