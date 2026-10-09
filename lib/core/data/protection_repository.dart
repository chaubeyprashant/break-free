import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/models/domain_normalizer.dart';
import 'package:break_free/core/models/protection_config.dart';
import 'package:break_free/core/models/protection_schedule.dart';

/// Local protection config + schedules, synced to Android SharedPreferences
/// so AccessibilityService can evaluate rules without Flutter running.
class ProtectionRepository {
  static const MethodChannel _channel = MethodChannel('com.breakfree/app_blocker');
  static const String configKey = 'protection_config_v1';
  static const String schedulesKey = 'protection_schedules_v1';

  Future<ProtectionConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(configKey);
    if (raw == null) return const ProtectionConfig();
    try {
      return ProtectionConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const ProtectionConfig();
    }
  }

  Future<void> saveConfig(ProtectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(configKey, jsonEncode(config.toJson()));
    await _syncNative(config: config, schedules: await loadSchedules());
  }

  Future<List<ProtectionSchedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(schedulesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => ProtectionSchedule.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveSchedules(List<ProtectionSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      schedulesKey,
      jsonEncode(schedules.map((s) => s.toJson()).toList()),
    );
    await _syncNative(config: await loadConfig(), schedules: schedules);
  }

  Future<List<String>> addCustomDomain(String raw) async {
    final normalized = DomainNormalizer.normalize(raw);
    if (normalized == null) {
      throw ArgumentError('Enter a valid domain like example.com');
    }
    final config = await loadConfig();
    if (config.customDomains.contains(normalized)) return config.customDomains;
    final next = config.copyWith(customDomains: [...config.customDomains, normalized]);
    await saveConfig(next);
    return next.customDomains;
  }

  Future<List<String>> removeCustomDomain(String domain) async {
    final config = await loadConfig();
    final next = config.copyWith(
      customDomains: config.customDomains.where((d) => d != domain).toList(),
    );
    await saveConfig(next);
    return next.customDomains;
  }

  Future<List<String>> replaceCustomDomain(String oldDomain, String raw) async {
    final normalized = DomainNormalizer.normalize(raw);
    if (normalized == null) {
      throw ArgumentError('Enter a valid domain like example.com');
    }
    final config = await loadConfig();
    final domains = [
      for (final d in config.customDomains) d == oldDomain ? normalized : d,
    ];
    final next = config.copyWith(customDomains: domains.toSet().toList());
    await saveConfig(next);
    return next.customDomains;
  }

  Future<void> syncToNative() async {
    await _syncNative(config: await loadConfig(), schedules: await loadSchedules());
  }

  Future<void> grantContinueAnyway({String? packageName, String? domain}) async {
    try {
      await _channel.invokeMethod('grantContinueAnyway', {
        'packageName': packageName,
        'domain': domain,
      });
    } catch (e) {
      debugPrint('grantContinueAnyway failed: $e');
    }
  }

  Future<Map<String, dynamic>> getProtectionHealth() async {
    try {
      final raw = await _channel.invokeMethod<Object?>('getProtectionHealth');
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (e) {
      debugPrint('getProtectionHealth failed: $e');
    }
    return const {};
  }

  Future<void> _syncNative({
    required ProtectionConfig config,
    required List<ProtectionSchedule> schedules,
  }) async {
    try {
      await _channel.invokeMethod('syncProtectionConfig', {
        'config': config.toJson(),
        'schedules': schedules.map((s) => s.toJson()).toList(),
      });
    } catch (e) {
      debugPrint('syncProtectionConfig failed: $e');
    }
  }
}
