import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/achievement_repository.dart';
import 'package:break_free/core/models/achievement.dart';
import 'package:break_free/core/models/activity_completion.dart';
import 'package:break_free/core/models/daily_quest.dart';
import 'package:break_free/core/models/habit.dart';
import 'package:break_free/core/models/streak_policy.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/models/urge_intervention.dart';
import 'package:break_free/core/providers/achievement_provider.dart';

final now = DateTime(2026, 9, 28, 12);

UrgeEvent urge(DateTime at, {bool handled = false, DateTime? handledAt}) => UrgeEvent(
      id: at.toIso8601String(),
      timestamp: at,
      intensity: 6,
      trigger: UrgeTrigger.stress,
      intervention: handled ? UrgeIntervention.breathe : null,
      handledAt: handled ? (handledAt ?? at.add(const Duration(minutes: 2))) : null,
      outcome: handled ? UrgeOutcome.rodeItOut : UrgeOutcome.unresolved,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AchievementRules', () {
    test('nothing is unlocked with no activity', () {
      expect(AchievementRules.satisfied(const AchievementInputs(), now: now), isEmpty);
    });

    test('First Victory needs a handled urge, not just a logged one', () {
      expect(AchievementRules.satisfied(AchievementInputs(urges: [urge(now)]), now: now), isNot(contains(AchievementId.firstVictory)));
      expect(AchievementRules.satisfied(AchievementInputs(urges: [urge(now, handled: true)]), now: now), contains(AchievementId.firstVictory));
    });

    test('Night Warrior is about when the urge was ridden out', () {
      final day = AchievementInputs(urges: [urge(DateTime(2026, 9, 28, 14), handled: true)]);
      final night = AchievementInputs(urges: [urge(DateTime(2026, 9, 28, 23, 30), handled: true)]);
      final earlyMorning = AchievementInputs(urges: [urge(DateTime(2026, 9, 29, 3, 50), handled: true)]);
      expect(AchievementRules.satisfied(day, now: now), isNot(contains(AchievementId.nightWarrior)));
      expect(AchievementRules.satisfied(night, now: now), contains(AchievementId.nightWarrior));
      expect(AchievementRules.satisfied(earlyMorning, now: now), contains(AchievementId.nightWarrior));
    });

    test('Pattern Breaker needs a handled urge inside the danger window', () {
      // Three urges at 22:xx form a 10 PM-12 AM window; none handled yet.
      final cluster = [urge(DateTime(2026, 9, 25, 22)), urge(DateTime(2026, 9, 26, 22, 30)), urge(DateTime(2026, 9, 27, 23))];
      expect(AchievementRules.satisfied(AchievementInputs(urges: cluster), now: now), isNot(contains(AchievementId.patternBreaker)));

      final handledOutside = [...cluster, urge(DateTime(2026, 9, 28, 9), handled: true)];
      expect(AchievementRules.satisfied(AchievementInputs(urges: handledOutside), now: now), isNot(contains(AchievementId.patternBreaker)));

      final handledInside = [...cluster, urge(DateTime(2026, 9, 28, 22, 15), handled: true)];
      expect(AchievementRules.satisfied(AchievementInputs(urges: handledInside), now: now), contains(AchievementId.patternBreaker));
    });

    test('Comeback needs a slip followed by a 3-day streak', () {
      final neverSlipped = Habit(id: 'a', title: 'A', iconPath: 'x', startDate: DateTime(2026, 9, 1));
      final slippedRecently = Habit(id: 'b', title: 'B', iconPath: 'x', startDate: DateTime(2026, 9, 1), relapseDates: [DateTime(2026, 9, 27)]);
      final cameBack = Habit(id: 'c', title: 'C', iconPath: 'x', startDate: DateTime(2026, 9, 1), relapseDates: [DateTime(2026, 9, 20)]);
      expect(AchievementRules.satisfied(AchievementInputs(habits: [neverSlipped]), now: now), isNot(contains(AchievementId.comeback)));
      expect(AchievementRules.satisfied(AchievementInputs(habits: [slippedRecently]), now: now), isNot(contains(AchievementId.comeback)));
      expect(AchievementRules.satisfied(AchievementInputs(habits: [cameBack]), now: now), contains(AchievementId.comeback));
    });

    test('City Builder, Shield Keeper, Habit Replacer and Quest Master', () {
      expect(AchievementRules.satisfied(const AchievementInputs(level: 2), now: now), isNot(contains(AchievementId.cityBuilder)));
      expect(AchievementRules.satisfied(const AchievementInputs(level: 3), now: now), contains(AchievementId.cityBuilder));

      expect(AchievementRules.satisfied(AchievementInputs(policy: StreakPolicy()), now: now), isNot(contains(AchievementId.shieldKeeper)));
      expect(AchievementRules.satisfied(AchievementInputs(policy: StreakPolicy(shieldUsedDates: [now])), now: now), contains(AchievementId.shieldKeeper));
      expect(AchievementRules.satisfied(AchievementInputs(policy: StreakPolicy(freezeUsedDates: [now])), now: now), contains(AchievementId.shieldKeeper));

      ActivityCompletion done(int i) => ActivityCompletion(id: '$i', activityId: 'walk_5', completedAt: now, tierMinutes: 5, xpAwarded: 10);
      expect(AchievementRules.satisfied(AchievementInputs(activities: [for (var i = 0; i < 4; i++) done(i)]), now: now), isNot(contains(AchievementId.habitReplacer)));
      expect(AchievementRules.satisfied(AchievementInputs(activities: [for (var i = 0; i < 5; i++) done(i)]), now: now), contains(AchievementId.habitReplacer));

      DailyQuest q(QuestType t, bool done) => DailyQuest(type: t, startedAt: now, progress: done ? t.target : 0, completedAt: done ? now : null);
      final twoOfThree = [q(QuestType.logUrge, true), q(QuestType.checkIn, true), q(QuestType.replacementActivity, false)];
      final allThree = [q(QuestType.logUrge, true), q(QuestType.checkIn, true), q(QuestType.replacementActivity, true)];
      expect(AchievementRules.satisfied(AchievementInputs(quests: twoOfThree), now: now), isNot(contains(AchievementId.questMaster)));
      expect(AchievementRules.satisfied(AchievementInputs(quests: allThree), now: now), contains(AchievementId.questMaster));
    });
  });

  group('AchievementProvider', () {
    test('unlocks persist, pay XP once, and never re-lock', () async {
      final paid = <int>[];
      final provider = AchievementProvider(AchievementRepository(), awardXp: (xp) async => paid.add(xp), now: () => now);
      await Future<void>.delayed(Duration.zero);

      final fresh = await provider.evaluate(AchievementInputs(urges: [urge(now, handled: true)]));
      expect(fresh, [AchievementId.firstVictory]);
      expect(paid, [AchievementId.firstVictory.xp]);
      expect(provider.takeToasts(), [AchievementId.firstVictory]);
      expect(provider.takeToasts(), isEmpty);

      // Same inputs again, and then inputs that no longer satisfy the rule.
      expect(await provider.evaluate(AchievementInputs(urges: [urge(now, handled: true)])), isEmpty);
      expect(await provider.evaluate(const AchievementInputs()), isEmpty);
      expect(provider.isUnlocked(AchievementId.firstVictory), isTrue);
      expect(paid.length, 1);

      final restarted = AchievementProvider(AchievementRepository(), awardXp: (xp) async => paid.add(xp), now: () => now);
      await Future<void>.delayed(Duration.zero);
      expect(restarted.isUnlocked(AchievementId.firstVictory), isTrue);
      expect(restarted.unlockFor(AchievementId.firstVictory)!.unlockedAt, now);
      expect(await restarted.evaluate(AchievementInputs(urges: [urge(now, handled: true)])), isEmpty);
      expect(paid.length, 1);
    });

    test('inputs given before load are evaluated once loaded', () async {
      final paid = <int>[];
      final provider = AchievementProvider(AchievementRepository(), awardXp: (xp) async => paid.add(xp), now: () => now);
      await provider.evaluate(const AchievementInputs(level: 3)); // before _load completes
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(provider.isUnlocked(AchievementId.cityBuilder), isTrue);
      expect(paid, [AchievementId.cityBuilder.xp]);
    });
  });
}
