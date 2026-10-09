import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/activity_completion.dart';

class ActivityRepository {
  static const String completionsKey = 'activity_completions';

  Future<List<ActivityCompletion>> getCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(completionsKey);
    if (encoded == null) return [];
    final decoded = json.decode(encoded);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => ActivityCompletion.fromMap(Map<String, dynamic>.from(e)))
        .whereType<ActivityCompletion>()
        .toList();
  }

  Future<void> addCompletion(ActivityCompletion completion) async {
    final all = await getCompletions();
    all.add(completion);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(completionsKey, json.encode(all.map((c) => c.toMap()).toList()));
  }
}
