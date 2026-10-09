import 'package:break_free/core/models/urge_event.dart';

/// A time-of-day period in which the user's own logged urges cluster.
///
/// This is a description of recorded behaviour, nothing more: "N of your M
/// logged urges happened between X and Y". It is computed deterministically
/// from the event list and makes no claims about causes.
class DangerWindow {
  const DangerWindow({
    required this.startHour,
    required this.count,
    required this.total,
  });

  /// Start of the 2-hour bucket, 0..22 in local time.
  final int startHour;

  /// Urges inside the bucket.
  final int count;

  /// Urges considered in total.
  final int total;

  int get endHour => (startHour + DangerWindowAnalyzer.bucketHours) % 24;

  double get share => count / total;

  /// "10 PM–12 AM" style label.
  String get label => '${formatHour(startHour)}–${formatHour(endHour)}';

  static String formatHour(int hour) {
    final h = hour % 24;
    if (h == 0) return '12 AM';
    if (h == 12) return '12 PM';
    return h < 12 ? '$h AM' : '${h - 12} PM';
  }

  /// Next moment the window starts, strictly after [from].
  DateTime nextStart(DateTime from) {
    var start = DateTime(from.year, from.month, from.day, startHour);
    if (!start.isAfter(from)) start = start.add(const Duration(days: 1));
    return start;
  }

  bool contains(DateTime time) {
    final bucket = (time.hour ~/ DangerWindowAnalyzer.bucketHours) * DangerWindowAnalyzer.bucketHours;
    return bucket == startHour;
  }
}

class DangerWindowAnalyzer {
  static const int bucketHours = 2;
  static const int bucketCount = 24 ~/ bucketHours;

  /// Fewer logged urges than this and no pattern is reported: one or two
  /// events say nothing about a period.
  static const int minimumEvents = 3;

  /// The busiest bucket must hold at least this many urges.
  static const int minimumInWindow = 2;

  /// Returns the busiest 2-hour period, or null when there is not enough
  /// data to call it a pattern. Ties go to the earlier period of the day.
  static DangerWindow? analyze(List<UrgeEvent> events) {
    if (events.length < minimumEvents) return null;

    final counts = List<int>.filled(bucketCount, 0);
    for (final e in events) {
      counts[e.timestamp.hour ~/ bucketHours]++;
    }

    var best = 0;
    for (var i = 1; i < bucketCount; i++) {
      if (counts[i] > counts[best]) best = i;
    }
    if (counts[best] < minimumInWindow) return null;

    return DangerWindow(startHour: best * bucketHours, count: counts[best], total: events.length);
  }
}
