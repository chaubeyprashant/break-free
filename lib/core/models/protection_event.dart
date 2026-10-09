/// Local protection history events. Kept on-device by default.
enum ProtectionEventType {
  appBlocked,
  websiteBlocked,
  customDomainBlocked,
  notificationIntervention,
  protectionDisabled,
  permissionRemoved,
  scheduleStarted,
  scheduleEnded,
  configChanged,
  continueAnyway,
}

class ProtectionEvent {
  const ProtectionEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.title,
    this.detail,
    this.packageName,
    this.domain,
    this.scheduleId,
  });

  final String id;
  final ProtectionEventType type;
  final DateTime timestamp;
  final String? title;
  final String? detail;
  final String? packageName;
  final String? domain;
  final String? scheduleId;

  /// Companion-safe summary — never includes full URLs or notification bodies.
  String get companionSummary => switch (type) {
        ProtectionEventType.appBlocked => 'Blocked app attempt',
        ProtectionEventType.websiteBlocked => 'Website blocked',
        ProtectionEventType.customDomainBlocked => 'Custom domain blocked',
        ProtectionEventType.notificationIntervention => 'Notification intervention',
        ProtectionEventType.protectionDisabled => 'Protection was disabled',
        ProtectionEventType.permissionRemoved => 'Protection permission removed',
        ProtectionEventType.scheduleStarted => 'Protection schedule started',
        ProtectionEventType.scheduleEnded => 'Protection schedule ended',
        ProtectionEventType.configChanged => 'Protection settings changed',
        ProtectionEventType.continueAnyway => 'Continued past intervention',
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'detail': detail,
        'packageName': packageName,
        'domain': domain,
        'scheduleId': scheduleId,
      };

  factory ProtectionEvent.fromJson(Map<String, dynamic> json) {
    return ProtectionEvent(
      id: json['id'] as String,
      type: ProtectionEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ProtectionEventType.configChanged,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      title: json['title'] as String?,
      detail: json['detail'] as String?,
      packageName: json['packageName'] as String?,
      domain: json['domain'] as String?,
      scheduleId: json['scheduleId'] as String?,
    );
  }
}
