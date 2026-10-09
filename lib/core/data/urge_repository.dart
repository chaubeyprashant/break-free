import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/urge_event.dart';

/// Local-only store for urge events, following the same SharedPreferences
/// pattern as HabitRepository and GameRepository.
class UrgeRepository {
  static const String urgesKey = 'urge_events';

  Future<List<UrgeEvent>> getUrges() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(urgesKey);
    if (encoded == null) return [];

    final decoded = json.decode(encoded);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => UrgeEvent.fromMap(Map<String, dynamic>.from(e)))
        .whereType<UrgeEvent>()
        .toList();
  }

  Future<void> saveUrges(List<UrgeEvent> urges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(urgesKey, json.encode(urges.map((e) => e.toMap()).toList()));
  }

  Future<void> addUrge(UrgeEvent urge) async {
    final urges = await getUrges();
    urges.add(urge);
    await saveUrges(urges);
  }

  Future<void> updateUrge(UrgeEvent updated) async {
    final urges = await getUrges();
    final index = urges.indexWhere((u) => u.id == updated.id);
    if (index == -1) return;
    urges[index] = updated;
    await saveUrges(urges);
  }
}
