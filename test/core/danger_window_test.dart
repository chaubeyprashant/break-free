import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/danger_window_repository.dart';
import 'package:break_free/core/models/danger_window.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/providers/danger_window_provider.dart';
import 'package:break_free/core/services/protection_reminder_service.dart';

UrgeEvent urgeAt(int day, int hour, [int minute = 0]) => UrgeEvent(
      id: 'd$day-h$hour-m$minute',
      timestamp: DateTime(2026, 9, day, hour, minute),
      intensity: 5,
      trigger: UrgeTrigger.stress,
    );

class FakeScheduler implements ProtectionReminderScheduler {
  final List<DangerWindow> scheduled = [];
  int cancels = 0;

  @override
  Future<void> scheduleFor(DangerWindow window, {DateTime? now}) async => scheduled.add(window);

  @override
  Future<void> cancel() async => cancels++;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('DangerWindowAnalyzer', () {
    test('finds the busiest two-hour period', () {
      final events = [
        urgeAt(1, 22, 15),
        urgeAt(2, 23, 40),
        urgeAt(3, 22, 5),
        urgeAt(3, 9),
        urgeAt(4, 14),
      ];

      final window = DangerWindowAnalyzer.analyze(events)!;

      expect(window.startHour, 22);
      expect(window.endHour, 0);
      expect(window.label, '10 PM–12 AM');
      expect(window.count, 3);
      expect(window.total, 5);
      expect(window.share, closeTo(0.6, 1e-9));
    });

    test('needs at least three urges before reporting anything', () {
      expect(DangerWindowAnalyzer.analyze([]), isNull);
      expect(DangerWindowAnalyzer.analyze([urgeAt(1, 22), urgeAt(2, 22)]), isNull);
    });

    test('needs at least two urges in the busiest period', () {
      expect(DangerWindowAnalyzer.analyze([urgeAt(1, 1), urgeAt(1, 9), urgeAt(1, 17)]), isNull);
    });

    test('ties resolve to the earlier period, deterministically', () {
      final events = [urgeAt(1, 8), urgeAt(2, 9), urgeAt(3, 20), urgeAt(4, 21)];
      final a = DangerWindowAnalyzer.analyze(events)!;
      final b = DangerWindowAnalyzer.analyze(events.reversed.toList())!;
      expect(a.startHour, 8);
      expect(b.startHour, 8);
      expect(a.label, '8 AM–10 AM');
    });

    test('labels handle midnight and noon', () {
      expect(const DangerWindow(startHour: 0, count: 2, total: 3).label, '12 AM–2 AM');
      expect(const DangerWindow(startHour: 12, count: 2, total: 3).label, '12 PM–2 PM');
      expect(const DangerWindow(startHour: 10, count: 2, total: 3).label, '10 AM–12 PM');
    });

    test('nextStart is the next occurrence strictly after now', () {
      const window = DangerWindow(startHour: 22, count: 2, total: 3);
      expect(window.nextStart(DateTime(2026, 9, 28, 9)), DateTime(2026, 9, 28, 22));
      expect(window.nextStart(DateTime(2026, 9, 28, 22)), DateTime(2026, 9, 29, 22));
      expect(window.nextStart(DateTime(2026, 9, 28, 23, 30)), DateTime(2026, 9, 29, 22));
    });

    test('contains checks the two-hour bucket', () {
      const window = DangerWindow(startHour: 22, count: 2, total: 3);
      expect(window.contains(DateTime(2026, 9, 28, 23, 59)), isTrue);
      expect(window.contains(DateTime(2026, 9, 28, 21, 59)), isFalse);
      expect(window.contains(DateTime(2026, 9, 29, 0, 0)), isFalse);
    });
  });

  group('DangerWindowProvider', () {
    test('schedules nothing until the user opts in', () async {
      final scheduler = FakeScheduler();
      final provider = DangerWindowProvider(DangerWindowRepository(), scheduler);
      await Future<void>.delayed(Duration.zero);

      await provider.updateUrges([urgeAt(1, 22), urgeAt(2, 22), urgeAt(3, 9)]);

      expect(provider.window, isNotNull);
      expect(provider.reminderEnabled, isFalse);
      expect(scheduler.scheduled, isEmpty);
    });

    test('opting in schedules the window and persists the choice', () async {
      final scheduler = FakeScheduler();
      final provider = DangerWindowProvider(DangerWindowRepository(), scheduler);
      await Future<void>.delayed(Duration.zero);
      await provider.updateUrges([urgeAt(1, 22), urgeAt(2, 22), urgeAt(3, 9)]);

      await provider.setReminderEnabled(true);

      expect(scheduler.scheduled.map((w) => w.startHour), [22]);
      expect(await DangerWindowRepository().isReminderEnabled(), isTrue);

      await provider.setReminderEnabled(false);
      expect(scheduler.cancels, greaterThan(0));
      expect(await DangerWindowRepository().isReminderEnabled(), isFalse);
    });

    test('reschedules when the window moves and cancels when it disappears', () async {
      SharedPreferences.setMockInitialValues({DangerWindowRepository.reminderEnabledKey: true});
      final scheduler = FakeScheduler();
      final provider = DangerWindowProvider(DangerWindowRepository(), scheduler);
      await Future<void>.delayed(Duration.zero);

      await provider.updateUrges([urgeAt(1, 22), urgeAt(2, 22), urgeAt(3, 9)]);
      await provider.updateUrges([urgeAt(1, 22), urgeAt(2, 22), urgeAt(3, 9), urgeAt(4, 8), urgeAt(5, 8), urgeAt(6, 9)]);
      expect(scheduler.scheduled.map((w) => w.startHour), [22, 8]);

      final cancelsBefore = scheduler.cancels;
      await provider.updateUrges([urgeAt(1, 22)]);
      expect(provider.window, isNull);
      expect(scheduler.cancels, cancelsBefore + 1);
    });
  });
}
