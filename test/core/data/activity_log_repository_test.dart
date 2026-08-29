import 'package:break_free/core/data/activity_log_repository.dart';
import 'package:break_free/core/models/activity_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ActivityEvent _event(String title, DateTime at) => ActivityEvent(
  id: '${at.microsecondsSinceEpoch}',
  type: ActivityEvent.checkIn,
  title: title,
  description: 'test',
  timestamp: at,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns events newest first and survives a round trip', () async {
    final repository = ActivityLogRepository();

    await repository.record(_event('older', DateTime(2026, 8, 27)));
    await repository.record(_event('newer', DateTime(2026, 8, 28)));

    final events = await repository.getEvents();
    expect(events.map((e) => e.title), ['newer', 'older']);
    expect(events.first.type, ActivityEvent.checkIn);
    expect(events.first.timestamp, DateTime(2026, 8, 28));
  });

  test('keeps only the most recent entries', () async {
    final repository = ActivityLogRepository();

    for (var i = 0; i < ActivityLogRepository.maxEntries + 5; i++) {
      await repository.record(_event('event $i', DateTime(2026, 8, 1).add(Duration(days: i))));
    }

    final events = await repository.getEvents();
    expect(events.length, ActivityLogRepository.maxEntries);
    expect(events.first.title, 'event 24');
    expect(events.last.title, 'event 5');
  });
}
