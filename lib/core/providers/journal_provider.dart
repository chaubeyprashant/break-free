import 'package:flutter/material.dart';
import 'package:break_free/core/data/journal_repository.dart';
import 'package:break_free/core/models/journal_entry.dart';

class JournalProvider extends ChangeNotifier {
  JournalProvider(this._repository) {
    _load();
  }

  final JournalRepository _repository;

  List<JournalEntry> _entries = [];
  bool _loaded = false;
  String? _error;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoaded => _loaded;
  String? get error => _error;
  bool get isEmpty => _loaded && _entries.isEmpty;

  Future<void> _load() async {
    try {
      _entries = await _repository.getEntries();
      _error = null;
    } catch (e) {
      _error = 'Could not load journal entries.';
      _entries = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() => _load();

  JournalEntry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<JournalEntry> create({
    required String note,
    required double moodRating,
    double urgeIntensity = 0,
    List<String> triggers = const [],
    bool isRelapse = false,
    String? habitId,
    String? copingMethod,
    DateTime? date,
  }) async {
    final entry = JournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: date ?? DateTime.now(),
      note: note.trim(),
      moodRating: moodRating.clamp(1.0, 5.0),
      urgeIntensity: urgeIntensity <= 0 ? 0.0 : urgeIntensity.clamp(1.0, 10.0),
      triggersIdentified: triggers.where((t) => t.trim().isNotEmpty).toList(),
      isRelapse: isRelapse,
      habitId: habitId,
      copingMethod: copingMethod?.trim().isEmpty == true ? null : copingMethod?.trim(),
    );
    await _repository.addEntry(entry);
    _entries = [entry, ..._entries];
    _error = null;
    notifyListeners();
    return entry;
  }

  Future<JournalEntry?> update(JournalEntry updated) async {
    final index = _entries.indexWhere((e) => e.id == updated.id);
    if (index == -1) return null;
    await _repository.updateEntry(updated);
    _entries = [..._entries]..[index] = updated;
    _entries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    return updated;
  }

  Future<void> delete(String id) async {
    await _repository.deleteEntry(id);
    _entries = _entries.where((e) => e.id != id).toList();
    notifyListeners();
  }
}
