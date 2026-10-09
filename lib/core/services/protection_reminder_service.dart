import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:break_free/core/models/danger_window.dart';

/// Something that can schedule (and cancel) the single danger-window
/// reminder. Abstracted so the provider can be unit tested without the
/// notifications plugin.
abstract class ProtectionReminderScheduler {
  /// Schedules one reminder for the next start of [window].
  Future<void> scheduleFor(DangerWindow window, {DateTime? now});

  Future<void> cancel();
}

/// Local-notification implementation. Only one reminder exists at a time
/// (fixed id), so re-scheduling replaces the previous one. It is
/// re-scheduled on every app start while the reminder is enabled, which keeps
/// it correct across clock changes without needing exact-alarm permission.
class LocalProtectionReminderService implements ProtectionReminderScheduler {
  LocalProtectionReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int notificationId = 4242;
  static const String channelId = 'danger_window';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  @override
  Future<void> scheduleFor(DangerWindow window, {DateTime? now}) async {
    await initialize();
    final start = window.nextStart(now ?? DateTime.now());
    // TZDateTime.from converts the absolute instant, so the local zone name is irrelevant.
    final when = tz.TZDateTime.from(start, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Your ${window.label} window is starting',
        body: 'Most of your logged urges land in this period. Have a plan ready: breathe, move, or distract.',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Danger window reminders',
            channelDescription: 'A heads-up before the period in which your logged urges cluster.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Could not schedule protection reminder: $e');
    }
  }

  @override
  Future<void> cancel() async {
    await initialize();
    try {
      await _plugin.cancel(id: notificationId);
    } catch (e) {
      debugPrint('Could not cancel protection reminder: $e');
    }
  }
}
