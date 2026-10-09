import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/journal_repository.dart';
import 'package:break_free/core/models/activity_insights.dart';
import 'package:break_free/core/models/habit.dart';
import 'package:break_free/core/models/journal_entry.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/providers/journal_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('JournalEntry', () {
    test('round-trips through json with optional fields', () {
      final entry = JournalEntry(
        id: 'j1',
        date: DateTime(2026, 10, 7, 15, 0),
        note: 'Felt stronger',
        moodRating: 4,
        urgeIntensity: 6,
        triggersIdentified: const ['Stress'],
        habitId: 'h1',
        copingMethod: 'Breathe',
      );
      final restored = JournalEntry.fromJson(entry.toJson());
      expect(restored, isNotNull);
      expect(restored!.note, 'Felt stronger');
      expect(restored.habitId, 'h1');
      expect(restored.copingMethod, 'Breathe');
      expect(restored.urgeIntensity, 6);
    });

    test('rejects corrupt maps', () {
      expect(JournalEntry.fromMap({'id': 1, 'date': '2026-01-01'}), isNull);
      expect(JournalEntry.fromMap({'id': 'x', 'date': 'nope'}), isNull);
    });
  });

  group('JournalRepository / Provider', () {
    test('create edit delete persist across reload', () async {
      final repo = JournalRepository();
      final provider = JournalProvider(repo);
      await Future<void>.delayed(Duration.zero);
      await provider.reload();

      final created = await provider.create(
        note: 'Hello',
        moodRating: 3,
        urgeIntensity: 5,
        triggers: const ['Boredom'],
      );
      expect(provider.entries, hasLength(1));

      await provider.update(created.copyWith(note: 'Updated'));
      expect(provider.entries.first.note, 'Updated');

      await provider.delete(created.id);
      expect(provider.entries, isEmpty);

      final reloaded = await repo.getEntries();
      expect(reloaded, isEmpty);
    });
  });

  group('ActivityInsights', () {
    test('computes triggers, hours, managed count, and week deltas', () {
      final now = DateTime(2026, 10, 7, 18);
      final urges = [
        UrgeEvent(id: '1', timestamp: DateTime(2026, 10, 6, 22), intensity: 8, trigger: UrgeTrigger.nighttime),
        UrgeEvent(
          id: '2',
          timestamp: DateTime(2026, 10, 5, 22),
          intensity: 4,
          trigger: UrgeTrigger.stress,
          handledAt: DateTime(2026, 10, 5, 22, 5),
          outcome: UrgeOutcome.rodeItOut,
        ),
        UrgeEvent(id: '3', timestamp: DateTime(2026, 9, 28, 10), intensity: 3, trigger: UrgeTrigger.boredom),
      ];
      final habits = [
        Habit(
          id: 'h',
          title: 'Porn',
          iconPath: 'x',
          startDate: DateTime(2026, 9, 1),
          relapseDates: [DateTime(2026, 10, 1)],
        ),
      ];
      final insights = ActivityInsights.compute(
        urges: urges,
        habits: habits,
        journal: const [],
        now: now,
        periodDays: 7,
      );

      expect(insights.urgeTotal, 3);
      expect(insights.urgesManaged, 1);
      expect(insights.averageUrgeIntensity, closeTo(5.0, 0.01));
      expect(insights.mostCommonTriggers.first.key, isNotEmpty);
      expect(insights.difficultHours.first.key, 22);
      expect(insights.currentPeriodUrgeCount, 2);
      expect(insights.previousPeriodUrgeCount, 1);
      expect(insights.longestStreakDays, greaterThan(0));
    });
  });
}
