import 'package:shared_preferences/shared_preferences.dart';

class StreakRepository {
  static const String _streakKey = 'streak_start_date';

  Future<void> startStreak() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_streakKey)) {
      await prefs.setString(_streakKey, DateTime.now().toIso8601String());
    }
  }

  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_streakKey, DateTime.now().toIso8601String());
  }

  Future<DateTime?> getStreakStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_streakKey);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }
}
