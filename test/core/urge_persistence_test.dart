import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/urge_repository.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/models/urge_intervention.dart';
import 'package:break_free/core/models/urge_stats.dart';
import 'package:break_free/core/providers/urge_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UrgeEvent', () {
    test('round-trips through json', () {
      final event = UrgeEvent(
        id: 'a1',
        timestamp: DateTime(2026, 9, 28, 22, 15),
        intensity: 7,
        trigger: UrgeTrigger.nighttime,
      );

      final restored = UrgeEvent.fromJson(event.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, 'a1');
      expect(restored.timestamp, DateTime(2026, 9, 28, 22, 15));
      expect(restored.intensity, 7);
      expect(restored.trigger, UrgeTrigger.nighttime);
    });

    test('rejects out-of-range intensity and unknown triggers', () {
      expect(UrgeEvent.fromMap({'id': 'x', 'timestamp': '2026-01-01T00:00:00', 'intensity': 0, 'trigger': 'stress'}), isNull);
      expect(UrgeEvent.fromMap({'id': 'x', 'timestamp': '2026-01-01T00:00:00', 'intensity': 11, 'trigger': 'stress'}), isNull);
      expect(UrgeEvent.fromMap({'id': 'x', 'timestamp': '2026-01-01T00:00:00', 'intensity': 5, 'trigger': 'hunger'}), isNull);
      expect(UrgeEvent.fromMap({'id': 'x', 'timestamp': 'not a date', 'intensity': 5, 'trigger': 'stress'}), isNull);
    });

    test('offers the eight required triggers in order', () {
      expect(
        UrgeTrigger.values.map((t) => t.label).toList(),
        ['Stress', 'Boredom', 'Loneliness', 'Anger', 'Social media', 'Nighttime', 'Environment', 'Other'],
      );
    });
  });

  group('UrgeRepository', () {
    test('starts empty', () async {
      expect(await UrgeRepository().getUrges(), isEmpty);
    });

    test('persists added urges across repository instances', () async {
      final first = UrgeEvent(id: '1', timestamp: DateTime(2026, 9, 28, 9), intensity: 3, trigger: UrgeTrigger.boredom);
      final second = UrgeEvent(id: '2', timestamp: DateTime(2026, 9, 28, 21), intensity: 9, trigger: UrgeTrigger.stress);

      await UrgeRepository().addUrge(first);
      await UrgeRepository().addUrge(second);

      final stored = await UrgeRepository().getUrges();
      expect(stored.map((e) => e.id), ['1', '2']);
      expect(stored.last.intensity, 9);
      expect(stored.last.trigger, UrgeTrigger.stress);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(UrgeRepository.urgesKey), isNotNull);
    });

    test('skips corrupt entries instead of losing the whole history', () async {
      SharedPreferences.setMockInitialValues({
        UrgeRepository.urgesKey:
            '[{"id":"ok","timestamp":"2026-09-28T10:00:00.000","intensity":4,"trigger":"anger"},{"id":"bad","intensity":99}]',
      });

      final stored = await UrgeRepository().getUrges();

      expect(stored.length, 1);
      expect(stored.single.id, 'ok');
    });
  });

  group('UrgeProvider', () {
    test('logUrge stores the event and exposes it', () async {
      final provider = UrgeProvider(UrgeRepository());
      await Future<void>.delayed(Duration.zero); // let the initial load finish

      final event = await provider.logUrge(intensity: 6, trigger: UrgeTrigger.socialMedia);

      expect(provider.urges.map((e) => e.id), [event.id]);
      expect(provider.urgesToday, 1);
      expect((await UrgeRepository().getUrges()).single.trigger, UrgeTrigger.socialMedia);
    });
  });

  group('UrgeIntervention', () {
    test('every plan runs between 60 and 120 seconds', () {
      for (final plan in UrgeIntervention.values) {
        expect(plan.duration.inSeconds, inInclusiveRange(60, 120), reason: plan.label);
        expect(plan.prompts, isNotEmpty, reason: plan.label);
      }
    });

    test('offers Breathe, Move and Distract in order', () {
      expect(UrgeIntervention.values.map((i) => i.label).toList(), ['Breathe', 'Move', 'Distract']);
    });

    test('prompts cycle with elapsed time', () {
      const move = UrgeIntervention.move;
      expect(move.promptAt(Duration.zero), move.prompts[0]);
      expect(move.promptAt(const Duration(seconds: 15)), move.prompts[1]);
      expect(move.promptAt(const Duration(seconds: 59)), move.prompts[3]);
      expect(UrgeIntervention.breathe.promptAt(const Duration(seconds: 16)), 'Breathe in');
    });
  });

  group('Handled urges', () {
    test('intervention and handledAt round-trip and stay optional', () {
      final open = UrgeEvent(id: 'o', timestamp: DateTime(2026, 9, 28), intensity: 5, trigger: UrgeTrigger.other);
      expect(open.isHandled, isFalse);
      expect(open.toMap().containsKey('intervention'), isFalse);

      final handled = open.copyWith(intervention: UrgeIntervention.breathe, handledAt: DateTime(2026, 9, 28, 1));
      final restored = UrgeEvent.fromJson(handled.toJson())!;
      expect(restored.isHandled, isTrue);
      expect(restored.intervention, UrgeIntervention.breathe);
      expect(restored.handledAt, DateTime(2026, 9, 28, 1));
    });

    test('records saved before stage two still load', () {
      final legacy = UrgeEvent.fromMap({'id': 'l', 'timestamp': '2026-09-28T10:00:00.000', 'intensity': 4, 'trigger': 'anger'});
      expect(legacy, isNotNull);
      expect(legacy!.isHandled, isFalse);
      expect(legacy.intervention, isNull);
    });

    test('provider markHandled persists the intervention', () async {
      final provider = UrgeProvider(UrgeRepository());
      await Future<void>.delayed(Duration.zero);
      final event = await provider.logUrge(intensity: 8, trigger: UrgeTrigger.stress);

      final updated = await provider.markHandled(event.id, UrgeIntervention.distract);

      expect(updated!.isHandled, isTrue);
      expect(provider.byId(event.id)!.intervention, UrgeIntervention.distract);
      final stored = (await UrgeRepository().getUrges()).single;
      expect(stored.intervention, UrgeIntervention.distract);
      expect(stored.handledAt, isNotNull);
      expect(await provider.markHandled('missing', UrgeIntervention.move), isNull);
    });
  });

  group('Outcomes', () {
    test('markHandled records rodeItOut and markStoppedEarly records stoppedEarly', () async {
      final provider = UrgeProvider(UrgeRepository());
      await Future<void>.delayed(Duration.zero);
      final a = await provider.logUrge(intensity: 5, trigger: UrgeTrigger.stress);
      final b = await provider.logUrge(intensity: 6, trigger: UrgeTrigger.anger);

      await provider.markHandled(a.id, UrgeIntervention.breathe);
      await provider.markStoppedEarly(b.id, UrgeIntervention.move);

      final stored = await UrgeRepository().getUrges();
      expect(stored[0].outcome, UrgeOutcome.rodeItOut);
      expect(stored[1].outcome, UrgeOutcome.stoppedEarly);
      expect(stored[1].intervention, UrgeIntervention.move);
      expect(stored[1].isHandled, isFalse);
    });

    test('stopping early never downgrades a handled urge', () async {
      final provider = UrgeProvider(UrgeRepository());
      await Future<void>.delayed(Duration.zero);
      final a = await provider.logUrge(intensity: 5, trigger: UrgeTrigger.stress);
      await provider.markHandled(a.id, UrgeIntervention.breathe);

      final result = await provider.markStoppedEarly(a.id, UrgeIntervention.move);

      expect(result!.outcome, UrgeOutcome.rodeItOut);
      expect(result.intervention, UrgeIntervention.breathe);
    });

    test('records without an outcome field infer it from handledAt', () {
      final handled = UrgeEvent.fromMap({'id': 'h', 'timestamp': '2026-09-28T10:00:00', 'intensity': 4, 'trigger': 'anger', 'handledAt': '2026-09-28T10:02:00'});
      final open = UrgeEvent.fromMap({'id': 'o', 'timestamp': '2026-09-28T10:00:00', 'intensity': 4, 'trigger': 'anger'});
      expect(handled!.outcome, UrgeOutcome.rodeItOut);
      expect(open!.outcome, UrgeOutcome.unresolved);
    });
  });

  group('UrgeStats', () {
    final now = DateTime(2026, 9, 28, 20);
    UrgeEvent at(DateTime t, {int intensity = 5, UrgeTrigger trigger = UrgeTrigger.stress, bool handled = false}) => UrgeEvent(
          id: t.toIso8601String(),
          timestamp: t,
          intensity: intensity,
          trigger: trigger,
          handledAt: handled ? t.add(const Duration(minutes: 2)) : null,
          outcome: handled ? UrgeOutcome.rodeItOut : UrgeOutcome.unresolved,
        );
    final events = [
      at(DateTime(2026, 9, 28, 9), intensity: 8, trigger: UrgeTrigger.nighttime, handled: true), // today
      at(DateTime(2026, 9, 28, 1), intensity: 4, trigger: UrgeTrigger.stress), // today, after midnight
      at(DateTime(2026, 9, 24, 22), intensity: 6, trigger: UrgeTrigger.stress, handled: true), // this week
      at(DateTime(2026, 9, 10, 12), intensity: 2, trigger: UrgeTrigger.boredom), // this month
      at(DateTime(2026, 7, 1, 12), intensity: 10, trigger: UrgeTrigger.boredom, handled: true), // older
    ];

    test('empty input yields nulls, not fake zeros', () {
      final stats = UrgeStats.compute([], UrgeRange.all, now: now);
      expect(stats.total, 0);
      expect(stats.handled, 0);
      expect(stats.mostCommonTrigger, isNull);
      expect(stats.averageIntensity, isNull);
      expect(stats.handledShare, isNull);
    });

    test('ranges start at local midnight and include the right events', () {
      expect(UrgeStats.compute(events, UrgeRange.today, now: now).total, 2);
      expect(UrgeStats.compute(events, UrgeRange.week, now: now).total, 3);
      expect(UrgeStats.compute(events, UrgeRange.month, now: now).total, 4);
      expect(UrgeStats.compute(events, UrgeRange.all, now: now).total, 5);
    });

    test('summaries are computed from the events in range', () {
      final week = UrgeStats.compute(events, UrgeRange.week, now: now);
      expect(week.handled, 2);
      expect(week.handledShare, closeTo(2 / 3, 1e-9));
      expect(week.mostCommonTrigger, UrgeTrigger.stress);
      expect(week.averageIntensity, closeTo((8 + 4 + 6) / 3, 1e-9));

      final all = UrgeStats.compute(events, UrgeRange.all, now: now);
      expect(all.averageIntensity, closeTo(6.0, 1e-9));
      expect(all.mostCommonTrigger, UrgeTrigger.stress); // 2 stress vs 2 boredom: enum order breaks the tie
    });

    test('events come back newest first', () {
      final all = UrgeStats.compute(events, UrgeRange.all, now: now);
      expect(all.events.first.timestamp, DateTime(2026, 9, 28, 9));
      expect(all.events.last.timestamp, DateTime(2026, 7, 1, 12));
    });
  });
}
