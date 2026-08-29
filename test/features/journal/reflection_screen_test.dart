import 'package:break_free/core/data/relapse_log_repository.dart';
import 'package:break_free/core/models/relapse_record.dart';
import 'package:break_free/features/journal/presentation/reflection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _screen() => Provider(
  create: (_) => RelapseLogRepository(),
  child: const MaterialApp(home: ReflectionScreen()),
);

Future<void> _seed(List<RelapseRecord> records) async {
  final repository = RelapseLogRepository();
  // Stored newest-first, so insert oldest first.
  for (final record in records.reversed) {
    await repository.record(record);
  }
}

RelapseRecord _slip(String trigger, DateTime at, {String? habit}) =>
    RelapseRecord(
      id: at.microsecondsSinceEpoch.toString(),
      trigger: trigger,
      timestamp: at,
      habitTitle: habit,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('invites the user to log rather than showing an empty chart', (
    tester,
  ) async {
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    expect(find.text('Nothing to reflect on yet'), findsOneWidget);
    expect(find.text('Your patterns'), findsNothing);
  });

  testWidgets('withholds patterns until there are enough slips', (
    tester,
  ) async {
    await _seed([_slip('Stress', DateTime(2026, 8, 28, 21))]);

    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    expect(find.text('Still learning'), findsOneWidget);
    expect(find.text('Most common trigger'), findsNothing);
  });

  testWidgets('surfaces trigger, time and day once a pattern exists', (
    tester,
  ) async {
    await _seed([
      _slip('Stress', DateTime(2026, 8, 28, 21), habit: 'Smoking'),
      _slip('Stress', DateTime(2026, 8, 21, 20)),
      _slip('Boredom', DateTime(2026, 8, 25, 14)),
      _slip('Stress', DateTime(2026, 8, 14, 19)),
    ]);

    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    expect(find.text('Most common trigger'), findsOneWidget);
    expect(
      find.textContaining('Stress is behind 3 of your 4 slips'),
      findsOneWidget,
    );
    expect(find.text('Riskiest time of day'), findsOneWidget);
    expect(find.textContaining('Evenings'), findsOneWidget);
    expect(find.text('Riskiest day'), findsOneWidget);
    expect(find.textContaining('Fridays'), findsOneWidget);

    // History shows the habit alongside the trigger.
    expect(find.text('Smoking — Stress'), findsOneWidget);
  });
}
