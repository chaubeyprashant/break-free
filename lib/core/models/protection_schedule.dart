/// A user-defined protection window. End may be earlier than start (crosses midnight).
class ProtectionSchedule {
  const ProtectionSchedule({
    required this.id,
    required this.name,
    required this.startMinutes,
    required this.endMinutes,
    required this.daysOfWeek,
    required this.appPackages,
    required this.webCategories,
    this.enabled = true,
  });

  final String id;
  final String name;

  /// Minutes from midnight [0, 1440).
  final int startMinutes;
  final int endMinutes;

  /// DateTime.weekday values: 1=Mon … 7=Sun.
  final Set<int> daysOfWeek;

  /// Empty = use global blocked-apps list while schedule is active.
  final Set<String> appPackages;

  /// Category ids: adult, gambling, custom.
  final Set<String> webCategories;

  final bool enabled;

  bool get crossesMidnight => endMinutes <= startMinutes;

  /// Whether [now] falls inside this schedule (handles overnight windows).
  bool isActiveAt(DateTime now) {
    if (!enabled || daysOfWeek.isEmpty) return false;
    final minutes = now.hour * 60 + now.minute;
    if (!crossesMidnight) {
      if (!daysOfWeek.contains(now.weekday)) return false;
      return minutes >= startMinutes && minutes < endMinutes;
    }
    // 22:00 → 07:00: active if after start on listed day, or before end on the next calendar day
    // whose previous day is listed.
    if (minutes >= startMinutes) {
      return daysOfWeek.contains(now.weekday);
    }
    if (minutes < endMinutes) {
      final prev = now.weekday == 1 ? 7 : now.weekday - 1;
      return daysOfWeek.contains(prev);
    }
    return false;
  }

  String get timeLabel {
    String fmt(int m) {
      final h = m ~/ 60;
      final min = m % 60;
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:${min.toString().padLeft(2, '0')} $period';
    }
    return '${fmt(startMinutes)} → ${fmt(endMinutes)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'daysOfWeek': daysOfWeek.toList()..sort(),
        'appPackages': appPackages.toList(),
        'webCategories': webCategories.toList(),
        'enabled': enabled,
      };

  factory ProtectionSchedule.fromJson(Map<String, dynamic> json) {
    return ProtectionSchedule(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Schedule',
      startMinutes: (json['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (json['endMinutes'] as num?)?.toInt() ?? 0,
      daysOfWeek: {
        for (final d in (json['daysOfWeek'] as List?) ?? const [])
          if (d is num) d.toInt(),
      },
      appPackages: {
        for (final p in (json['appPackages'] as List?) ?? const [])
          if (p is String) p,
      },
      webCategories: {
        for (final c in (json['webCategories'] as List?) ?? const [])
          if (c is String) c,
      },
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  ProtectionSchedule copyWith({
    String? name,
    int? startMinutes,
    int? endMinutes,
    Set<int>? daysOfWeek,
    Set<String>? appPackages,
    Set<String>? webCategories,
    bool? enabled,
  }) {
    return ProtectionSchedule(
      id: id,
      name: name ?? this.name,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      appPackages: appPackages ?? this.appPackages,
      webCategories: webCategories ?? this.webCategories,
      enabled: enabled ?? this.enabled,
    );
  }
}
