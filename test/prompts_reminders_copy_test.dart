import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/reminders/reminder_copy.dart';
import 'package:letters_to_heaven/data/models/models.dart';
import 'package:letters_to_heaven/features/prompts/prompt_mood.dart';

void main() {
  test('reminder copy avoids pressure phrases', () {
    expect(
      ReminderCopy.notificationBody,
      'A private moment is waiting whenever you are ready.',
    );
    expect(ReminderCopy.remindMe, 'Remind Me');
    expect(ReminderCopy.returnOnMyOwn, 'I Will Return on My Own');
    expect(ReminderCopy.askMeLater, 'Ask Me Later');
    final surface = [
      ReminderCopy.optInQuestion,
      ReminderCopy.notificationBody,
      ReminderCopy.remindMe,
      ReminderCopy.returnOnMyOwn,
      ReminderCopy.askMeLater,
    ].join(' ');
    for (final banned in ReminderCopy.bannedPhrases) {
      expect(
        surface.toLowerCase().contains(banned.toLowerCase()),
        isFalse,
        reason: 'Banned reminder phrase: $banned',
      );
    }
  });

  test('prompt moods are never labeled easy', () {
    for (final mood in PromptMood.values) {
      expect(mood.label.toLowerCase().contains('easy'), isFalse);
    }
  });

  test('difficult prompts require consent tags', () {
    final hard = const Prompt(
      id: 'x',
      category: 'letters',
      text: 'Share an apology you are still carrying',
      intensity: 'reflective',
      sensitivityTags: ['guilt'],
    );
    expect(promptNeedsDifficultConsent(hard), isTrue);
    final soft = const Prompt(
      id: 'y',
      category: 'memories',
      text: 'What did they always order?',
      intensity: 'gentle',
      sensitivityTags: ['food'],
    );
    expect(promptNeedsDifficultConsent(soft), isFalse);
  });
}
