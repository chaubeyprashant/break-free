import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/daily_quest.dart';

class DailyQuestRepository {
  static const String questSetKey = 'daily_quest_set';

  /// Written by the blocker whenever a blocked app is opened; read by the
  /// "stay off blocked apps" quest.
  static const String lastBlockedAttemptKey = 'last_blocked_attempt_at';

  Future<DailyQuestSet?> getQuestSet() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(questSetKey);
    if (s == null) return null;
    try {
      return DailyQuestSet.fromJson(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveQuestSet(DailyQuestSet set) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(questSetKey, set.toJson());
  }

  Future<DateTime?> getLastBlockedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime.tryParse(prefs.getString(lastBlockedAttemptKey) ?? '');
  }

  Future<void> recordBlockedAttempt(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastBlockedAttemptKey, at.toIso8601String());
  }
}
