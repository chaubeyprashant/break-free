import 'package:break_free/core/data/activity_log_repository.dart';
import 'package:break_free/core/data/check_in_repository.dart';
import 'package:break_free/core/data/game_repository.dart';
import 'package:break_free/core/providers/game_provider.dart';
import 'package:break_free/features/dashboard/presentation/dashboard_screen.dart';
import 'package:break_free/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:shared_preferences/shared_preferences.dart';

Widget _dashboardUnderTest() {
  return ProviderScope(
    child: legacy_provider.MultiProvider(
      providers: [
        legacy_provider.Provider(create: (_) => CheckInRepository()),
        legacy_provider.Provider(create: (_) => ActivityLogRepository()),
        legacy_provider.ChangeNotifierProvider(
          create: (_) => GameProvider(GameRepository()),
        ),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
}

/// The value shown on the stat tile with the given title.
Finder _statValue(String title, String value) => find.descendant(
  of: find.widgetWithText(StatCard, title),
  matching: find.text(value),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('checking in awards XP and flips the card to the done state', (
    tester,
  ) async {
    await tester.pumpWidget(_dashboardUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('How did today go?'), findsOneWidget);
    expect(find.text('Checked in today'), findsNothing);

    await tester.tap(find.text('I stayed on track today'));
    await tester.pumpAndSettle();

    expect(find.text('Checked in today'), findsOneWidget);
    expect(find.text('How did today go?'), findsNothing);

    // The stat tiles now reflect the check-in that just happened.
    expect(_statValue('Total Check-ins', '1'), findsOneWidget);
    expect(_statValue('Coins', '5'), findsOneWidget);

    final progress = await GameRepository().getProgress();
    expect(progress.xp, 20);
    expect(progress.coins, 5);

    final events = await ActivityLogRepository().getEvents();
    expect(events.single.title, 'Checked in');
  });

  testWidgets('a day already checked in cannot be checked in again', (
    tester,
  ) async {
    await CheckInRepository().recordCheckIn(when: DateTime.now(), xp: 20);

    await tester.pumpWidget(_dashboardUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Checked in today'), findsOneWidget);
    expect(find.text('I stayed on track today'), findsNothing);
  });

  testWidgets('day one shows hours rather than a zero-day streak', (
    tester,
  ) async {
    final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
    SharedPreferences.setMockInitialValues({
      'streak_start_date': threeHoursAgo.toIso8601String(),
    });

    await tester.pumpWidget(_dashboardUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('3 Hours'), findsOneWidget);
  });
}
