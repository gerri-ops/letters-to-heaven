/// Retention without streaks — grief journaling is episodic.
///
/// Writing several times in one week and then disappearing for two months
/// does not mean the app failed.
abstract final class RetentionCopy {
  static const principle =
      'Grief journaling is episodic. Return when you are ready—there is '
      'nothing to keep up with.';

  static const homeSectionTitle = 'Whenever you are ready';

  static const homeSectionSupporting =
      'Optional ways back in. Silence any of them anytime.';

  static const continueDraft = 'Continue an unfinished draft';
  static const memoryQuestionWeekly = 'This week’s memory question';
  static const memoryQuestionMonthly = 'This month’s memory question';
  static const saveBeforeForget = 'Save this before I forget';
  static const importPhoto = 'Add a photo from your device';
  static const monthlyKeepsake = 'Peek at a keepsake preview';
  static const resurfaceMemory = 'A quieter memory (only if you ask)';
  static const remembranceDates = 'Birthday or anniversary reminders';
  static const familyContribution = 'A family contribution is waiting';

  static const widgetLabel = 'Save this before I forget';
  static const widgetDescription =
      'Opens a private quick capture—one sentence, photo, or voice note. '
      'No streaks. No homework.';

  static const settingsTitle = 'Returning at your pace';
  static const settingsIntro =
      'Choose gentle return options. Turning everything off is always fine.';

  static const cadenceOff = 'Off';
  static const cadenceWeekly = 'Weekly';
  static const cadenceMonthly = 'Monthly';

  static const resurfacingOff = 'Off';
  static const resurfacingFavorites = 'Favorites only, when I ask';
  static const resurfacingGentle = 'A gentle saved memory, when I ask';

  /// Healthy return triggers (product list).
  static const healthyTriggers = <String>[
    'Optional birthday and anniversary reminders',
    'An unfinished draft',
    'A user-selected weekly or monthly memory question',
    'A “save this before I forget” home-screen widget',
    'A private photo import suggestion initiated by the user',
    'Monthly keepsake preview',
    'Family contribution notification',
    'User-controlled memory resurfacing',
  ];

  /// Patterns we never use for retention.
  static const avoidPatterns = <String>[
    'Daily streaks',
    'Missed-day counts',
    'Progress percentages',
    'You are falling behind',
    'Empty monthly calendars',
    'Red warning badges',
    'Grief scores',
    'Healing scores',
    'Pressure to reread painful entries',
  ];

  static const bannedPhrases = <String>[
    'You are falling behind',
    'day streak',
    'missed days',
    'complete your progress',
    'grief score',
    'healing score',
    'keep your streak',
    'you skipped yesterday',
    'catch up on journaling',
  ];
}

/// How often an optional memory question may appear on Home.
enum MemoryQuestionCadence {
  off,
  weekly,
  monthly,
}

/// User-controlled resurfacing — never forced rereading.
enum MemoryResurfacingMode {
  off,
  favoritesWhenAsked,
  gentleWhenAsked,
}
