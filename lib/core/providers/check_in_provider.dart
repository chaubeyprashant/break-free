import 'package:flutter/material.dart';
import 'package:break_free/core/data/check_in_repository.dart';
import 'package:break_free/core/models/daily_quest.dart';

class CheckInProvider extends ChangeNotifier {
  CheckInProvider(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now {
    _load();
  }

  final CheckInRepository _repository;
  final DateTime Function() _now;

  Map<String, String> _byHabit = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> reloadFromDisk() => _load();

  Future<void> _load() async {
    _byHabit = await _repository.getCheckIns();
    _loaded = true;
    notifyListeners();
  }

  String get _todayKey => DailyQuestSet.keyFor(_now());

  bool hasCheckedInToday(String habitId) => _byHabit[habitId] == _todayKey;

  /// Awards are the caller's responsibility. Returns false if already checked in.
  Future<bool> recordCheckIn(String habitId) async {
    if (!_loaded) await _load();
    if (hasCheckedInToday(habitId)) return false;
    final ok = await _repository.recordCheckIn(habitId, now: _now());
    if (!ok) return false;
    _byHabit = {..._byHabit, habitId: _todayKey};
    notifyListeners();
    return true;
  }

  Future<void> clear() async {
    await _repository.clear();
    _byHabit = {};
    notifyListeners();
  }
}
