import 'package:break_free/core/data/habit_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('titles are unique across categories', () {
    final titles = HabitCatalog.all.map((option) => option.title).toList();

    // HabitProvider de-duplicates by title, so a repeat would make one of the
    // two tiles silently do nothing.
    expect(titles.toSet().length, titles.length);
  });

  test('every option has a title and an emoji', () {
    for (final option in HabitCatalog.all) {
      expect(option.title, isNotEmpty);
      expect(option.emoji, isNotEmpty);
    }
  });

  test('keeps the titles earlier versions already saved', () {
    // Renaming any of these would orphan the habit an existing user tracks.
    const shipped = [
      'Porn/Masturbation',
      'Smoking',
      'Alcohol',
      'Junk Food',
      'Social Media',
      'Gaming',
    ];

    for (final title in shipped) {
      expect(
        HabitCatalog.byTitle(title),
        isNotNull,
        reason: '$title was previously selectable and must remain so',
      );
    }
  });

  test('emojiFor falls back for a habit outside the catalog', () {
    expect(HabitCatalog.emojiFor('Smoking'), '🚬');
    expect(HabitCatalog.emojiFor('Something we never shipped'),
        HabitCatalog.defaultEmoji);
  });
}
