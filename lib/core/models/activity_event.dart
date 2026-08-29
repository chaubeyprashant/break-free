import 'dart:convert';

/// Something the user did, recorded locally so the dashboard can show a real
/// history instead of placeholder rows.
class ActivityEvent {
  /// Matches the icon types the dashboard list understands.
  static const String checkIn = 'check_in';
  static const String relapse = 'relapse';
  static const String achievement = 'achievement';

  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;

  ActivityEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  factory ActivityEvent.now({
    required String type,
    required String title,
    required String description,
  }) {
    final timestamp = DateTime.now();
    return ActivityEvent(
      id: '${timestamp.microsecondsSinceEpoch}',
      type: type,
      title: title,
      description: description,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActivityEvent.fromMap(Map<String, dynamic> map) => ActivityEvent(
    id: map['id'] as String,
    type: map['type'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
  );

  String toJson() => json.encode(toMap());

  factory ActivityEvent.fromJson(String source) =>
      ActivityEvent.fromMap(json.decode(source) as Map<String, dynamic>);
}
