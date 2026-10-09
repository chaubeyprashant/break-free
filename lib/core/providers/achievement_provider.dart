import 'package:flutter/material.dart';
import 'package:break_free/core/data/achievement_repository.dart';
import 'package:break_free/core/models/achievement.dart';

typedef AchievementRewardSink = Future<void> Function(int xp);

/// Evaluates the achievement rules against current activity, persists new
/// unlocks, pays their XP once through the existing game system, and queues
/// them for the unlock toast.
class AchievementProvider extends ChangeNotifier {
  AchievementProvider(this._repository, {required AchievementRewardSink awardXp, DateTime Function()? now})
      : _awardXp = awardXp,
        _now = now ?? DateTime.now {
    _load();
  }

  final AchievementRepository _repository;
  final AchievementRewardSink _awardXp;
  final DateTime Function() _now;

  List<UnlockedAchievement> _unlocked = [];
  final List<AchievementId> _toastQueue = [];
  AchievementInputs? _pendingInputs;
  bool _loaded = false;
  bool _evaluating = false;

  List<UnlockedAchievement> get unlocked => List.unmodifiable(_unlocked);
  bool isUnlocked(AchievementId id) => _unlocked.any((u) => u.id == id);
  UnlockedAchievement? unlockFor(AchievementId id) {
    for (final u in _unlocked) {
      if (u.id == id) return u;
    }
    return null;
  }

  int get unlockedCount => _unlocked.length;
  int get totalCount => AchievementId.values.length;

  Future<void> reloadFromDisk() => _load();

  Future<void> _load() async {
    _unlocked = await _repository.getUnlocked();
    _loaded = true;
    final pending = _pendingInputs;
    if (pending != null) await evaluate(pending);
    notifyListeners();
  }

  /// Checks every rule; unlocks what is newly satisfied. Never re-locks.
  Future<List<AchievementId>> evaluate(AchievementInputs inputs) async {
    if (!_loaded) {
      _pendingInputs = inputs;
      return const [];
    }
    if (_evaluating) {
      _pendingInputs = inputs;
      return const [];
    }
    _evaluating = true;
    try {
      final satisfied = AchievementRules.satisfied(inputs, now: _now());
      final fresh = satisfied.where((id) => !isUnlocked(id)).toList();
      if (fresh.isEmpty) return const [];

      final at = _now();
      _unlocked = [..._unlocked, for (final id in fresh) UnlockedAchievement(id: id, unlockedAt: at)];
      // Persist first so a crash cannot pay the same unlock twice.
      await _repository.saveUnlocked(_unlocked);
      _toastQueue.addAll(fresh);
      notifyListeners();
      for (final id in fresh) {
        await _awardXp(id.xp);
      }
      return fresh;
    } finally {
      _evaluating = false;
      final pending = _pendingInputs;
      _pendingInputs = null;
      if (pending != null) await evaluate(pending);
    }
  }

  /// Unlocks not yet shown to the user; the UI drains this.
  List<AchievementId> takeToasts() {
    final out = List<AchievementId>.from(_toastQueue);
    _toastQueue.clear();
    return out;
  }

  bool get hasPendingToasts => _toastQueue.isNotEmpty;
}
