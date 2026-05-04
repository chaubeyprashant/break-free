// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your app, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can use WidgetTester to find child widgets in the widget
// tree, read the widget properties, and verify the values of widget properties.

import 'package:flutter_test/flutter_test.dart';
import 'package:break_free/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BreakFreeApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Break Free'), findsWidgets);
    expect(find.textContaining('Identify your triggers'), findsOneWidget);
  });
}
