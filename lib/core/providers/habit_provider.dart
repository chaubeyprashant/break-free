import 'package:flutter/material.dart';
import 'package:break_free/core/data/habit_repository.dart';
import 'package:break_free/core/models/habit.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository;
  List<Habit> _habits = [];

  HabitProvider(this._repository) {
    _loadHabits();
  }

  List<Habit> get habits => _habits;

  Future<void> _loadHabits() async {
    final habits = await _repository.getHabits();
    // De-duplicate by title
    final seenTitles = <String>{};
    _habits = habits.where((habit) {
      if (seenTitles.contains(habit.title)) {
        return false;
      } else {
        seenTitles.add(habit.title);
        return true;
      }
    }).toList();

    // If we removed duplicates, save back to repository to clean up storage
    if (_habits.length < habits.length) {
      await _repository.saveHabits(_habits);
    }
    notifyListeners();
  }

  Future<void> addHabit(
    String title,
    String iconPath,
    List<String> triggers,
  ) async {
    // Check for duplicates before adding
    if (_habits.any((h) => h.title == title)) {
      return;
    }

    final newHabit = Habit(
      id: DateTime.now().toIso8601String(),
      title: title,
      iconPath: iconPath,
      startDate: DateTime.now(),
      triggers: triggers,
    );
    await _repository.addHabit(newHabit);
    await _loadHabits();
  }

  Future<void> logRelapse(String habitId) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index != -1) {
      final habit = _habits[index];
      final updatedHabit = Habit(
        id: habit.id,
        title: habit.title,
        iconPath: habit.iconPath,
        startDate: habit.startDate,
        triggers: habit.triggers,
        relapseDates: [...habit.relapseDates, DateTime.now()],
      );
      await _repository.updateHabit(updatedHabit);
      await _loadHabits();
    }
  }
}
