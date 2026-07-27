/// Reminder opt-in and notification copy — treat reminders as potentially painful.
enum ReminderOptInChoice { remindMe, returnOnMyOwn, askMeLater, unset }

abstract final class ReminderCopy {
  static const optInQuestion =
      'Would a quiet reminder help, or would you rather return on your own?';

  static const remindMe = 'Remind Me';
  static const returnOnMyOwn = 'I Will Return on My Own';
  static const askMeLater = 'Ask Me Later';

  /// Lock-screen / notification body — never names or pressure language.
  static const notificationBody =
      'A private moment is waiting whenever you are ready.';

  static const bannedPhrases = <String>[
    'It is time to journal',
    'Do not forget today’s reflection',
    'Continue your healing',
    'You have missed three days',
    'Remember [Name] today',
    'You are falling behind',
    'day streak',
    'missed days',
    'grief score',
    'healing score',
    'keep your streak',
  ];
}
