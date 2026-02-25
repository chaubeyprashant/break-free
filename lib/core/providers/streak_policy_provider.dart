import 'package:flutter/material.dart';
import 'package:mukti/core/data/streak_policy_repository.dart';
import 'package:mukti/core/models/streak_policy.dart';

class StreakPolicyProvider extends ChangeNotifier {
  final StreakPolicyRepository _repository;
  StreakPolicy _policy = StreakPolicy();

  StreakPolicyProvider(this._repository) {
    _load();
  }

  StreakPolicy get policy => _policy;
  bool get canUseFreeze => _policy.canUseFreeze;
  bool canUseShieldAtLevel(int level) => _policy.canUseShieldAtLevel(level);
  int get freezesUsedThisWeek => _policy.freezesUsedThisWeek;
  int get freezesRemaining => StreakPolicy.freezesPerWeek - _policy.freezesUsedThisWeek;
  int get shieldsRemaining => StreakPolicy.shieldsPerWeek - _policy.shieldsUsedThisWeek;

  Future<void> _load() async {
    _policy = await _repository.get();
    notifyListeners();
  }

  /// Use a freeze (does not log relapse). Caller should not call habitProvider.logRelapse.
  Future<bool> useFreeze() async {
    if (!_policy.canUseFreeze) return false;
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
    if (!_policy.canUseShieldAtLevel(currentLevel)) return false;
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
