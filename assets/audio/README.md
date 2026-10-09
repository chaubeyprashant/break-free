# Panic / Urge Surfing audio

Production calming audio for the 90-second Urge Surfing exercise lives here.

| Asset | Purpose |
|-------|---------|
| `calm_breathing.wav` | Default guided pad used by Panic Mode (loops or plays for the 90s session). |

To replace with a professionally mixed track:

1. Add `calm_breathing.mp3` (or keep `.wav`) under this folder.
2. Update `PanicAudioPaths.primary` in `lib/features/panic_mode/panic_audio.dart` if the filename changes.
3. Keep `pubspec.yaml` declaring `assets/audio/`.

The app loads the asset offline via `just_audio`. If the asset fails to load, Urge Surfing still runs with breathing animation, haptics, and a muted audio state — never blocks the crisis flow.
