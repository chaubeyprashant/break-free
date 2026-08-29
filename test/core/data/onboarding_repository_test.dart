import 'package:break_free/core/data/habit_repository.dart';
import 'package:break_free/core/data/onboarding_repository.dart';
import 'package:break_free/core/models/habit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a brand new user has not completed onboarding', () async {
    expect(await OnboardingRepository().hasCompleted(), isFalse);
  });

  test('completing onboarding sticks', () async {
    final repository = OnboardingRepository();

    await repository.markCompleted();

    expect(await repository.hasCompleted(), isTrue);
    // A fresh instance reads the same persisted flag.
    expect(await OnboardingRepository().hasCompleted(), isTrue);
  });

  test('a user who already has habits is treated as onboarded', () async {
    // Upgrading from a build that predates the flag must not send an existing
    // user back through habit selection.
    final habits = HabitRepository();
    await habits.addHabit(
      Habit(
        id: '1',
        title: 'Smoking',
        iconPath: '🚬',
        startDate: DateTime(2026, 8, 1),
      ),
    );

    expect(await OnboardingRepository(habits: habits).hasCompleted(), isTrue);
  });
}
