import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/habit_repository.dart';

/// Tracks whether the user has been through onboarding and picked the habits
/// they want to break.
class OnboardingRepository {
  static const String _completedKey = 'onboarding_completed';

  final HabitRepository _habits;

  OnboardingRepository({HabitRepository? habits})
    : _habits = habits ?? HabitRepository();

  Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_completedKey) ?? false) return true;

    // Users from before this flag existed already chose their habits — don't
    // drag them back through onboarding on upgrade.
    final habits = await _habits.getHabits();
    return habits.isNotEmpty;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}
