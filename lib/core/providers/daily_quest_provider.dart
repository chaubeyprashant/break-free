import 'package:flutter/material.dart';
import 'package:break_free/core/data/daily_quest_repository.dart';
import 'package:break_free/core/models/activity_completion.dart';
import 'package:break_free/core/models/daily_quest.dart';
import 'package:break_free/core/models/urge_event.dart';

typedef RewardSink = Future<void> Function(int xp, int coins);

/// Owns today's quest set. Progress is recomputed from the records the app
/// already keeps (urges, interventions, activities) plus two small hooks
/// (check-ins, blocked-app attempts). The set is persisted and only replaced
/// when the calendar day changes.
class DailyQuestProvider extends ChangeNotifier {
  DailyQuestProvider(
    this._repository, {
    required RewardSink awardReward,
    DateTime Function()? now,
  })  : _awardReward = awardReward,
        _now = now ?? DateTime.now {
    _load();
  }

  final DailyQuestRepository _repository;
  final RewardSink _awardReward;
  final DateTime Function() _now;

  DailyQuestSet? _set;
  bool _loaded = false;

  // Latest inputs, kept so the day rollover can recompute immediately.
  List<UrgeEvent> _urges = const [];
  List<ActivityCompletion> _activities = const [];
  bool _hasBlockedApps = false;
  bool _hasHabits = false;

  /// Generation waits for the first [update] so the set reflects whether the
  /// user has habits and blocked apps, instead of guessing at load time.
  bool _contextKnown = false;

  List<DailyQuest> get quests => _set?.quests ?? const [];
  bool get isLoaded => _loaded;
  int get completedCount => quests.where((q) => q.isCompleted).length;

  Future<void> reloadFromDisk() => _load();

  Future<void> _load() async {
    _set = await _repository.getQuestSet();
    _loaded = true;
    if (_contextKnown) {
      await _ensureToday();
      await _recompute();
    }
    notifyListeners();
  }

  /// Regenerates only when the stored set is for another day.
  Future<void> _ensureToday() async {
    final now = _now();
    final today = DailyQuestSet.keyFor(now);
    if (_set != null && _set!.dateKey == today && _set!.quests.isNotEmpty) return;
    if (!_contextKnown) return;
    _set = DailyQuestSet(
      dateKey: today,
      quests: DailyQuestGenerator.generate(day: now, hasBlockedApps: _hasBlockedApps, hasHabits: _hasHabits),
    );
    await _repository.saveQuestSet(_set!);
  }

  /// Called by the proxy provider whenever urges or activities change, and by
  /// the UI on a timer for the timed quest.
  Future<void> update({
    List<UrgeEvent>? urges,
    List<ActivityCompletion>? activities,
    bool? hasBlockedApps,
    bool? hasHabits,
  }) async {
    if (urges != null) _urges = urges;
    if (activities != null) _activities = activities;
    if (hasBlockedApps != null) _hasBlockedApps = hasBlockedApps;
    if (hasHabits != null) _hasHabits = hasHabits;
    if (hasBlockedApps != null && hasHabits != null) _contextKnown = true;
    if (!_loaded) return;
    await _ensureToday();
    await _recompute();
  }

  Future<void> recordCheckIn() async {
    if (!_loaded) return;
    await _ensureToday();
    if (_set == null) return;
    // Always persist the counter even when today's set has no check-in quest,
    // so the count survives restart and process death.
    _set = _set!.copyWith(checkInsToday: _set!.checkInsToday + 1);
    await _repository.saveQuestSet(_set!);
    await _recompute();
    notifyListeners();
  }

  Future<void> tick() => update();

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<int> _progressFor(DailyQuest quest, DateTime now) async {
    switch (quest.type) {
      case QuestType.logUrge:
      case QuestType.twoUrges:
        return _urges.where((u) => _sameDay(u.timestamp, now)).length;
      case QuestType.completeIntervention:
        return _urges.where((u) => u.handledAt != null && _sameDay(u.handledAt!, now)).length;
      case QuestType.replacementActivity:
        return _activities.where((a) => _sameDay(a.completedAt, now)).length;
      case QuestType.checkIn:
        return _set?.checkInsToday ?? 0;
      case QuestType.avoidBlockedApps:
        final lastAttempt = await _repository.getLastBlockedAttempt();
        var from = quest.startedAt;
        if (lastAttempt != null && lastAttempt.isAfter(from)) from = lastAttempt;
        return now.difference(from).inMinutes.clamp(0, quest.target);
    }
  }

  Future<void> _recompute() async {
    final set = _set;
    if (set == null) return;
    final now = _now();
    var changed = false;
    final next = <DailyQuest>[];
    final rewards = <DailyQuest>[];

    for (final quest in set.quests) {
      var q = quest;
      final progress = q.isCompleted ? q.progress : await _progressFor(q, now);
      if (progress != q.progress) {
        q = q.copyWith(progress: progress);
        changed = true;
      }
      if (!q.isCompleted && q.progress >= q.target) {
        q = q.copyWith(completedAt: now);
        changed = true;
      }
      if (q.isCompleted && !q.rewardClaimed) {
        q = q.copyWith(rewardClaimed: true);
        rewards.add(q);
        changed = true;
      }
      next.add(q);
    }

    if (!changed) return;
    _set = set.copyWith(quests: next);
    // Persist before paying out so a crash cannot pay twice.
    await _repository.saveQuestSet(_set!);
    for (final q in rewards) {
      await _awardReward(q.type.xp, q.type.coins);
    }
    notifyListeners();
  }
}
