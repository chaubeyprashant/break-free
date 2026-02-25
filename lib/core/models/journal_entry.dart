import 'dart:convert';

class JournalEntry {
  final String id;
  final DateTime date;
  final String note;
  final double moodRating; // 1.0 to 5.0
  final double urgeIntensity; // 1.0 to 10.0
  final List<String> triggersIdentified;
  final bool isRelapse;

  JournalEntry({
    required this.id,
    required this.date,
    this.note = '',
    this.moodRating = 3.0,
    this.urgeIntensity = 0.0,
    this.triggersIdentified = const [],
    this.isRelapse = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'note': note,
      'moodRating': moodRating,
      'urgeIntensity': urgeIntensity,
      'triggersIdentified': triggersIdentified,
      'isRelapse': isRelapse,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
      moodRating: map['moodRating']?.toDouble() ?? 3.0,
      urgeIntensity: map['urgeIntensity']?.toDouble() ?? 0.0,
      triggersIdentified: List<String>.from(map['triggersIdentified'] ?? []),
      isRelapse: map['isRelapse'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory JournalEntry.fromJson(String source) =>
      JournalEntry.fromMap(json.decode(source));
}
