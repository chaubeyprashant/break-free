import 'dart:convert';

/// What tapping an action does in the help screen.
enum RecoveryActionKind {
  /// A step the user ticks off (put phone away, drink water, custom actions).
  checklist,

  /// Opens the timed breathing intervention.
  breathing,

  /// Opens the Urge Surfing (panic) screen.
  urgeSurfing,

  /// Opens Companion Sync so the user can reach their companion.
  contactCompanion,

  /// Opens the Replace the Habit activity picker.
  replaceHabit;

  static RecoveryActionKind fromStorageKey(String? key) {
    for (final k in RecoveryActionKind.values) {
      if (k.name == key) return k;
    }
    return RecoveryActionKind.checklist;
  }
}

class RecoveryAction {
  const RecoveryAction({
    required this.id,
    required this.title,
    this.kind = RecoveryActionKind.checklist,
    this.enabled = true,
    this.isCustom = false,
  });

  final String id;
  final String title;
  final RecoveryActionKind kind;

  /// Disabled actions stay in the plan editor but are hidden from the help screen.
  final bool enabled;

  /// Custom actions can be deleted; built-in ones can only be disabled.
  final bool isCustom;

  RecoveryAction copyWith({String? title, bool? enabled}) => RecoveryAction(
        id: id,
        title: title ?? this.title,
        kind: kind,
        enabled: enabled ?? this.enabled,
        isCustom: isCustom,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'kind': kind.name,
        'enabled': enabled,
        'isCustom': isCustom,
      };

  static RecoveryAction? fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    if (id is! String || title is! String || title.trim().isEmpty) return null;
    return RecoveryAction(
      id: id,
      title: title,
      kind: RecoveryActionKind.fromStorageKey(map['kind'] as String?),
      enabled: map['enabled'] is bool ? map['enabled'] as bool : true,
      isCustom: map['isCustom'] is bool ? map['isCustom'] as bool : false,
    );
  }

  String toJson() => json.encode(toMap());
}

/// The starting plan every user gets; all of it can be reordered, disabled
/// or extended with custom actions.
class RecoveryPlanDefaults {
  static List<RecoveryAction> actions() => const [
        RecoveryAction(id: 'phone_away', title: 'Put my phone away for 10 minutes'),
        RecoveryAction(id: 'walk', title: 'Go for a short walk'),
        RecoveryAction(id: 'water', title: 'Drink a glass of water'),
        RecoveryAction(id: 'breathing', title: 'Breathing exercise', kind: RecoveryActionKind.breathing),
        RecoveryAction(id: 'urge_surfing', title: 'Open Urge Surfing', kind: RecoveryActionKind.urgeSurfing),
        RecoveryAction(id: 'contact_companion', title: 'Contact my accountability companion', kind: RecoveryActionKind.contactCompanion),
        RecoveryAction(id: 'replace_habit', title: 'Do a replacement activity', kind: RecoveryActionKind.replaceHabit),
      ];
}
