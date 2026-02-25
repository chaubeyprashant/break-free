import 'dart:convert';

/// Streak protection: freezes (1/week), shield (1/week at level 3+), grace period.
class StreakPolicy {
  /// Freezes allowed per week (resets every Monday or first day of week).
  static const int freezesPerWeek = 1;
  /// Streak shield available once per week when user is level 3+.
  static const int shieldsPerWeek = 1;
  /// Grace period in hours (e.g. complete day until 2am next day).
  static const int gracePeriodHours = 2;

  List<DateTime> freezeUsedDates;
  List<DateTime> shieldUsedDates;

  StreakPolicy({
    this.freezeUsedDates = const [],
    this.shieldUsedDates = const [],
  });

  /// Freezes used in the current week (week starts Monday).
  int get freezesUsedThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return freezeUsedDates.where((d) => d.isAfter(startOfWeekMidnight)).length;
  }

  int get shieldsUsedThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return shieldUsedDates.where((d) => d.isAfter(startOfWeekMidnight)).length;
  }

  bool get canUseFreeze => freezesUsedThisWeek < freezesPerWeek;
  bool get canUseShield => shieldsUsedThisWeek < shieldsPerWeek;

  /// User can use shield only at level 3+ (checked in provider with level).
  bool canUseShieldAtLevel(int level) => level >= 3 && canUseShield;

  Map<String, dynamic> toMap() => {
        'freezeUsedDates': freezeUsedDates.map((e) => e.toIso8601String()).toList(),
        'shieldUsedDates': shieldUsedDates.map((e) => e.toIso8601String()).toList(),
      };

  factory StreakPolicy.fromMap(Map<String, dynamic> map) => StreakPolicy(
        freezeUsedDates: (map['freezeUsedDates'] as List<dynamic>?)
                ?.map((e) => DateTime.parse(e as String))
                .toList() ??
            [],
        shieldUsedDates: (map['shieldUsedDates'] as List<dynamic>?)
                ?.map((e) => DateTime.parse(e as String))
                .toList() ??
            [],
      );

  String toJson() => json.encode(toMap());
  factory StreakPolicy.fromJson(String s) => StreakPolicy.fromMap(json.decode(s) as Map<String, dynamic>);
}
