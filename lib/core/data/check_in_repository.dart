import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Daily check-in state: the lifetime total and the XP earned per day.
///
/// Per-day XP is kept for the last [_historyDays] days so the dashboard can
/// chart the current week without storing an unbounded history.
class CheckInRepository {
  static const String _totalKey = 'check_in_total';
  static const String _dailyXpKey = 'check_in_daily_xp';
  static const int _historyDays = 30;

  /// Local calendar day key, e.g. `2026-08-28`.
  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<Map<String, int>> getDailyXp() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_dailyXpKey);
    if (encoded == null) return {};
    final decoded = json.decode(encoded) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  Future<int> getTotalCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalKey) ?? 0;
  }

  Future<bool> hasCheckedInOn(DateTime day) async {
    final daily = await getDailyXp();
    return daily.containsKey(dateKey(day));
  }

  /// Records a check-in for the calendar day of [when].
  ///
  /// Returns false when that day has already been checked in, so callers can
  /// avoid awarding XP twice.
  Future<bool> recordCheckIn({required DateTime when, required int xp}) async {
    final daily = await getDailyXp();
    final key = dateKey(when);
    if (daily.containsKey(key)) return false;

    daily[key] = xp;

    final cutoff = DateTime(when.year, when.month, when.day - _historyDays);
    daily.removeWhere((day, _) {
      final parsed = DateTime.tryParse(day);
      return parsed == null || parsed.isBefore(cutoff);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyXpKey, json.encode(daily));
    await prefs.setInt(_totalKey, (prefs.getInt(_totalKey) ?? 0) + 1);
    return true;
  }

  /// XP per day for the Monday-to-Sunday week containing [day].
  Future<List<double>> xpForWeekOf(DateTime day) async {
    final daily = await getDailyXp();
    final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    return List<double>.generate(7, (index) {
      final date = DateTime(monday.year, monday.month, monday.day + index);
      return (daily[dateKey(date)] ?? 0).toDouble();
    });
  }
}
