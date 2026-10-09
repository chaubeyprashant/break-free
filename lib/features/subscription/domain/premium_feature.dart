/// Features that exist today and may require Premium.
/// Do not add values for features that are not implemented.
enum PremiumFeature {
  multipleHabits(
    title: 'Multiple habits',
    benefit: 'Track more than one habit at once and grow several streaks together.',
  ),
  journalInsights(
    title: 'Journal insights',
    benefit: 'See triggers, hard times of day, and week-over-week progress from your activity.',
  ),
  extraProtection(
    title: 'Extra streak protection',
    benefit: 'Get an additional Freeze and Shield each week when urges hit.',
  ),
  companionSync(
    title: 'Accountability Companion',
    benefit: 'Link a trusted companion who can be notified when you slip.',
  ),
  transactionScanner(
    title: 'Transaction Scanner',
    benefit: 'Get a heads-up when purchase notifications match risky keywords.',
  ),
  mindCityPremium(
    title: 'Mind City landmark',
    benefit: 'Unlock the premium landmark that grows with your recovery city.',
  ),
  advancedSchedules(
    title: 'Advanced protection schedules',
    benefit: 'Create more than one Night/Work protection window.',
  ),
  expandedCustomBlocklist(
    title: 'Expanded custom domains',
    benefit: 'Block more websites you choose beyond the free limit.',
  ),
  advancedCompanionAlerts(
    title: 'Advanced companion alerts',
    benefit: 'Choose which protection accountability events your companion can receive.',
  ),
  advancedProtectionHistory(
    title: 'Advanced protection history',
    benefit: 'See the full local history of blocked attempts and protection events.',
  );

  const PremiumFeature({required this.title, required this.benefit});

  final String title;
  final String benefit;
}

/// Free-tier limits for features that scale with Premium.
class FreeTier {
  FreeTier._();

  static const int maxHabits = 1;
  static const int freezesPerWeek = 1;
  static const int shieldsPerWeek = 1;

  /// Basic protection (apps + adult category + setup) stays free.
  static const int maxSchedules = 1;
  static const int maxCustomDomains = 5;
  static const int freeProtectionHistory = 10;
}

class PremiumTiers {
  PremiumTiers._();

  static const int freezesPerWeek = 2;
  static const int shieldsPerWeek = 2;
}
