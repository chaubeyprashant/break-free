import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/activity_event.dart';

/// Append-only log of recent user activity, newest first.
class ActivityLogRepository {
  static const String _logKey = 'activity_log';

  /// Only the most recent entries are kept — the dashboard shows a handful.
  static const int maxEntries = 20;

  Future<List<ActivityEvent>> getEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_logKey);
    if (encoded == null) return [];

    final decoded = json.decode(encoded) as List<dynamic>;
    return decoded
        .map((e) => ActivityEvent.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> record(ActivityEvent event) async {
    final events = await getEvents();
    events.insert(0, event);
    if (events.length > maxEntries) {
      events.removeRange(maxEntries, events.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _logKey,
      json.encode(events.map((e) => e.toMap()).toList()),
    );
  }
}
