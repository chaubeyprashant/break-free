import 'package:break_free/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:break_free/features/auth/domain/entities/user_entity.dart';
import 'package:break_free/features/auth/domain/repositories/auth_repository.dart';
import 'package:break_free/features/auth/presentation/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails [failures] times before returning a user, mimicking a flaky link.
class _FlakyAuthRepository implements AuthRepository {
  _FlakyAuthRepository({required this.failures});

  final int failures;
  int attempts = 0;

  @override
  UserEntity? get currentUser => null;

  @override
  Stream<UserEntity?> authStateChanges() => const Stream.empty();

  @override
  Future<UserEntity> signInAnonymously() async {
    attempts++;
    if (attempts <= failures) {
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'A network error has occurred.',
      );
    }
    return const UserEntity(id: 'anon-uid');
  }

  @override
  Future<void> signOut() async {}
}

ProviderContainer _containerWith(AuthRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() {
    // Keep the backoff out of the test's wall clock.
    AuthNotifier.initialRetryDelay = Duration.zero;
  });

  test('signs in anonymously on first launch', () async {
    final repository = _FlakyAuthRepository(failures: 0);
    final container = _containerWith(repository);

    final user = await container.read(authProvider.future);

    expect(user?.id, 'anon-uid');
    expect(user?.isAnonymous, isTrue);
    expect(repository.attempts, 1);
  });

  test('retries a transient network failure instead of giving up', () async {
    // This is what actually happened on device: one failure on a weak link
    // used to cost the whole session.
    final repository = _FlakyAuthRepository(failures: 2);
    final container = _containerWith(repository);

    final user = await container.read(authProvider.future);

    expect(user?.id, 'anon-uid');
    expect(repository.attempts, 3);
  });

  test('gives up quietly after exhausting attempts, leaving the app usable', () async {
    final repository = _FlakyAuthRepository(failures: 99);
    final container = _containerWith(repository);

    final user = await container.read(authProvider.future);

    // Null, not a thrown error: the app is offline-first and must keep working.
    expect(user, isNull);
    expect(repository.attempts, AuthNotifier.signInAttempts);
  });
}
