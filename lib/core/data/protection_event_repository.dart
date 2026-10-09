import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/protection_event.dart';

class ProtectionEventRepository {
  static const String _key = 'protection_events';
  static const int _maxEvents = 200;

  Future<List<ProtectionEvent>> load({int limit = 50}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      final events = list
          .whereType<Map>()
          .map((e) => ProtectionEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return events.take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(ProtectionEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await load(limit: _maxEvents);
    final next = [event, ...existing].take(_maxEvents).toList();
    await prefs.setString(
      _key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
