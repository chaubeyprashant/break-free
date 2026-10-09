import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences that stay on-device (theme, notifications, privacy toggles).
class SettingsRepository {
  static const String themeModeKey = 'settings_theme_mode';
  static const String dailyRemindersKey = 'settings_daily_reminders';
  static const String protectionRemindersKey = 'settings_protection_reminders';
  static const String shareLocationWithCompanionKey = 'settings_share_location_companion';

  /// Known local progress keys cleared by "Reset progress" / "Delete local data".
  /// Does **not** include Firebase Auth or Firestore companion docs.
  static const List<String> localProgressKeys = [
    'habits_data',
    'user_progress',
    'urge_events',
    'journal_entries',
    'daily_quest_set',
    'last_blocked_attempt_at',
    'streak_policy',
    'streak_start_date',
    'recovery_plan',
    'activity_completions',
    'achievements_unlocked',
    'danger_window_reminder_enabled',
    'blocked_apps_list',
    'habit_check_ins',
    'settings_theme_mode',
    'settings_daily_reminders',
    'settings_protection_reminders',
    'settings_share_location_companion',
    'protection_config_v1',
    'protection_schedules_v1',
    'protection_events',
  ];

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(themeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      case null:
      default:
        // Dark charcoal is the designed product surface for first launch.
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(themeModeKey, value);
  }

  Future<bool> getDailyRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dailyRemindersKey) ?? true;
  }

  Future<void> setDailyRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dailyRemindersKey, value);
  }

  Future<bool> getProtectionRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(protectionRemindersKey) ?? true;
  }

  Future<void> setProtectionRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(protectionRemindersKey, value);
  }

  Future<bool> getShareLocationWithCompanion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(shareLocationWithCompanionKey) ?? true;
  }

  Future<void> setShareLocationWithCompanion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(shareLocationWithCompanionKey, value);
  }

  /// Clears local progress and preference keys. Does not sign out or delete
  /// Firebase user / companion link data in Firestore.
  Future<void> clearLocalProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in localProgressKeys) {
      await prefs.remove(key);
    }
    // Companion nickname cache keys are prefixed.
    for (final key in prefs.getKeys()) {
      if (key.startsWith('companion_name_') || key == 'has_seen_companion_feature') {
        await prefs.remove(key);
      }
    }
  }
}
