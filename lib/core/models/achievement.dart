import 'dart:convert';
import 'package:break_free/core/models/activity_completion.dart';
import 'package:break_free/core/models/daily_quest.dart';
import 'package:break_free/core/models/danger_window.dart';
import 'package:break_free/core/models/habit.dart';
import 'package:break_free/core/models/streak_policy.dart';
import 'package:break_free/core/models/urge_event.dart';

/// Behaviour-based achievements. Each one has a rule over stored activity in
/// [AchievementRules]; nothing here is unlocked by default.
enum AchievementId {
  firstVictory('First Victory', 'Ride out your first urge with an intervention.', '🥇', 20),
  nightWarrior('Night Warrior', 'Ride out an urge between 10 PM and 4 AM.', '🌙', 25),
  patternBreaker('Pattern Breaker', 'Ride out an urge inside your highest-risk period.', '🧩', 30),
  comeback('Comeback', 'After a slip, rebuild a streak of 3 days or more.', '🔥', 30),
  cityBuilder('City Builder', 'Reach Level 3 and unlock the tower in Mind City.', '🏙️', 25),
  shieldKeeper('Shield Keeper', 'Use a Streak Shield or Freeze to protect a streak.', '🛡️', 15),
  habitReplacer('Habit Replacer', 'Complete five replacement activities.', '🔁', 25),
  questMaster('Quest Master', 'Complete all three daily quests in one day.', '🏁', 30);

  const AchievementId(this.title, this.description, this.emoji, this.xp);

  final String title;
  final String description;
  final String emoji;
  final int xp;

  static AchievementId? fromStorageKey(String? key) {
    for (final a in AchievementId.values) {
      if (a.name == key) return a;
    }
    return null;
  }
}

class UnlockedAchievement {
  const UnlockedAchievement({required this.id, required this.unlockedAt});

  final AchievementId id;
  final DateTime unlockedAt;

  Map<String, dynamic> toMap() => {'id': id.name, 'unlockedAt': unlockedAt.toIso8601String()};

  static UnlockedAchievement? fromMap(Map<String, dynamic> map) {
    final id = AchievementId.fromStorageKey(map['id'] as String?);
    final at = DateTime.tryParse(map['unlockedAt'] as String? ?? '');
    if (id == null || at == null) return null;
    return UnlockedAchievement(id: id, unlockedAt: at);
  }

  static String encodeList(List<UnlockedAchievement> list) => json.encode(list.map((u) => u.toMap()).toList());

  static List<UnlockedAchievement> decodeList(String? s) {
    if (s == null) return [];
    final decoded = json.decode(s);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((m) => UnlockedAchievement.fromMap(Map<String, dynamic>.from(m)))
        .whereType<UnlockedAchievement>()
        .toList();
  }
}

/// Everything the rules look at. Built from the providers' current state.
class AchievementInputs {
  const AchievementInputs({
    this.urges = const [],
    this.activities = const [],
    this.habits = const [],
    this.level = 1,
    this.policy,
    this.quests = const [],
  });

  final List<UrgeEvent> urges;
  final List<ActivityCompletion> activities;
  final List<Habit> habits;
  final int level;
  final StreakPolicy? policy;
  final List<DailyQuest> quests;
}

class AchievementRules {
  static const int comebackStreakDays = 3;
  static const int habitReplacerCount = 5;
  static const int cityBuilderLevel = 3;

  /// Returns the ids whose rule is satisfied by [inputs]. Pure and
  /// deterministic; [now] only matters for streak lengths.
  static Set<AchievementId> satisfied(AchievementInputs inputs, {DateTime? now}) {
    final handled = inputs.urges.where((u) => u.isHandled).toList();
    final result = <AchievementId>{};

    if (handled.isNotEmpty) result.add(AchievementId.firstVictory);

    if (handled.any((u) => _isNight(u.handledAt!))) result.add(AchievementId.nightWarrior);

    final window = DangerWindowAnalyzer.analyze(inputs.urges);
    if (window != null && handled.any((u) => window.contains(u.timestamp))) {
      result.add(AchievementId.patternBreaker);
    }

    if (inputs.habits.any((h) => h.relapseDates.isNotEmpty && _streakDays(h, now) >= comebackStreakDays)) {
      result.add(AchievementId.comeback);
    }

    if (inputs.level >= cityBuilderLevel) result.add(AchievementId.cityBuilder);

    final policy = inputs.policy;
    if (policy != null && (policy.shieldUsedDates.isNotEmpty || policy.freezeUsedDates.isNotEmpty)) {
      result.add(AchievementId.shieldKeeper);
    }

    if (inputs.activities.length >= habitReplacerCount) result.add(AchievementId.habitReplacer);

    if (inputs.quests.length == DailyQuestGenerator.questsPerDay && inputs.quests.every((q) => q.isCompleted)) {
      result.add(AchievementId.questMaster);
    }

    return result;
  }

  static bool _isNight(DateTime t) => t.hour >= 22 || t.hour < 4;

  static int _streakDays(Habit h, DateTime? now) {
    final reference = now ?? DateTime.now();
    final last = h.relapseDates.isNotEmpty ? h.relapseDates.last : h.startDate;
    return reference.difference(last).inDays;
  }
}
