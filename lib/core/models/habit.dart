import 'dart:convert';

class Habit {
  final String id;
  final String title;
  final String iconPath; // Asset path or icon code
  final DateTime startDate;
  final List<String> triggers;
  final List<DateTime> relapseDates;

  Habit({
    required this.id,
    required this.title,
    required this.iconPath,
    required this.startDate,
    this.triggers = const [],
    this.relapseDates = const [],
  });

  int get currentStreakDays {
    final now = DateTime.now();
    final lastRelapse = relapseDates.isNotEmpty ? relapseDates.last : startDate;
    return now.difference(lastRelapse).inDays;
  }

  // Calculate streak in hours for more granular updates
  int get currentStreakHours {
    final now = DateTime.now();
    final lastRelapse = relapseDates.isNotEmpty ? relapseDates.last : startDate;
    return now.difference(lastRelapse).inHours;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'iconPath': iconPath,
      'startDate': startDate.toIso8601String(),
      'triggers': triggers,
      'relapseDates': relapseDates.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      iconPath: map['iconPath'],
      startDate: DateTime.parse(map['startDate']),
      triggers: List<String>.from(map['triggers']),
      relapseDates: List<dynamic>.from(
        map['relapseDates'],
      ).map((e) => DateTime.parse(e)).toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Habit.fromJson(String source) => Habit.fromMap(json.decode(source));
}
