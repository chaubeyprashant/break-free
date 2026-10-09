import 'dart:convert';

/// Local journal reflection. Kept separate from [UrgeEvent] so urge history
/// is not duplicated — relapse/urge flows may *optionally* create an entry.
class JournalEntry {
  JournalEntry({
    required this.id,
    required this.date,
    this.note = '',
    this.moodRating = 3.0,
    this.urgeIntensity = 0.0,
    this.triggersIdentified = const [],
    this.isRelapse = false,
    this.habitId,
    this.copingMethod,
  });

  final String id;
  final DateTime date;
  final String note;

  /// 1.0 (low) to 5.0 (high).
  final double moodRating;

  /// 0 when not applicable; otherwise 1.0–10.0.
  final double urgeIntensity;
  final List<String> triggersIdentified;
  final bool isRelapse;

  /// Optional link to a [Habit.id].
  final String? habitId;

  /// Optional successful coping method (e.g. "Breathe", "Walk").
  final String? copingMethod;

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    String? note,
    double? moodRating,
    double? urgeIntensity,
    List<String>? triggersIdentified,
    bool? isRelapse,
    String? habitId,
    String? copingMethod,
    bool clearHabitId = false,
    bool clearCopingMethod = false,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      note: note ?? this.note,
      moodRating: moodRating ?? this.moodRating,
      urgeIntensity: urgeIntensity ?? this.urgeIntensity,
      triggersIdentified: triggersIdentified ?? this.triggersIdentified,
      isRelapse: isRelapse ?? this.isRelapse,
      habitId: clearHabitId ? null : (habitId ?? this.habitId),
      copingMethod: clearCopingMethod ? null : (copingMethod ?? this.copingMethod),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'note': note,
      'moodRating': moodRating,
      'urgeIntensity': urgeIntensity,
      'triggersIdentified': triggersIdentified,
      'isRelapse': isRelapse,
      if (habitId != null) 'habitId': habitId,
      if (copingMethod != null && copingMethod!.isNotEmpty) 'copingMethod': copingMethod,
    };
  }

  /// Returns null for corrupt records so one bad entry cannot hide history.
  static JournalEntry? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final date = DateTime.tryParse(map['date'] as String? ?? '');
    if (id is! String || date == null) return null;

    final mood = (map['moodRating'] as num?)?.toDouble() ?? 3.0;
    final urge = (map['urgeIntensity'] as num?)?.toDouble() ?? 0.0;
    final triggers = map['triggersIdentified'];
    return JournalEntry(
      id: id,
      date: date,
      note: map['note'] as String? ?? '',
      moodRating: mood.clamp(1.0, 5.0),
      urgeIntensity: urge <= 0 ? 0.0 : urge.clamp(1.0, 10.0),
      triggersIdentified: triggers is List ? List<String>.from(triggers.map((e) => '$e')) : const [],
      isRelapse: map['isRelapse'] == true,
      habitId: map['habitId'] as String?,
      copingMethod: map['copingMethod'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  static JournalEntry? fromJson(String source) {
    final decoded = json.decode(source);
    return decoded is Map<String, dynamic> ? fromMap(decoded) : null;
  }
}
