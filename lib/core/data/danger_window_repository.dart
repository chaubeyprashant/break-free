import 'package:shared_preferences/shared_preferences.dart';

/// Stores whether the user opted in to the protection reminder.
class DangerWindowRepository {
  static const String reminderEnabledKey = 'danger_window_reminder_enabled';

  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(reminderEnabledKey) ?? false;
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(reminderEnabledKey, enabled);
  }
}
