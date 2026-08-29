import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/relapse_record.dart';

/// Stores logged slips, newest first, so the app can show the user their own
/// patterns back.
class RelapseLogRepository {
  static const String _key = 'relapse_log';

  /// Enough history to see a pattern without growing without bound.
  static const int maxEntries = 200;

  Future<List<RelapseRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_key);
    if (encoded == null) return [];

    final decoded = json.decode(encoded) as List<dynamic>;
    return decoded
        .map((e) => RelapseRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> record(RelapseRecord record) async {
    final records = await getRecords();
    records.insert(0, record);
    if (records.length > maxEntries) {
      records.removeRange(maxEntries, records.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(records.map((r) => r.toMap()).toList()),
    );
  }
}
