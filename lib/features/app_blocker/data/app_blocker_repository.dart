import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:break_free/core/data/daily_quest_repository.dart';
import 'package:break_free/core/data/protection_event_repository.dart';
import 'package:break_free/core/data/protection_repository.dart';
import 'package:break_free/core/models/protection_event.dart';
import 'package:break_free/core/router/app_router.dart';
import 'package:break_free/features/app_blocker/data/blocker_trigger.dart';
import 'package:break_free/features/companion/data/companion_repository.dart';
import 'package:break_free/features/protection/presentation/protection_intervention_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dart side of the App & Web Blocker.
///
/// Talks to MainActivity over [_channel]: pushes the blocked-app list to the
/// accessibility service, reports permission state, and receives triggers
/// (blocked app opened, website detected, suspicious notification) that
/// it turns into intervention screens.
class AppBlockerRepository {
  static const MethodChannel _channel = MethodChannel('com.breakfree/app_blocker');
  static const String _prefsKey = 'blocked_apps_list';

  final Set<String> _blockedApps = {};
  final BlockerTriggerDeduplicator _deduplicator = BlockerTriggerDeduplicator();
  final ProtectionEventRepository _events = ProtectionEventRepository();
  final ProtectionRepository _protection = ProtectionRepository();

  Set<String> get blockedApps => _blockedApps;

  Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
    await _loadBlockedApps();
    await _protection.syncToNative();
    await _consumePendingTrigger();
  }

  Future<void> reloadFromDisk() => _loadBlockedApps(replace: true);

  Future<void> _loadBlockedApps({bool replace = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApps = prefs.getStringList(_prefsKey) ?? const <String>[];
      if (replace) _blockedApps.clear();
      if (savedApps.isNotEmpty) {
        _blockedApps.addAll(savedApps);
      }
      await _channel.invokeMethod('setBlockedApps', {
        'blockedApps': _blockedApps.toList(),
      });
    } catch (e) {
      debugPrint('Failed to load blocked apps: $e');
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onBlockerTrigger') {
      final trigger = BlockerTrigger.fromMap(call.arguments);
      if (trigger != null) _dispatch(trigger);
    }
    return null;
  }

  Future<void> _consumePendingTrigger() async {
    try {
      final raw = await _channel.invokeMethod<Object?>('getPendingTrigger');
      final trigger = BlockerTrigger.fromMap(raw);
      if (trigger == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _dispatch(trigger));
    } catch (e) {
      debugPrint('No pending blocker trigger: $e');
    }
  }

  void _dispatch(BlockerTrigger trigger) {
    if (!_deduplicator.shouldHandle(trigger)) return;

    switch (trigger.type) {
      case BlockerTriggerType.blockedApp:
        final packageName = trigger.packageName ?? 'Unknown App';
        final appName = trigger.appName ?? packageName;
        debugPrint('Blocked app opened: $appName ($packageName)');
        DailyQuestRepository().recordBlockedAttempt(DateTime.now());
        _recordAndMaybeNotify(
          ProtectionEvent(
            id: '${trigger.id}',
            type: ProtectionEventType.appBlocked,
            timestamp: DateTime.now(),
            title: 'Tried to open $appName',
            packageName: packageName,
          ),
          companionKey: 'blockedAttempts',
        );
        router.go(
          '/protection/intervention',
          extra: ProtectionInterventionArgs(
            kind: 'app',
            packageName: packageName,
            appName: appName,
            reasonText: 'Trying to open $appName',
          ),
        );
      case BlockerTriggerType.adultContent:
      case BlockerTriggerType.websiteBlocked:
        final category = trigger.category ??
            (trigger.type == BlockerTriggerType.adultContent ? 'adult' : 'website');
        final isCustom = category == 'custom';
        _recordAndMaybeNotify(
          ProtectionEvent(
            id: '${trigger.id}',
            type: isCustom
                ? ProtectionEventType.customDomainBlocked
                : ProtectionEventType.websiteBlocked,
            timestamp: DateTime.now(),
            title: isCustom ? 'Custom domain blocked' : 'Website blocked',
            domain: trigger.keyword,
            detail: category,
          ),
          companionKey: 'blockedAttempts',
        );
        router.go(
          '/protection/intervention',
          extra: ProtectionInterventionArgs(
            kind: 'website',
            url: trigger.url,
            category: category,
            reasonText: 'Website protection matched “${trigger.keyword ?? category}” in a supported browser',
          ),
        );
      case BlockerTriggerType.suspiciousTransaction:
        _recordAndMaybeNotify(
          ProtectionEvent(
            id: '${trigger.id}',
            type: ProtectionEventType.notificationIntervention,
            timestamp: DateTime.now(),
            title: 'Notification intervention',
            detail: trigger.keyword,
          ),
          companionKey: 'blockedAttempts',
        );
        router.push(
          '/protection/intervention',
          extra: ProtectionInterventionArgs(
            kind: 'notification',
            reasonText: trigger.text ?? 'A notification matched a risk keyword',
            category: trigger.category,
          ),
        );
    }
  }

  Future<void> _recordAndMaybeNotify(
    ProtectionEvent event, {
    required String companionKey,
  }) async {
    try {
      await _events.add(event);
      final config = await _protection.loadConfig();
      final alerts = config.companionAlerts;
      final allow = switch (companionKey) {
        'blockedAttempts' => alerts.blockedAttempts,
        'protectionDisabled' => alerts.protectionDisabled,
        'permissionRemoved' => alerts.permissionRemoved,
        'configChanged' => alerts.configChanged,
        _ => false,
      };
      if (!allow) return;
      final companionId = await companionRepository.getCompanionId();
      if (companionId == null || companionId.isEmpty) return;
      await companionRepository.syncProtectionAlert(event.companionSummary);
    } catch (e) {
      debugPrint('Failed to record protection event: $e');
    }
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool? isEnabled = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return isEnabled ?? false;
    } catch (e) {
      debugPrint("Failed to check accessibility: '$e'.");
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint("Failed to open accessibility settings: '$e'.");
    }
  }

  Future<List<String>> getSupportedBrowsers() async {
    try {
      final list = await _channel.invokeMethod<List<Object?>>('getSupportedBrowsers');
      return list?.whereType<String>().toList() ?? const [];
    } catch (e) {
      debugPrint("Failed to read supported browsers: '$e'.");
      return const [];
    }
  }

  Future<void> toggleAppBlock(String packageName, bool block) async {
    if (block) {
      _blockedApps.add(packageName);
    } else {
      _blockedApps.remove(packageName);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _blockedApps.toList());

      await _channel.invokeMethod('setBlockedApps', {
        'blockedApps': _blockedApps.toList(),
      });
    } catch (e) {
      debugPrint("Failed to set blocked apps: '$e'.");
    }
  }
}

final appBlockerRepository = AppBlockerRepository();
