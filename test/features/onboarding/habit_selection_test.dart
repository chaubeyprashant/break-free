import 'package:break_free/core/data/habit_catalog.dart';
import 'package:break_free/core/data/habit_repository.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/features/onboarding/presentation/habit_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _screenUnderTest() {
  return ProviderScope(
    child: ChangeNotifierProvider(
      create: (_) => HabitProvider(HabitRepository()),
      child: const MaterialApp(home: HabitSelectionScreen()),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders every catalog habit under its category', (tester) async {
    // Tall surface so the whole list lays out without scrolling.
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_screenUnderTest());
    await tester.pumpAndSettle();

    for (final category in HabitCatalog.categories) {
      expect(
        find.text(category.name),
        findsOneWidget,
        reason: 'category ${category.name} should have a heading',
      );
    }
    for (final option in HabitCatalog.all) {
      expect(
        find.text(option.title),
        findsOneWidget,
        reason: '${option.title} should be selectable',
      );
    }
  });

  testWidgets('selecting habits enables continue and counts them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_screenUnderTest());
    await tester.pumpAndSettle();

    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
    expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);

    await tester.tap(find.text('Vaping'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with 1 habit'), findsOneWidget);

    await tester.tap(find.text('Gambling'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with 2 habits'), findsOneWidget);

    // Tapping again de-selects.
    await tester.tap(find.text('Gambling'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with 1 habit'), findsOneWidget);
  });
}
