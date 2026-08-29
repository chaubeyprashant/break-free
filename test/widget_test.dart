import 'package:break_free/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:break_free/features/auth/domain/entities/user_entity.dart';
import 'package:break_free/features/auth/domain/repositories/auth_repository.dart';
import 'package:break_free/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for Firebase, which needs platform channels a widget test has no
/// way to provide.
class _FakeAuthRepository implements AuthRepository {
  static const _anonymous = UserEntity(id: 'test-uid');

  @override
  UserEntity? get currentUser => _anonymous;

  @override
  Stream<UserEntity?> authStateChanges() => const Stream.empty();

  @override
  Future<UserEntity> signInAnonymously() async => _anonymous;

  @override
  Future<void> signOut() async {}
}

Widget _app() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ],
    child: const BreakFreeApp(),
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('a new user lands on onboarding, not the dashboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Break Free'), findsWidgets);
    expect(find.textContaining('Identify your triggers'), findsOneWidget);
  });

  testWidgets('a returning user goes straight to the dashboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'flutter.onboarding_completed': true,
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('How did today go?'), findsOneWidget);
    expect(find.textContaining('Identify your triggers'), findsNothing);
  });

  testWidgets('no login screen stands between the user and the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Anonymous sign-in means there is nothing to log into.
    expect(find.text('Welcome Back'), findsNothing);
    expect(find.widgetWithText(TextField, 'Email'), findsNothing);
    expect(find.widgetWithText(TextField, 'Password'), findsNothing);
  });
}
