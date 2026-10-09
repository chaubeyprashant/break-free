import 'package:break_free/core/models/companion_alert_prefs.dart';

/// On-device protection preferences synced to Android SharedPreferences.
class ProtectionConfig {
  const ProtectionConfig({
    this.protectionEnabled = true,
    this.alwaysOnApps = true,
    this.webAdultEnabled = true,
    this.webGamblingEnabled = false,
    this.customDomainsEnabled = true,
    this.allowContinueAnyway = true,
    this.continueAnywayMinutes = 5,
    this.scannerEnabled = true,
    this.scannerCategories = const {
      'smoking',
      'alcohol',
      'junk_food',
      'gambling',
      'shopping',
    },
    this.scannerCooldownSeconds = 120,
    this.companionAlerts = const CompanionAlertPrefs(),
    this.customDomains = const [],
    this.allowlistDomains = const [],
  });

  final bool protectionEnabled;

  /// When true, blocked apps are enforced outside schedules too.
  final bool alwaysOnApps;

  final bool webAdultEnabled;
  final bool webGamblingEnabled;
  final bool customDomainsEnabled;
  final bool allowContinueAnyway;
  final int continueAnywayMinutes;
  final bool scannerEnabled;
  final Set<String> scannerCategories;
  final int scannerCooldownSeconds;
  final CompanionAlertPrefs companionAlerts;
  final List<String> customDomains;
  final List<String> allowlistDomains;

  Map<String, dynamic> toJson() => {
        'protectionEnabled': protectionEnabled,
        'alwaysOnApps': alwaysOnApps,
        'webAdultEnabled': webAdultEnabled,
        'webGamblingEnabled': webGamblingEnabled,
        'customDomainsEnabled': customDomainsEnabled,
        'allowContinueAnyway': allowContinueAnyway,
        'continueAnywayMinutes': continueAnywayMinutes,
        'scannerEnabled': scannerEnabled,
        'scannerCategories': scannerCategories.toList(),
        'scannerCooldownSeconds': scannerCooldownSeconds,
        'companionAlerts': companionAlerts.toJson(),
        'customDomains': customDomains,
        'allowlistDomains': allowlistDomains,
      };

  factory ProtectionConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ProtectionConfig();
    final companion = json['companionAlerts'];
    return ProtectionConfig(
      protectionEnabled: json['protectionEnabled'] as bool? ?? true,
      alwaysOnApps: json['alwaysOnApps'] as bool? ?? true,
      webAdultEnabled: json['webAdultEnabled'] as bool? ?? true,
      webGamblingEnabled: json['webGamblingEnabled'] as bool? ?? false,
      customDomainsEnabled: json['customDomainsEnabled'] as bool? ?? true,
      allowContinueAnyway: json['allowContinueAnyway'] as bool? ?? true,
      continueAnywayMinutes: (json['continueAnywayMinutes'] as num?)?.toInt() ?? 5,
      scannerEnabled: json['scannerEnabled'] as bool? ?? true,
      scannerCategories: {
        for (final c in (json['scannerCategories'] as List?) ??
            const ['smoking', 'alcohol', 'junk_food', 'gambling', 'shopping'])
          if (c is String) c,
      },
      scannerCooldownSeconds: (json['scannerCooldownSeconds'] as num?)?.toInt() ?? 120,
      companionAlerts: CompanionAlertPrefs.fromJson(
        companion is Map<String, dynamic> ? companion : null,
      ),
      customDomains: [
        for (final d in (json['customDomains'] as List?) ?? const [])
          if (d is String) d,
      ],
      allowlistDomains: [
        for (final d in (json['allowlistDomains'] as List?) ?? const [])
          if (d is String) d,
      ],
    );
  }

  ProtectionConfig copyWith({
    bool? protectionEnabled,
    bool? alwaysOnApps,
    bool? webAdultEnabled,
    bool? webGamblingEnabled,
    bool? customDomainsEnabled,
    bool? allowContinueAnyway,
    int? continueAnywayMinutes,
    bool? scannerEnabled,
    Set<String>? scannerCategories,
    int? scannerCooldownSeconds,
    CompanionAlertPrefs? companionAlerts,
    List<String>? customDomains,
    List<String>? allowlistDomains,
  }) {
    return ProtectionConfig(
      protectionEnabled: protectionEnabled ?? this.protectionEnabled,
      alwaysOnApps: alwaysOnApps ?? this.alwaysOnApps,
      webAdultEnabled: webAdultEnabled ?? this.webAdultEnabled,
      webGamblingEnabled: webGamblingEnabled ?? this.webGamblingEnabled,
      customDomainsEnabled: customDomainsEnabled ?? this.customDomainsEnabled,
      allowContinueAnyway: allowContinueAnyway ?? this.allowContinueAnyway,
      continueAnywayMinutes: continueAnywayMinutes ?? this.continueAnywayMinutes,
      scannerEnabled: scannerEnabled ?? this.scannerEnabled,
      scannerCategories: scannerCategories ?? this.scannerCategories,
      scannerCooldownSeconds: scannerCooldownSeconds ?? this.scannerCooldownSeconds,
      companionAlerts: companionAlerts ?? this.companionAlerts,
      customDomains: customDomains ?? this.customDomains,
      allowlistDomains: allowlistDomains ?? this.allowlistDomains,
    );
  }
}
