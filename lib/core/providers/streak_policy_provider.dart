import 'package:flutter/material.dart';
import 'package:break_free/core/data/streak_policy_repository.dart';
import 'package:break_free/core/models/streak_policy.dart';

class StreakPolicyProvider extends ChangeNotifier {
  final StreakPolicyRepository _repository;
  StreakPolicy _policy = StreakPolicy();

  StreakPolicyProvider(this._repository) {
    _load();
  }

  StreakPolicy get policy => _policy;

  /// Optional Premium-aware caps. Defaults keep legacy free limits.
  int freezeCap = StreakPolicy.freezesPerWeek;
  int shieldCap = StreakPolicy.shieldsPerWeek;

  bool get canUseFreeze => _policy.canUseFreezeWithCap(freezeCap);
  bool canUseShieldAtLevel(int level) => _policy.canUseShieldAtLevelWithCap(level, shieldCap);
  int get freezesUsedThisWeek => _policy.freezesUsedThisWeek;
  int get freezesRemaining => (freezeCap - _policy.freezesUsedThisWeek).clamp(0, freezeCap);
  int get shieldsRemaining => (shieldCap - _policy.shieldsUsedThisWeek).clamp(0, shieldCap);

  void applyCaps({required int freezesPerWeek, required int shieldsPerWeek}) {
    if (freezeCap == freezesPerWeek && shieldCap == shieldsPerWeek) return;
    freezeCap = freezesPerWeek;
    shieldCap = shieldsPerWeek;
    notifyListeners();
  }

  Future<void> _load() async {
    _policy = await _repository.get();
    notifyListeners();
  }

  /// Use a freeze (does not log relapse). Caller should not call habitProvider.logRelapse.
  Future<bool> useFreeze() async {
    if (!_policy.canUseFreezeWithCap(freezeCap)) return false;
    _policy = StreakPolicy(
      freezeUsedDates: [..._policy.freezeUsedDates, DateTime.now()],
      shieldUsedDates: _policy.shieldUsedDates,
    );
    await _repository.save(_policy);
    notifyListeners();
    return true;
  }

  /// Use streak shield (level 3+). Caller should not log relapse.
  Future<bool> useShield(int currentLevel) async {
    if (!_policy.canUseShieldAtLevelWithCap(currentLevel, shieldCap)) return false;
    _policy = StreakPolicy(
      freezeUsedDates: _policy.freezeUsedDates,
      shieldUsedDates: [..._policy.shieldUsedDates, DateTime.now()],
    );
    await _repository.save(_policy);
    notifyListeners();
    return true;
  }

  Future<void> refresh() async => _load();
}
