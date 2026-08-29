import 'package:break_free/core/models/relapse_record.dart';

/// Rough part of the day a slip happened in.
enum DayWindow {
  morning('Mornings', 'around 5am–12pm'),
  afternoon('Afternoons', 'around 12pm–5pm'),
  evening('Evenings', 'around 5pm–10pm'),
  night('Late nights', 'around 10pm–5am');

  const DayWindow(this.label, this.range);

  final String label;
  final String range;

  static DayWindow forHour(int hour) {
    if (hour >= 5 && hour < 12) return DayWindow.morning;
    if (hour >= 12 && hour < 17) return DayWindow.afternoon;
    if (hour >= 17 && hour < 22) return DayWindow.evening;
    return DayWindow.night;
  }
}

/// What the user's own logged slips say about when and why they happen.
///
/// Everything here is derived on-device from data the user entered by hand.
class RelapseInsights {
  /// Below this, counts are just noise — announcing "your riskiest day is
  /// Tuesday" off a single slip would be inventing a pattern.
  static const int minimumForPatterns = 3;

  final int totalSlips;
  final String? topTrigger;
  final int topTriggerCount;
  final DayWindow? riskiestWindow;
  final int riskiestWindowCount;
  final int? riskiestWeekday;
  final int riskiestWeekdayCount;
  final DateTime? lastSlip;

  const RelapseInsights({
    required this.totalSlips,
    this.topTrigger,
    this.topTriggerCount = 0,
    this.riskiestWindow,
    this.riskiestWindowCount = 0,
    this.riskiestWeekday,
    this.riskiestWeekdayCount = 0,
    this.lastSlip,
  });

  bool get hasPatterns => totalSlips >= minimumForPatterns;

  /// How many more slips before patterns are worth showing.
  int get slipsUntilPatterns =>
      (minimumForPatterns - totalSlips).clamp(0, minimumForPatterns);

  factory RelapseInsights.from(List<RelapseRecord> records) {
    if (records.isEmpty) return const RelapseInsights(totalSlips: 0);

    final triggers = <String, int>{};
    final windows = <DayWindow, int>{};
    final weekdays = <int, int>{};
    DateTime? lastSlip;

    for (final record in records) {
      final trigger = record.trigger.trim();
      if (trigger.isNotEmpty) {
        triggers[trigger] = (triggers[trigger] ?? 0) + 1;
      }

      final window = DayWindow.forHour(record.timestamp.hour);
      windows[window] = (windows[window] ?? 0) + 1;
      weekdays[record.timestamp.weekday] =
          (weekdays[record.timestamp.weekday] ?? 0) + 1;

      if (lastSlip == null || record.timestamp.isAfter(lastSlip)) {
        lastSlip = record.timestamp;
      }
    }

    final topTrigger = _highest(triggers);
    final topWindow = _highest(windows);
    final topWeekday = _highest(weekdays);

    return RelapseInsights(
      totalSlips: records.length,
      topTrigger: topTrigger?.key,
      topTriggerCount: topTrigger?.value ?? 0,
      riskiestWindow: topWindow?.key,
      riskiestWindowCount: topWindow?.value ?? 0,
      riskiestWeekday: topWeekday?.key,
      riskiestWeekdayCount: topWeekday?.value ?? 0,
      lastSlip: lastSlip,
    );
  }

  /// Highest count wins. Ties break on insertion order, which follows the
  /// records themselves, so the same input always gives the same answer.
  static MapEntry<K, int>? _highest<K>(Map<K, int> counts) {
    MapEntry<K, int>? best;
    for (final entry in counts.entries) {
      if (best == null || entry.value > best.value) best = entry;
    }
    return best;
  }
}
