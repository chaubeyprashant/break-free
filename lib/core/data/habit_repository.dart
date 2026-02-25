import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mukti/core/models/habit.dart';

class HabitRepository {
  static const String _habitsKey = 'habits_data';

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(habits.map((e) => e.toMap()).toList());
    await prefs.setString(_habitsKey, encoded);
  }

  Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_habitsKey);
    if (encoded == null) return [];

    final List<dynamic> decoded = json.decode(encoded);
    return decoded.map((e) => Habit.fromMap(e)).toList();
  }

  Future<void> addHabit(Habit habit) async {
    final habits = await getHabits();
    habits.add(habit);
    await saveHabits(habits);
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final habits = await getHabits();
    final index = habits.indexWhere((h) => h.id == updatedHabit.id);
    if (index != -1) {
      habits[index] = updatedHabit;
      await saveHabits(habits);
    }
  }
}
