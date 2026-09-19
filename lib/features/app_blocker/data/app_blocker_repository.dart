import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:break_free/core/router/app_router.dart';
import 'package:break_free/features/companion/data/companion_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBlockerRepository {
  static const MethodChannel _channel = MethodChannel('com.breakfree/app_blocker');

  // We keep a local set of blocked apps to provide to the UI
  final Set<String> _blockedApps = {};
  static const String _prefsKey = 'blocked_apps_list';

  Set<String> get blockedApps => _blockedApps;

  Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
    await _loadBlockedApps();
  }

  Future<void> _loadBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApps = prefs.getStringList(_prefsKey);
      if (savedApps != null && savedApps.isNotEmpty) {
        _blockedApps.addAll(savedApps);
        // Sync with native service immediately
        await _channel.invokeMethod('setBlockedApps', {
          'blockedApps': _blockedApps.toList(),
        });
      }
    } catch (e) {
      debugPrint('Failed to load blocked apps: $e');
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onBlockedAppOpened') {
      final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
      final String packageName = args['packageName'] as String;
      final String appName = args['appName'] as String? ?? packageName;
      debugPrint('Blocked app opened: $appName ($packageName)');

      // Automatically notify the companion with readable name!
      companionRepository.syncRelapse('Tried to open: $appName');
      
      // Navigate to the intervention screen using GoRouter
      router.go('/intervention', extra: packageName);
    } else if (call.method == 'onSuspiciousTransaction') {
      final String text = call.arguments as String;
      debugPrint('Suspicious transaction detected: $text');
      router.push('/transaction-intervention', extra: text);
    } else if (call.method == 'onAdultContentDetected') {
      final String url = call.arguments as String;
      debugPrint('Adult content detected: $url');
      
      // Automatically notify the companion!
      companionRepository.syncRelapse('Adult content blocked');
      
      router.go('/adult-intervention', extra: url);
    }
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool isEnabled = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      debugPrint("Failed to check accessibility: '${e.message}'.");
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open accessibility settings: '${e.message}'.");
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
    } on PlatformException catch (e) {
      debugPrint("Failed to set blocked apps: '${e.message}'.");
    }
  }
}

// Global instance for easy access (in a real app, use Riverpod or Provider)
final appBlockerRepository = AppBlockerRepository();
