/// A habit the user can choose to break, and the grouping it appears under.
///
/// Titles are the stable identity of a habit: [HabitProvider] de-duplicates by
/// title and saved habits store it verbatim, so renaming an entry here would
/// orphan the habit an existing user is already tracking. Add freely, rename
/// with care.
class HabitOption {
  final String title;
  final String emoji;

  const HabitOption(this.title, this.emoji);
}

class HabitCategory {
  final String name;
  final List<HabitOption> options;

  const HabitCategory(this.name, this.options);
}

class HabitCatalog {
  const HabitCatalog._();

  static const List<HabitCategory> categories = [
    HabitCategory('Substances', [
      HabitOption('Smoking', '🚬'),
      HabitOption('Vaping', '💨'),
      HabitOption('Alcohol', '🍺'),
      HabitOption('Cannabis', '🌿'),
      HabitOption('Chewing Tobacco', '🍂'),
    ]),
    HabitCategory('Screens', [
      HabitOption('Porn/Masturbation', '🚫'),
      HabitOption('Social Media', '📱'),
      HabitOption('Short Videos', '📹'),
      HabitOption('Gaming', '🎮'),
      HabitOption('Late-Night Scrolling', '🌙'),
    ]),
    HabitCategory('Food & drink', [
      HabitOption('Junk Food', '🍔'),
      HabitOption('Sugar', '🍬'),
      HabitOption('Caffeine', '☕'),
      HabitOption('Energy Drinks', '⚡'),
    ]),
    HabitCategory('Other', [
      HabitOption('Gambling', '🎰'),
      HabitOption('Online Shopping', '🛍️'),
      HabitOption('Nail Biting', '💅'),
    ]),
  ];

  static List<HabitOption> get all =>
      categories.expand((category) => category.options).toList();

  /// The catalog entry for a saved habit, or null if it came from an older
  /// version of the app or a category that has since been removed.
  static HabitOption? byTitle(String title) {
    for (final option in all) {
      if (option.title == title) return option;
    }
    return null;
  }

  /// Fallback icon for a habit with no catalog entry.
  static const String defaultEmoji = '🚫';

  static String emojiFor(String title) =>
      byTitle(title)?.emoji ?? defaultEmoji;
}
