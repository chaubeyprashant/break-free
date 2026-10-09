/// Paths for Urge Surfing audio assets under `assets/audio/`.
///
/// Replace [primary] with a professionally mixed track when ready; keep the
/// folder declared in `pubspec.yaml`. See `assets/audio/README.md`.
class PanicAudioPaths {
  PanicAudioPaths._();

  static const String primary = 'assets/audio/calm_breathing.wav';
  static const Duration sessionDuration = Duration(seconds: 90);
  static const int xpReward = 15;
  static const int coinReward = 3;
}
