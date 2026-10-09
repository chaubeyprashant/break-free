/// Duration tiers offered by "Replace the Habit".
enum ActivityTier {
  two(2, 'Quick'),
  five(5, 'Short'),
  ten(10, 'Medium'),
  thirty(30, 'Deep');

  const ActivityTier(this.minutes, this.tagline);

  final int minutes;
  final String tagline;

  Duration get duration => Duration(minutes: minutes);

  String get label => '$minutes min';

  /// XP for a completed activity in this tier. Goes through the same
  /// GameProvider.addXp path as check-ins (25 XP) and urge interventions (15).
  int get xpReward => switch (this) {
        ActivityTier.two => 5,
        ActivityTier.five => 10,
        ActivityTier.ten => 15,
        ActivityTier.thirty => 30,
      };

  int get coinReward => switch (this) {
        ActivityTier.two => 1,
        ActivityTier.five => 2,
        ActivityTier.ten => 3,
        ActivityTier.thirty => 6,
      };

  static ActivityTier? fromMinutes(int? minutes) {
    for (final t in ActivityTier.values) {
      if (t.minutes == minutes) return t;
    }
    return null;
  }
}

/// How an activity is run.
enum ActivityKind {
  /// Countdown with rotating prompts.
  timed,

  /// Countdown with the breathing pacer.
  breathing,

  /// The Bubble Popper mini-game; completes when every bubble is popped.
  miniGame,
}

class ReplacementActivity {
  const ReplacementActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.icon,
    this.kind = ActivityKind.timed,
    this.prompts = const [],
  });

  final String id;
  final String title;
  final String description;
  final ActivityTier tier;

  /// Emoji shown in the list; keeps the catalog free of asset dependencies.
  final String icon;
  final ActivityKind kind;

  /// Shown one at a time, spread evenly across the activity's duration.
  final List<String> prompts;

  /// Prompt to show [elapsed] into the activity.
  String? promptAt(Duration elapsed) {
    if (prompts.isEmpty) return null;
    final slot = tier.duration.inSeconds / prompts.length;
    final index = (elapsed.inSeconds / slot).floor().clamp(0, prompts.length - 1);
    return prompts[index];
  }
}

