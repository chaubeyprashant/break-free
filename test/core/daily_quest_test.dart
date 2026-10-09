import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/daily_quest_repository.dart';
import 'package:break_free/core/models/activity_completion.dart';
import 'package:break_free/core/models/daily_quest.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/providers/daily_quest_provider.dart';

class RewardLog {
  final List<(int, int)> paid = [];
  Future<void> call(int xp, int coins) async => paid.add((xp, coins));
}

Future<DailyQuestProvider> provider(DateTime Function() now, RewardLog log, {bool blocked = false, bool habits = true}) async {
  final p = DailyQuestProvider(DailyQuestRepository(), awardReward: log.call, now: now);
  await Future<void>.delayed(Duration.zero);
  await p.update(hasBlockedApps: blocked, hasHabits: habits, urges: const [], activities: const []);
  return p;
}

UrgeEvent urge(DateTime at, {DateTime? handledAt}) => UrgeEvent(
      id: at.toIso8601String(),
      timestamp: at,
      intensity: 5,
      trigger: UrgeTrigger.stress,
      handledAt: handledAt,
      outcome: handledAt == null ? UrgeOutcome.unresolved : UrgeOutcome.rodeItOut,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('DailyQuestGenerator', () {
    test('always yields three distinct quests', () {
      for (var d = 1; d <= 31; d++) {
        final set = DailyQuestGenerator.generate(day: DateTime(2026, 10, d), hasBlockedApps: d.isEven, hasHabits: d % 3 == 0);
        expect(set.length, 3, reason: 'day $d');
        expect(set.map((q) => q.type).toSet().length, 3, reason: 'day $d');
        expect(set.any((q) => q.type == QuestType.logUrge) && set.any((q) => q.type == QuestType.twoUrges), isFalse);
      }
    });

    test('is deterministic for the same day and context', () {
      final a = DailyQuestGenerator.generate(day: DateTime(2026, 9, 28, 8), hasBlockedApps: true, hasHabits: true);
      final b = DailyQuestGenerator.generate(day: DateTime(2026, 9, 28, 23), hasBlockedApps: true, hasHabits: true);
      expect(a.map((q) => q.type), b.map((q) => q.type));
    });

    test('varies across days', () {
      final types = {
        for (var d = 1; d <= 7; d++)
          DailyQuestGenerator.generate(day: DateTime(2026, 10, d), hasBlockedApps: true, hasHabits: true).map((q) => q.type).join(','),
      };
      expect(types.length, greaterThan(1));
    });

    test('never offers blocker or habit quests the user cannot do', () {
      for (var d = 1; d <= 31; d++) {
        final set = DailyQuestGenerator.generate(day: DateTime(2026, 10, d), hasBlockedApps: false, hasHabits: false);
        expect(set.any((q) => q.type == QuestType.avoidBlockedApps), isFalse);
        expect(set.any((q) => q.type == QuestType.checkIn), isFalse);
      }
    });
  });

  group('DailyQuestSet persistence', () {
    test('round-trips including progress and reward flags', () {
      final set = DailyQuestSet(
        dateKey: '2026-09-28',
        checkInsToday: 2,
        quests: [
          DailyQuest(type: QuestType.checkIn, startedAt: DateTime(2026, 9, 28, 7), progress: 1, completedAt: DateTime(2026, 9, 28, 8), rewardClaimed: true),
          DailyQuest(type: QuestType.avoidBlockedApps, startedAt: DateTime(2026, 9, 28, 7), progress: 120),
        ],
      );
      final restored = DailyQuestSet.fromJson(set.toJson())!;
      expect(restored.dateKey, '2026-09-28');
      expect(restored.checkInsToday, 2);
      expect(restored.quests[0].isCompleted, isTrue);
      expect(restored.quests[0].rewardClaimed, isTrue);
      expect(restored.quests[1].progress, 120);
      expect(restored.quests[1].isCompleted, isFalse);
    });
  });

  group('DailyQuestProvider', () {
    test('keeps the same quests within a day and across restarts', () async {
      var clock = DateTime(2026, 9, 28, 9);
      final log = RewardLog();
      final first = await provider(() => clock, log, blocked: true);
      final types = first.quests.map((q) => q.type).toList();

      clock = DateTime(2026, 9, 28, 22);
      await first.tick();
      expect(first.quests.map((q) => q.type).toList(), types);

      final restarted = await provider(() => clock, log, blocked: true);
      expect(restarted.quests.map((q) => q.type).toList(), types);
    });

    test('generates a fresh set when the day changes', () async {
      var clock = DateTime(2026, 9, 28, 9);
      final log = RewardLog();
      final p = await provider(() => clock, log);
      final before = p.quests.map((q) => q.startedAt).toList();

      clock = DateTime(2026, 9, 29, 0, 5);
      await p.tick();
      expect(p.quests.length, 3);
      expect(p.quests.every((q) => q.startedAt.day == 29), isTrue);
      expect(p.quests.map((q) => q.startedAt), isNot(before));
      expect(p.quests.every((q) => !q.isCompleted && q.progress == 0), isTrue);
    });

    test('urge and intervention quests progress from real records and pay once', () async {
      final clock = DateTime(2026, 9, 28, 12);
      final log = RewardLog();
      // Pick a day whose set includes both urge and intervention quests.
      DateTime day = clock;
      while (true) {
        final set = DailyQuestGenerator.generate(day: day, hasBlockedApps: false, hasHabits: false).map((q) => q.type).toList();
        if (set.contains(QuestType.logUrge) && set.contains(QuestType.completeIntervention)) break;
        day = day.add(const Duration(days: 1));
      }
      final p = await provider(() => day, log, habits: false);

      final handled = urge(day.subtract(const Duration(hours: 2)), handledAt: day.subtract(const Duration(hours: 1)));
      await p.update(urges: [handled]);

      final logQuest = p.quests.firstWhere((q) => q.type == QuestType.logUrge);
      final interventionQuest = p.quests.firstWhere((q) => q.type == QuestType.completeIntervention);
      expect(logQuest.isCompleted, isTrue);
      expect(interventionQuest.isCompleted, isTrue);
      expect(log.paid, containsAll([(QuestType.logUrge.xp, QuestType.logUrge.coins), (QuestType.completeIntervention.xp, QuestType.completeIntervention.coins)]));

      final paidBefore = log.paid.length;
      await p.update(urges: [handled, urge(day)]);
      await p.tick();
      expect(log.paid.length, paidBefore, reason: 'rewards are paid exactly once');

      final stored = (await DailyQuestRepository().getQuestSet())!;
      expect(stored.quests.firstWhere((q) => q.type == QuestType.logUrge).rewardClaimed, isTrue);
    });

    test('yesterday\'s records do not count today', () async {
      final clock = DateTime(2026, 9, 28, 12);
      final log = RewardLog();
      final p = await provider(() => clock, log, habits: false);
      await p.update(urges: [urge(DateTime(2026, 9, 27, 23, 50))], activities: [
        ActivityCompletion(id: 'a', activityId: 'walk_5', completedAt: DateTime(2026, 9, 27, 20), tierMinutes: 5, xpAwarded: 10),
      ]);
      expect(p.quests.every((q) => q.progress == 0), isTrue);
      expect(log.paid, isEmpty);
    });

    test('check-ins and replacement activities complete their quests', () async {
      final log = RewardLog();
      // Find a day whose set includes both quests.
      DateTime day = DateTime(2026, 9, 28, 12);
      while (true) {
        final set = DailyQuestGenerator.generate(day: day, hasBlockedApps: false, hasHabits: true).map((q) => q.type).toList();
        if (set.contains(QuestType.checkIn) && set.contains(QuestType.replacementActivity)) break;
        day = day.add(const Duration(days: 1));
      }
      final p = await provider(() => day, log);

      await p.recordCheckIn();
      await p.update(activities: [
        ActivityCompletion(id: 'a', activityId: 'walk_5', completedAt: day, tierMinutes: 5, xpAwarded: 10),
      ]);

      expect(p.quests.firstWhere((q) => q.type == QuestType.checkIn).isCompleted, isTrue);
      expect(p.quests.firstWhere((q) => q.type == QuestType.replacementActivity).isCompleted, isTrue);
      expect(log.paid.length, 2);
    });

    test('the blocked-app quest measures time since the last attempt', () async {
      final log = RewardLog();
      DateTime day = DateTime(2026, 9, 28, 9);
      while (!DailyQuestGenerator.generate(day: day, hasBlockedApps: true, hasHabits: false).any((q) => q.type == QuestType.avoidBlockedApps)) {
        day = day.add(const Duration(days: 1));
      }
      var clock = day;
      final p = await provider(() => clock, log, blocked: true, habits: false);
      DailyQuest quest() => p.quests.firstWhere((q) => q.type == QuestType.avoidBlockedApps);

      clock = day.add(const Duration(hours: 2));
      await p.tick();
      expect(quest().progress, 120);
      expect(quest().isCompleted, isFalse);

      // A blocked-app attempt resets the clock.
      await DailyQuestRepository().recordBlockedAttempt(day.add(const Duration(hours: 3)));
      clock = day.add(const Duration(hours: 4));
      await p.tick();
      expect(quest().progress, 60);

      clock = day.add(const Duration(hours: 7, minutes: 30));
      await p.tick();
      expect(quest().isCompleted, isTrue);
      expect(log.paid, contains((QuestType.avoidBlockedApps.xp, QuestType.avoidBlockedApps.coins)));
    });
  });
}
