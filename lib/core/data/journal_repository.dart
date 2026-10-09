import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/journal_entry.dart';

/// Local-only journal store (SharedPreferences), same pattern as UrgeRepository.
class JournalRepository {
  static const String entriesKey = 'journal_entries';

  Future<List<JournalEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(entriesKey);
    if (encoded == null) return [];

    final decoded = json.decode(encoded);
    if (decoded is! List) return [];
    final entries = decoded
        .whereType<Map>()
        .map((e) => JournalEntry.fromMap(Map<String, dynamic>.from(e)))
        .whereType<JournalEntry>()
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> saveEntries(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(entriesKey, json.encode(entries.map((e) => e.toMap()).toList()));
  }

  Future<void> addEntry(JournalEntry entry) async {
    final entries = await getEntries();
    entries.insert(0, entry);
    await saveEntries(entries);
  }

  Future<void> updateEntry(JournalEntry updated) async {
    final entries = await getEntries();
    final index = entries.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    entries[index] = updated;
    await saveEntries(entries);
  }

  Future<void> deleteEntry(String id) async {
    final entries = await getEntries();
    entries.removeWhere((e) => e.id == id);
    await saveEntries(entries);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(entriesKey);
  }
}
