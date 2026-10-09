import 'package:flutter/foundation.dart';
import 'package:break_free/core/data/protection_event_repository.dart';
import 'package:break_free/core/data/protection_repository.dart';
import 'package:break_free/core/models/companion_alert_prefs.dart';
import 'package:break_free/core/models/protection_config.dart';
import 'package:break_free/core/models/protection_event.dart';
import 'package:break_free/core/models/protection_schedule.dart';
import 'package:break_free/features/app_blocker/data/app_blocker_repository.dart';
import 'package:break_free/features/companion/data/companion_repository.dart';
import 'package:break_free/features/scanner/data/notification_scanner_repository.dart';

class ProtectionProvider extends ChangeNotifier {
  ProtectionProvider({
    ProtectionRepository? repository,
    ProtectionEventRepository? events,
    AppBlockerRepository? blocker,
    NotificationScannerRepository? scanner,
    CompanionRepository? companion,
  })  : _repo = repository ?? ProtectionRepository(),
        _events = events ?? ProtectionEventRepository(),
        _blocker = blocker ?? appBlockerRepository,
        _scanner = scanner ?? NotificationScannerRepository(),
        _companion = companion ?? companionRepository {
    reload();
  }

  final ProtectionRepository _repo;
  final ProtectionEventRepository _events;
  final AppBlockerRepository _blocker;
  final NotificationScannerRepository _scanner;
  final CompanionRepository _companion;

  ProtectionConfig _config = const ProtectionConfig();
  List<ProtectionSchedule> _schedules = const [];
  List<ProtectionEvent> _recentEvents = const [];
  List<String> _supportedBrowsers = const [];
  bool _accessibilityEnabled = false;
  bool _notificationAccessEnabled = false;
  bool _loaded = false;
  String? _error;
  bool? _lastAccessibility;

  ProtectionConfig get config => _config;
  List<ProtectionSchedule> get schedules => List.unmodifiable(_schedules);
  List<ProtectionEvent> get recentEvents => List.unmodifiable(_recentEvents);
  List<String> get supportedBrowsers => List.unmodifiable(_supportedBrowsers);
  bool get accessibilityEnabled => _accessibilityEnabled;
  bool get notificationAccessEnabled => _notificationAccessEnabled;
  bool get isLoaded => _loaded;
  String? get error => _error;

  bool get isProtectionActive =>
      _config.protectionEnabled && _accessibilityEnabled;

  List<ProtectionSchedule> get activeSchedulesNow {
    final now = DateTime.now();
    return _schedules.where((s) => s.isActiveAt(now)).toList();
  }

  Future<void> reload() async {
    try {
      _config = await _repo.loadConfig();
      _schedules = await _repo.loadSchedules();
      _recentEvents = await _events.load(limit: 40);
      _supportedBrowsers = await _blocker.getSupportedBrowsers();
      _accessibilityEnabled = await _blocker.isAccessibilityServiceEnabled();
      _notificationAccessEnabled = await _scanner.isScannerEnabled();
      await _repo.syncToNative();
      await _detectPermissionTamper();
      _error = null;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _detectPermissionTamper() async {
    if (_lastAccessibility == true && !_accessibilityEnabled) {
      await recordEvent(
        ProtectionEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: ProtectionEventType.permissionRemoved,
          timestamp: DateTime.now(),
          title: 'Accessibility permission removed',
        ),
        notifyCompanion: _config.companionAlerts.permissionRemoved,
      );
    }
    _lastAccessibility = _accessibilityEnabled;
  }

  Future<void> updateConfig(ProtectionConfig next, {bool configChangedAlert = false}) async {
    final wasEnabled = _config.protectionEnabled;
    _config = next;
    notifyListeners();
    await _repo.saveConfig(next);
    if (wasEnabled && !next.protectionEnabled) {
      await recordEvent(
        ProtectionEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: ProtectionEventType.protectionDisabled,
          timestamp: DateTime.now(),
          title: 'Protection was disabled',
        ),
        notifyCompanion: next.companionAlerts.protectionDisabled,
      );
    }
    if (configChangedAlert && next.companionAlerts.configChanged) {
      await recordEvent(
        ProtectionEvent(
          id: '${DateTime.now().millisecondsSinceEpoch}_cfg',
          type: ProtectionEventType.configChanged,
          timestamp: DateTime.now(),
          title: 'Protection settings changed',
        ),
        notifyCompanion: true,
      );
    }
  }

  Future<void> setSchedules(List<ProtectionSchedule> schedules) async {
    _schedules = schedules;
    notifyListeners();
    await _repo.saveSchedules(schedules);
  }

  Future<void> upsertSchedule(ProtectionSchedule schedule) async {
    final list = [..._schedules];
    final idx = list.indexWhere((s) => s.id == schedule.id);
    if (idx >= 0) {
      list[idx] = schedule;
    } else {
      list.add(schedule);
    }
    await setSchedules(list);
  }

  Future<void> deleteSchedule(String id) async {
    await setSchedules(_schedules.where((s) => s.id != id).toList());
  }

  Future<void> addDomain(String raw) async {
    final domains = await _repo.addCustomDomain(raw);
    _config = _config.copyWith(customDomains: domains);
    notifyListeners();
  }

  Future<void> removeDomain(String domain) async {
    final domains = await _repo.removeCustomDomain(domain);
    _config = _config.copyWith(customDomains: domains);
    notifyListeners();
  }

  Future<void> editDomain(String oldDomain, String raw) async {
    final domains = await _repo.replaceCustomDomain(oldDomain, raw);
    _config = _config.copyWith(customDomains: domains);
    notifyListeners();
  }

  Future<void> updateCompanionAlerts(CompanionAlertPrefs prefs) async {
    await updateConfig(_config.copyWith(companionAlerts: prefs));
  }

  Future<void> recordEvent(
    ProtectionEvent event, {
    bool notifyCompanion = false,
  }) async {
    await _events.add(event);
    _recentEvents = await _events.load(limit: 40);
    notifyListeners();
    if (!notifyCompanion) return;
    try {
      final companionId = await _companion.getCompanionId();
      if (companionId == null || companionId.isEmpty) return;
      await _companion.syncProtectionAlert(event.companionSummary);
    } catch (e) {
      debugPrint('Companion protection alert failed: $e');
    }
  }

  Future<void> grantContinueAnyway({String? packageName, String? domain}) async {
    await _repo.grantContinueAnyway(packageName: packageName, domain: domain);
    await recordEvent(
      ProtectionEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: ProtectionEventType.continueAnyway,
        timestamp: DateTime.now(),
        title: 'Continued past intervention',
        packageName: packageName,
        domain: domain,
      ),
    );
  }

  Future<void> openAccessibilitySettings() => _blocker.openAccessibilitySettings();
  Future<void> openNotificationSettings() => _scanner.openScannerSettings();
}
