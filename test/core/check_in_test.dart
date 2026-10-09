import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:break_free/core/data/check_in_repository.dart';
import 'package:break_free/core/providers/check_in_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('check-in is once per local calendar day and survives reload', () async {
    final now = DateTime(2026, 10, 7, 9, 30);
    final repo = CheckInRepository();
    expect(await repo.recordCheckIn('habit-a', now: now), isTrue);
    expect(await repo.recordCheckIn('habit-a', now: now), isFalse);
    expect(await repo.hasCheckedInToday('habit-a', now: now), isTrue);
    expect(await repo.hasCheckedInToday('habit-b', now: now), isFalse);

    // Same calendar day later still blocked.
    expect(await repo.recordCheckIn('habit-a', now: DateTime(2026, 10, 7, 23, 50)), isFalse);

    // Next local day allowed.
    expect(await repo.recordCheckIn('habit-a', now: DateTime(2026, 10, 8, 0, 5)), isTrue);
  });

  test('provider reflects repository after record', () async {
    var clock = DateTime(2026, 10, 7, 12);
    final provider = CheckInProvider(CheckInRepository(), now: () => clock);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(await provider.recordCheckIn('h1'), isTrue);
    expect(provider.hasCheckedInToday('h1'), isTrue);
    expect(await provider.recordCheckIn('h1'), isFalse);
  });
}
