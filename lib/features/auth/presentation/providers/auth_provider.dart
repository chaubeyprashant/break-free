import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, UserEntity?>(() {
  return AuthNotifier();
});

/// Signs the user in anonymously on first launch and keeps that identity.
///
/// Nothing in the app is gated on this: sign-in needs the network, and the app
/// works entirely offline. A failure here leaves the user without a Firebase
/// identity for the session, not without an app.
class AuthNotifier extends AsyncNotifier<UserEntity?> {
  /// Sign-in commonly fails on a weak connection, so one attempt isn't enough
  /// — a single bad moment at launch would cost the whole session.
  static const int signInAttempts = 3;

  @visibleForTesting
  static Duration initialRetryDelay = const Duration(seconds: 2);

  @override
  Future<UserEntity?> build() async {
    final repository = ref.watch(authRepositoryProvider);

    final subscription = repository.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
    ref.onDispose(subscription.cancel);

    final existing = repository.currentUser;
    if (existing != null) return existing;

    return _signInWithRetry(repository);
  }

  Future<UserEntity?> _signInWithRetry(AuthRepository repository) async {
    var delay = initialRetryDelay;

    for (var attempt = 1; attempt <= signInAttempts; attempt++) {
      try {
        return await repository.signInAnonymously();
      } catch (error) {
        debugPrint(
          'Anonymous sign-in attempt $attempt/$signInAttempts failed: $error',
        );
        if (attempt == signInAttempts) {
          // Out of attempts. The app carries on without a Firebase identity
          // and tries again on the next launch.
          return null;
        }
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }
    return null;
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      return null;
    });
  }
}
