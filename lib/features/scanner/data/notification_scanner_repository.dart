import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class NotificationScannerRepository {
  final MethodChannel _channel = const MethodChannel('com.breakfree/app_blocker'); // Reusing existing channel

  Future<bool> isScannerEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isNotificationServiceEnabled');
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> openScannerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      // Handle error
    }
  }
}
