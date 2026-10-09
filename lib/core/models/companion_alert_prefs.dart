/// Which protection events may be mirrored to a linked companion (with consent).
class CompanionAlertPrefs {
  const CompanionAlertPrefs({
    this.blockedAttempts = true,
    this.protectionDisabled = true,
    this.permissionRemoved = true,
    this.configChanged = false,
    this.relapseEvents = true,
  });

  final bool blockedAttempts;
  final bool protectionDisabled;
  final bool permissionRemoved;
  final bool configChanged;
  final bool relapseEvents;

  Map<String, dynamic> toJson() => {
        'blockedAttempts': blockedAttempts,
        'protectionDisabled': protectionDisabled,
        'permissionRemoved': permissionRemoved,
        'configChanged': configChanged,
        'relapseEvents': relapseEvents,
      };

  factory CompanionAlertPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanionAlertPrefs();
    return CompanionAlertPrefs(
      blockedAttempts: json['blockedAttempts'] as bool? ?? true,
      protectionDisabled: json['protectionDisabled'] as bool? ?? true,
      permissionRemoved: json['permissionRemoved'] as bool? ?? true,
      configChanged: json['configChanged'] as bool? ?? false,
      relapseEvents: json['relapseEvents'] as bool? ?? true,
    );
  }

  CompanionAlertPrefs copyWith({
    bool? blockedAttempts,
    bool? protectionDisabled,
    bool? permissionRemoved,
    bool? configChanged,
    bool? relapseEvents,
  }) {
    return CompanionAlertPrefs(
      blockedAttempts: blockedAttempts ?? this.blockedAttempts,
      protectionDisabled: protectionDisabled ?? this.protectionDisabled,
      permissionRemoved: permissionRemoved ?? this.permissionRemoved,
      configChanged: configChanged ?? this.configChanged,
      relapseEvents: relapseEvents ?? this.relapseEvents,
    );
  }
}