/// The built-in catalog. Static data, no network, no assets.
class ActivityCatalog {
  static const List<ReplacementActivity> all = [
    // 2 minutes
    ReplacementActivity(
      id: 'breathe_2',
      title: 'Box breathing',
      description: 'Four counts in, hold, out, hold.',
      tier: ActivityTier.two,
      icon: '🌬️',
      kind: ActivityKind.breathing,
      prompts: ['Breathe in', 'Hold', 'Breathe out', 'Hold'],
    ),
    ReplacementActivity(
      id: 'stretch_2',
      title: 'Desk stretch',
      description: 'Neck, shoulders, wrists.',
      tier: ActivityTier.two,
      icon: '🙆',
      prompts: ['Roll your shoulders back, slowly', 'Tilt your head side to side', 'Stretch your arms overhead', 'Shake out your hands'],
    ),
    ReplacementActivity(
      id: 'bubbles_2',
      title: 'Pop the Urge',
      description: 'Tap every angry bubble until the screen is clear.',
      tier: ActivityTier.two,
      icon: '🫧',
      kind: ActivityKind.miniGame,
    ),
    ReplacementActivity(
      id: 'water_2',
      title: 'Water break',
      description: 'Get up, fill a glass, drink it slowly.',
      tier: ActivityTier.two,
      icon: '💧',
      prompts: ['Stand up and go get a glass of water', 'Drink it slowly, notice the temperature', 'Rinse the glass and put it away'],
    ),
    // 5 minutes
    ReplacementActivity(
      id: 'walk_5',
      title: 'Walk around the block',
      description: 'Leave the phone in your pocket.',
      tier: ActivityTier.five,
      icon: '🚶',
      prompts: ['Head out the door', 'Notice three things you can hear', 'Pick up the pace a little', 'Slow down and head back', 'Take a full breath before going in'],
    ),
    ReplacementActivity(
      id: 'music_5',
      title: 'One song, eyes closed',
      description: 'Play a track you love and only listen.',
      tier: ActivityTier.five,
      icon: '🎧',
      prompts: ['Press play and close your eyes', 'Follow one instrument all the way through', 'Notice where you feel the beat', 'Let the last note fade before opening your eyes'],
    ),
    ReplacementActivity(
      id: 'journal_5',
      title: 'Brain dump',
      description: 'Write whatever is in your head, no editing.',
      tier: ActivityTier.five,
      icon: '📝',
      prompts: ['What is the urge asking for, really?', 'What would you tell a friend feeling this?', 'What is one thing you are looking forward to?', 'Finish the sentence: right now I need...'],
    ),
    ReplacementActivity(
      id: 'stretch_5',
      title: 'Full-body stretch',
      description: 'Slow, gentle, floor to ceiling.',
      tier: ActivityTier.five,
      icon: '🧘',
      prompts: ['Forward fold, let your head hang', 'Lunge, each side', 'Cat and cow on all fours', 'Child\'s pose, breathe into your back', 'Reach up tall and stand still'],
    ),
    // 10 minutes
    ReplacementActivity(
      id: 'read_10',
      title: 'Read ten pages',
      description: 'A real book or a long article. No feeds.',
      tier: ActivityTier.ten,
      icon: '📖',
      prompts: ['Find your book and a comfortable spot', 'Read without checking anything else', 'Halfway. Keep going', 'Finish the page you are on'],
    ),
    ReplacementActivity(
      id: 'walk_10',
      title: 'Brisk walk',
      description: 'Enough to raise your heart rate.',
      tier: ActivityTier.ten,
      icon: '🏃',
      prompts: ['Start easy for a minute', 'Speed up until you are breathing harder', 'Hold that pace', 'Ease off for the last stretch'],
    ),
    ReplacementActivity(
      id: 'music_10',
      title: 'Album side',
      description: 'Three songs back to back, nothing else open.',
      tier: ActivityTier.ten,
      icon: '🎶',
      prompts: ['Queue three tracks and put the phone down', 'Just listen', 'Notice how your mood has shifted', 'Last track'],
    ),
    ReplacementActivity(
      id: 'journal_10',
      title: 'Guided reflection',
      description: 'Five prompts, two minutes each.',
      tier: ActivityTier.ten,
      icon: '🖊️',
      prompts: ['When did the urge start today, and what was happening?', 'What does giving in usually cost you afterwards?', 'What has worked before when you rode one out?', 'Who or what are you doing this for?', 'One small thing you will do next'],
    ),
    // 30 minutes
    ReplacementActivity(
      id: 'walk_30',
      title: 'Long walk',
      description: 'Somewhere green if you can.',
      tier: ActivityTier.thirty,
      icon: '🌳',
      prompts: ['Pick a route and go', 'Look far ahead, not at your feet', 'Halfway. Turn around or loop back', 'Slow down for the last few minutes'],
    ),
    ReplacementActivity(
      id: 'read_30',
      title: 'Read a chapter',
      description: 'Phone face down in another room.',
      tier: ActivityTier.thirty,
      icon: '📚',
      prompts: ['Settle in', 'Keep reading', 'Halfway there', 'Finish the chapter'],
    ),
    ReplacementActivity(
      id: 'workout_30',
      title: 'Workout',
      description: 'Your routine, or bodyweight basics.',
      tier: ActivityTier.thirty,
      icon: '💪',
      prompts: ['Warm up: march, arm circles, easy squats', 'Main set: push, pull, squat, repeat', 'Keep the form clean, rest when needed', 'Cool down and stretch'],
    ),
    ReplacementActivity(
      id: 'journal_30',
      title: 'Long-form journaling',
      description: 'Write about the week, not just today.',
      tier: ActivityTier.thirty,
      icon: '📓',
      prompts: ['What went well this week?', 'Where did urges show up and what triggered them?', 'What would next week look like if it went well?', 'Write a note to yourself for the next hard moment'],
    ),
  ];

  static List<ReplacementActivity> forTier(ActivityTier tier) => all.where((a) => a.tier == tier).toList();

  static ReplacementActivity? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
