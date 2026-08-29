import 'package:shared_preferences/shared_preferences.dart';

/// The user's daily reminder preference.
class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  /// 8:00 PM — the time the Settings screen has always claimed.
  static const ReminderSettings defaults = ReminderSettings(
    enabled: false,
    hour: 20,
    minute: 0,
  );

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  /// e.g. `8:00 PM`
  String get label {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}

class ReminderSettingsRepository {
  static const String _enabledKey = 'reminder_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';

  Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? ReminderSettings.defaults.enabled,
      hour: prefs.getInt(_hourKey) ?? ReminderSettings.defaults.hour,
      minute: prefs.getInt(_minuteKey) ?? ReminderSettings.defaults.minute,
    );
  }

  Future<void> save(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, settings.hour);
    await prefs.setInt(_minuteKey, settings.minute);
  }
}
