import 'package:break_free/core/data/check_in_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('records a check-in and counts it once', () async {
    final repository = CheckInRepository();
    final today = DateTime(2026, 8, 28, 9);

    final first = await repository.recordCheckIn(when: today, xp: 20);

    expect(first, isTrue);
    expect(await repository.getTotalCheckIns(), 1);
    expect(await repository.hasCheckedInOn(today), isTrue);
  });

  test('refuses a second check-in on the same calendar day', () async {
    final repository = CheckInRepository();
    await repository.recordCheckIn(when: DateTime(2026, 8, 28, 9), xp: 20);

    // Later the same day.
    final second = await repository.recordCheckIn(
      when: DateTime(2026, 8, 28, 23),
      xp: 20,
    );

    expect(second, isFalse);
    expect(await repository.getTotalCheckIns(), 1);
  });

  test('allows a check-in again the next day', () async {
    final repository = CheckInRepository();
    await repository.recordCheckIn(when: DateTime(2026, 8, 28), xp: 20);

    final next = await repository.recordCheckIn(
      when: DateTime(2026, 8, 29),
      xp: 20,
    );

    expect(next, isTrue);
    expect(await repository.getTotalCheckIns(), 2);
  });

  test('maps the week Monday to Sunday for the chart', () async {
    final repository = CheckInRepository();
    // 2026-08-24 is a Monday; 2026-08-28 is that week's Friday.
    await repository.recordCheckIn(when: DateTime(2026, 8, 24), xp: 20);
    await repository.recordCheckIn(when: DateTime(2026, 8, 28), xp: 30);

    final week = await repository.xpForWeekOf(DateTime(2026, 8, 28));

    expect(week, [20.0, 0.0, 0.0, 0.0, 30.0, 0.0, 0.0]);
  });

  test('drops history older than the retention window', () async {
    final repository = CheckInRepository();
    await repository.recordCheckIn(when: DateTime(2026, 6, 1), xp: 20);

    await repository.recordCheckIn(when: DateTime(2026, 8, 28), xp: 20);

    expect(await repository.hasCheckedInOn(DateTime(2026, 6, 1)), isFalse);
    // The lifetime total survives the pruning of per-day history.
    expect(await repository.getTotalCheckIns(), 2);
  });
}
