import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:break_free/core/data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository();
});

/// Whether onboarding is done. The router watches this to decide if a new user
/// should be sent to pick their habits before seeing the dashboard.
final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(() {
  return OnboardingNotifier();
});

class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(onboardingRepositoryProvider).hasCompleted();
  }

  Future<void> complete() async {
    await ref.read(onboardingRepositoryProvider).markCompleted();
    state = const AsyncValue.data(true);
  }

  /// After a progress reset the flag is gone with the rest of the data, so the
  /// user starts from onboarding again.
  void reset() {
    state = const AsyncValue.data(false);
  }
}
