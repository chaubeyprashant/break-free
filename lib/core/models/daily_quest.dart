import 'dart:convert';

/// Kinds of daily quest. Every one is measured from real activity the app
/// already records; none are self-reported toggles.
enum QuestType {
  logUrge(
    title: 'Defeat an urge',
    description: 'Log an urge instead of acting on it.',
    target: 1,
    xp: 10,
    coins: 2,
  ),
  completeIntervention(
    title: 'Ride one out',
    description: 'Finish a Breathe, Move or Distract session.',
    target: 1,
    xp: 15,
    coins: 3,
  ),
  checkIn(
    title: 'Clean-day check-in',
    description: 'Check in on one of your habits.',
    target: 1,
    xp: 10,
    coins: 2,
  ),
  avoidBlockedApps(
    title: 'Stay off blocked apps',
    description: 'No blocked-app attempts for 4 hours.',
    target: 240, // minutes
    xp: 20,
    coins: 4,
  ),
  replacementActivity(
    title: 'Replace the habit',
    description: 'Complete any replacement activity.',
    target: 1,
    xp: 15,
    coins: 3,
  ),
  twoUrges(
    title: 'Stay aware',
    description: 'Log two urges today.',
    target: 2,
    xp: 15,
    coins: 3,
  );

  const QuestType({
    required this.title,
    required this.description,
    required this.target,
    required this.xp,
    required this.coins,
  });

  final String title;
  final String description;
  final int target;
  final int xp;
  final int coins;

  /// Progress is a duration in minutes rather than a count.
  bool get isTimed => this == QuestType.avoidBlockedApps;

  static QuestType? fromStorageKey(String? key) {
    for (final t in QuestType.values) {
      if (t.name == key) return t;
    }
    return null;
  }
}

class DailyQuest {
  const DailyQuest({
    required this.type,
    required this.startedAt,
    this.progress = 0,
    this.completedAt,
    this.rewardClaimed = false,
  });

  final QuestType type;

  /// When the quest was generated; the timed quest measures from here.
  final DateTime startedAt;
  final int progress;
  final DateTime? completedAt;
  final bool rewardClaimed;

  bool get isCompleted => completedAt != null;
  int get target => type.target;
  double get fraction => target == 0 ? 1 : (progress / target).clamp(0.0, 1.0);

  DailyQuest copyWith({int? progress, DateTime? completedAt, bool? rewardClaimed}) => DailyQuest(
        type: type,
        startedAt: startedAt,
        progress: progress ?? this.progress,
        completedAt: completedAt ?? this.completedAt,
        rewardClaimed: rewardClaimed ?? this.rewardClaimed,
      );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'startedAt': startedAt.toIso8601String(),
        'progress': progress,
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'rewardClaimed': rewardClaimed,
      };

  static DailyQuest? fromMap(Map<String, dynamic> map) {
    final type = QuestType.fromStorageKey(map['type'] as String?);
    final startedAt = DateTime.tryParse(map['startedAt'] as String? ?? '');
    final progress = map['progress'];
    if (type == null || startedAt == null || progress is! int) return null;
    return DailyQuest(
      type: type,
      startedAt: startedAt,
      progress: progress,
      completedAt: DateTime.tryParse(map['completedAt'] as String? ?? ''),
      rewardClaimed: map['rewardClaimed'] == true,
    );
  }
}

/// One day's quest set. [dateKey] is yyyy-mm-dd in local time; a set is
/// only replaced when the key no longer matches today.
class DailyQuestSet {
  const DailyQuestSet({required this.dateKey, required this.quests, this.checkInsToday = 0});

  final String dateKey;
  final List<DailyQuest> quests;

  /// Check-ins are not stored anywhere else, so the count lives with the day.
  final int checkInsToday;

  static String keyFor(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  DailyQuestSet copyWith({List<DailyQuest>? quests, int? checkInsToday}) =>
      DailyQuestSet(dateKey: dateKey, quests: quests ?? this.quests, checkInsToday: checkInsToday ?? this.checkInsToday);

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'checkInsToday': checkInsToday,
        'quests': quests.map((q) => q.toMap()).toList(),
      };

  static DailyQuestSet? fromMap(Map<String, dynamic> map) {
    final dateKey = map['dateKey'];
    final rawQuests = map['quests'];
    if (dateKey is! String || rawQuests is! List) return null;
    final quests = rawQuests
        .whereType<Map>()
        .map((q) => DailyQuest.fromMap(Map<String, dynamic>.from(q)))
        .whereType<DailyQuest>()
        .toList();
    return DailyQuestSet(
      dateKey: dateKey,
      quests: quests,
      checkInsToday: map['checkInsToday'] is int ? map['checkInsToday'] as int : 0,
    );
  }

  String toJson() => json.encode(toMap());
  static DailyQuestSet? fromJson(String s) {
    final decoded = json.decode(s);
    return decoded is Map<String, dynamic> ? fromMap(decoded) : null;
  }
}

/// Picks three quests for a day. Deterministic for a given day and context,
/// so reopening the app never reshuffles the set.
class DailyQuestGenerator {
  static const int questsPerDay = 3;

  static List<DailyQuest> generate({
    required DateTime day,
    required bool hasBlockedApps,
    required bool hasHabits,
  }) {
    final pool = <QuestType>[
      QuestType.logUrge,
      QuestType.completeIntervention,
      QuestType.replacementActivity,
      QuestType.twoUrges,
      if (hasHabits) QuestType.checkIn,
      if (hasBlockedApps) QuestType.avoidBlockedApps,
    ];

    // Rotate the pool by a value derived from the date so different days get
    // different mixes without any randomness.
    final seed = day.year * 366 + day.month * 31 + day.day;
    final rotated = [for (var i = 0; i < pool.length; i++) pool[(i + seed) % pool.length]];

    // Prefer one quest that needs a blocker/habit when available, so the set
    // reflects how the user actually uses the app.
    final chosen = <QuestType>[];
    for (final t in rotated) {
      if (chosen.length == questsPerDay) break;
      // Avoid both urge-count quests on the same day.
      if (t == QuestType.twoUrges && chosen.contains(QuestType.logUrge)) continue;
      if (t == QuestType.logUrge && chosen.contains(QuestType.twoUrges)) continue;
      chosen.add(t);
    }
    // Pool is at least 4 wide, so three are always found.
    final startedAt = DateTime(day.year, day.month, day.day, day.hour, day.minute, day.second);
    return [for (final t in chosen) DailyQuest(type: t, startedAt: startedAt)];
  }
}
