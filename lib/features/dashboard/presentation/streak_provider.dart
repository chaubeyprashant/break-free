import 'package:flutter/material.dart';
import 'package:mukti/features/dashboard/data/streak_repository.dart';

class StreakProvider extends ChangeNotifier {
  final StreakRepository _repository;
  DateTime? _startDate;
  Duration _streakDuration = Duration.zero;

  StreakProvider(this._repository) {
    _loadStreak();
  }

  Duration get streakDuration => _streakDuration;
  int get days => _streakDuration.inDays;
  int get hours => _streakDuration.inHours % 24;

  Future<void> _loadStreak() async {
    _startDate = await _repository.getStreakStartDate();
    if (_startDate == null) {
      await _repository.startStreak();
      _startDate = DateTime.now();
    }
    _updateDuration();
  }

  void _updateDuration() {
    if (_startDate != null) {
      _streakDuration = DateTime.now().difference(_startDate!);
      notifyListeners();
    }
  }

  Future<void> resetStreak() async {
    await _repository.resetStreak();
    await _loadStreak();
  }

  void refresh() {
    _updateDuration();
  }
}
