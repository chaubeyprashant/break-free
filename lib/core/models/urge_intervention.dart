/// The three ways to ride out an urge, with the timed plan for each.
/// Pure Dart so durations and prompts are unit-testable.
enum UrgeIntervention {
  breathe(
    label: 'Breathe',
    tagline: 'Box breathing, 90 seconds',
    duration: Duration(seconds: 90),
    prompts: ['Breathe in', 'Hold', 'Breathe out', 'Hold'],
    promptInterval: Duration(seconds: 4),
  ),
  move(
    label: 'Move',
    tagline: 'Get the body going, 60 seconds',
    duration: Duration(seconds: 60),
    prompts: ['Stand up and shake out your arms', '10 squats, slow and steady', 'Reach for the ceiling, then your toes', 'March in place, knees high'],
    promptInterval: Duration(seconds: 15),
  ),
  distract(
    label: 'Distract',
    tagline: 'Give your mind a job, 2 minutes',
    duration: Duration(seconds: 120),
    prompts: [
      'Count backwards from 100 in sevens',
      'Name five things you can see that are blue',
      'List every country you can think of starting with S',
      'Spell your full name backwards',
      'Name four things you can hear right now',
      'Think of a song and hum the whole chorus',
    ],
    promptInterval: Duration(seconds: 20),
  );

  const UrgeIntervention({
    required this.label,
    required this.tagline,
    required this.duration,
    required this.prompts,
    required this.promptInterval,
  });

  final String label;
  final String tagline;
  final Duration duration;
  final List<String> prompts;
  final Duration promptInterval;

  /// Rewards go through GameProvider.addXp, the same path as habit check-ins
  /// (25 XP / 5 coins). Riding out an urge is worth a little less than a clean day.
  static const int xpReward = 15;
  static const int coinReward = 3;

  String get storageKey => name;

  static UrgeIntervention? fromStorageKey(String? key) {
    for (final i in UrgeIntervention.values) {
      if (i.name == key) return i;
    }
    return null;
  }

  /// Prompt to show [elapsed] into the session; cycles through [prompts].
  String promptAt(Duration elapsed) {
    final index = elapsed.inSeconds ~/ promptInterval.inSeconds;
    return prompts[index % prompts.length];
  }
}
