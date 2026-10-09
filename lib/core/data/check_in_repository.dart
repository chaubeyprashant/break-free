import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/daily_quest.dart';

/// Persists the last clean-day check-in [dateKey] per habit so rewards cannot
/// be claimed twice for the same local calendar day, including after restart.
class CheckInRepository {
  static const String checkInsKey = 'habit_check_ins';

  /// habitId → yyyy-MM-dd (local).
  Future<Map<String, String>> getCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(checkInsKey);
    if (raw == null) return {};
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCheckIns(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(checkInsKey, json.encode(map));
  }

  Future<bool> hasCheckedInToday(String habitId, {DateTime? now}) async {
    final map = await getCheckIns();
    final today = DailyQuestSet.keyFor(now ?? DateTime.now());
    return map[habitId] == today;
  }

  /// Returns true if this is the first check-in for [habitId] today and it was saved.
  Future<bool> recordCheckIn(String habitId, {DateTime? now}) async {
    final map = await getCheckIns();
    final today = DailyQuestSet.keyFor(now ?? DateTime.now());
    if (map[habitId] == today) return false;
    map[habitId] = today;
    await saveCheckIns(map);
    return true;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(checkInsKey);
  }
}
