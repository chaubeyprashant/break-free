import 'dart:convert';
import 'package:break_free/core/models/urge_intervention.dart';

/// What set the urge off. Order is the order shown in the urge flow.
enum UrgeTrigger {
  stress('Stress'),
  boredom('Boredom'),
  loneliness('Loneliness'),
  anger('Anger'),
  socialMedia('Social media'),
  nighttime('Nighttime'),
  environment('Environment'),
  other('Other');

  const UrgeTrigger(this.label);

  final String label;

  /// Stored value; kept stable even if a label is reworded later.
  String get storageKey => name;

  static UrgeTrigger? fromStorageKey(String? key) {
    for (final t in UrgeTrigger.values) {
      if (t.name == key) return t;
    }
    return null;
  }
}

/// What happened after the urge was logged.
enum UrgeOutcome {
  /// Logged, no intervention finished (either skipped or still open).
  unresolved('Unresolved'),

  /// An intervention was started but stopped before the timer ended.
  stoppedEarly('Stopped early'),

  /// An intervention was completed.
  rodeItOut('Rode it out');

  const UrgeOutcome(this.label);
  final String label;

  static UrgeOutcome fromStorageKey(String? key) {
    for (final o in UrgeOutcome.values) {
      if (o.name == key) return o;
    }
    return UrgeOutcome.unresolved;
  }
}

/// One completed pass through the urge flow.
class UrgeEvent {
  static const int minIntensity = 1;
  static const int maxIntensity = 10;

  UrgeEvent({
    required this.id,
    required this.timestamp,
    required this.intensity,
    required this.trigger,
    this.intervention,
    this.handledAt,
    this.outcome = UrgeOutcome.unresolved,
  }) : assert(intensity >= minIntensity && intensity <= maxIntensity);

  final String id;
  final DateTime timestamp;

  /// 1 (barely there) to 10 (overwhelming).
  final int intensity;
  final UrgeTrigger trigger;

  /// The intervention the user chose (completed or not).
  final UrgeIntervention? intervention;

  /// Set only when an intervention was completed.
  final DateTime? handledAt;
  final UrgeOutcome outcome;

  bool get isHandled => handledAt != null;

  UrgeEvent copyWith({UrgeIntervention? intervention, DateTime? handledAt, UrgeOutcome? outcome}) => UrgeEvent(
        id: id,
        timestamp: timestamp,
        intensity: intensity,
        trigger: trigger,
        intervention: intervention ?? this.intervention,
        handledAt: handledAt ?? this.handledAt,
        outcome: outcome ?? this.outcome,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'intensity': intensity,
        'trigger': trigger.storageKey,
        if (intervention != null) 'intervention': intervention!.storageKey,
        if (handledAt != null) 'handledAt': handledAt!.toIso8601String(),
        'outcome': outcome.name,
      };

  /// Returns null for records that cannot be read, so one bad entry does not
  /// hide the rest of the history.
  static UrgeEvent? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final timestamp = DateTime.tryParse(map['timestamp'] as String? ?? '');
    final intensity = map['intensity'];
    final trigger = UrgeTrigger.fromStorageKey(map['trigger'] as String?);
    if (id is! String ||
        timestamp == null ||
        intensity is! int ||
        intensity < minIntensity ||
        intensity > maxIntensity ||
        trigger == null) {
      return null;
    }
    return UrgeEvent(
      id: id,
      timestamp: timestamp,
      intensity: intensity,
      trigger: trigger,
      intervention: UrgeIntervention.fromStorageKey(map['intervention'] as String?),
      handledAt: DateTime.tryParse(map['handledAt'] as String? ?? ''),
      // Records from before outcomes existed: a handled urge was always a completed intervention.
      outcome: map.containsKey('outcome')
          ? UrgeOutcome.fromStorageKey(map['outcome'] as String?)
          : (map['handledAt'] != null ? UrgeOutcome.rodeItOut : UrgeOutcome.unresolved),
    );
  }

  String toJson() => json.encode(toMap());

  static UrgeEvent? fromJson(String source) {
    final decoded = json.decode(source);
    return decoded is Map<String, dynamic> ? fromMap(decoded) : null;
  }
}
