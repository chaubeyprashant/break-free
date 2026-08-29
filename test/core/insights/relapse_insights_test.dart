import 'package:break_free/core/insights/relapse_insights.dart';
import 'package:break_free/core/models/relapse_record.dart';
import 'package:flutter_test/flutter_test.dart';

RelapseRecord _slip(String trigger, DateTime at) => RelapseRecord(
  id: at.microsecondsSinceEpoch.toString(),
  trigger: trigger,
  timestamp: at,
);

void main() {
  group('DayWindow', () {
    test('buckets the hour of day', () {
      expect(DayWindow.forHour(7), DayWindow.morning);
      expect(DayWindow.forHour(13), DayWindow.afternoon);
      expect(DayWindow.forHour(20), DayWindow.evening);
      expect(DayWindow.forHour(23), DayWindow.night);
      expect(DayWindow.forHour(3), DayWindow.night);
    });

    test('covers every hour with exactly one window', () {
      for (var hour = 0; hour < 24; hour++) {
        expect(DayWindow.forHour(hour), isA<DayWindow>());
      }
    });
  });

  group('RelapseInsights', () {
    test('reports nothing for a user who has never slipped', () {
      final insights = RelapseInsights.from([]);

      expect(insights.totalSlips, 0);
      expect(insights.hasPatterns, isFalse);
      expect(insights.topTrigger, isNull);
      expect(insights.lastSlip, isNull);
    });

    test('withholds patterns until there is enough data', () {
      // One slip is not a pattern, and presenting it as one would be inventing
      // a story about the user.
      final insights = RelapseInsights.from([
        _slip('Stress', DateTime(2026, 8, 25, 21)),
      ]);

      expect(insights.totalSlips, 1);
      expect(insights.hasPatterns, isFalse);
      expect(insights.slipsUntilPatterns, 2);
    });

    test('finds the dominant trigger, window and weekday', () {
      // 2026-08-21 and 2026-08-28 are Fridays.
      final insights = RelapseInsights.from([
        _slip('Stress', DateTime(2026, 8, 28, 21)),
        _slip('Stress', DateTime(2026, 8, 21, 20)),
        _slip('Boredom', DateTime(2026, 8, 25, 14)),
        _slip('Stress', DateTime(2026, 8, 14, 19)),
      ]);

      expect(insights.totalSlips, 4);
      expect(insights.hasPatterns, isTrue);
      expect(insights.topTrigger, 'Stress');
      expect(insights.topTriggerCount, 3);
      expect(insights.riskiestWindow, DayWindow.evening);
      expect(insights.riskiestWindowCount, 3);
      expect(insights.riskiestWeekday, DateTime.friday);
      expect(insights.riskiestWeekdayCount, 3);
    });

    test('tracks the most recent slip regardless of list order', () {
      final insights = RelapseInsights.from([
        _slip('Boredom', DateTime(2026, 8, 10, 9)),
        _slip('Stress', DateTime(2026, 8, 28, 21)),
        _slip('Anxiety', DateTime(2026, 8, 19, 9)),
      ]);

      expect(insights.lastSlip, DateTime(2026, 8, 28, 21));
    });

    test('ignores blank triggers without dropping the slip', () {
      final insights = RelapseInsights.from([
        _slip('   ', DateTime(2026, 8, 28, 21)),
        _slip('Stress', DateTime(2026, 8, 27, 21)),
        _slip('Stress', DateTime(2026, 8, 26, 21)),
      ]);

      // The slip still counts toward totals and timing.
      expect(insights.totalSlips, 3);
      expect(insights.topTrigger, 'Stress');
      expect(insights.topTriggerCount, 2);
      expect(insights.riskiestWindowCount, 3);
    });
  });
}
