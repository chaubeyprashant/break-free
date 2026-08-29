import 'dart:convert';

/// A logged slip, kept as structured data so patterns can be found in it.
///
/// The trigger used to survive only inside an activity-log sentence, which
/// meant the app asked the user "what triggered you?" and then never used the
/// answer for anything.
class RelapseRecord {
  final String id;
  final String? habitId;
  final String? habitTitle;
  final String trigger;
  final DateTime timestamp;

  RelapseRecord({
    required this.id,
    required this.trigger,
    required this.timestamp,
    this.habitId,
    this.habitTitle,
  });

  factory RelapseRecord.now({
    required String trigger,
    String? habitId,
    String? habitTitle,
  }) {
    final timestamp = DateTime.now();
    return RelapseRecord(
      id: '${timestamp.microsecondsSinceEpoch}',
      trigger: trigger,
      timestamp: timestamp,
      habitId: habitId,
      habitTitle: habitTitle,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'habitId': habitId,
    'habitTitle': habitTitle,
    'trigger': trigger,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RelapseRecord.fromMap(Map<String, dynamic> map) => RelapseRecord(
    id: map['id'] as String,
    habitId: map['habitId'] as String?,
    habitTitle: map['habitTitle'] as String?,
    trigger: map['trigger'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
  );

  String toJson() => json.encode(toMap());

  factory RelapseRecord.fromJson(String source) =>
      RelapseRecord.fromMap(json.decode(source) as Map<String, dynamic>);
}
