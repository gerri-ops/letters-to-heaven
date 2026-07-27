import '../../data/models/models.dart';

/// User-chosen prompt tone — never labeled “easy.”
enum PromptMood {
  gentle,
  ordinaryMemories,
  familyStories,
  deeperReflection,
}

extension PromptMoodX on PromptMood {
  String get label {
    switch (this) {
      case PromptMood.gentle:
        return 'Gentle';
      case PromptMood.ordinaryMemories:
        return 'Ordinary memories';
      case PromptMood.familyStories:
        return 'Family stories';
      case PromptMood.deeperReflection:
        return 'Deeper reflection';
    }
  }

  String get blurb {
    switch (this) {
      case PromptMood.gentle:
        return 'Soft questions you can leave unanswered.';
      case PromptMood.ordinaryMemories:
        return 'Everyday details, sounds, habits, and small scenes.';
      case PromptMood.familyStories:
        return 'Kitchen tables, traditions, and shared history.';
      case PromptMood.deeperReflection:
        return 'More reflective questions—only when you choose them.';
    }
  }
}

/// Tags that must not appear unless the user consents to deeper / difficult content.
const difficultSensitivityTags = {
  'anger',
  'guilt',
  'apology',
  'hardship',
  'grief',
  'end-of-life',
  'mixed-emotions',
  'boundaries',
  'unsaid-words',
};

bool promptNeedsDifficultConsent(Prompt prompt) {
  for (final tag in prompt.sensitivityTags) {
    if (difficultSensitivityTags.contains(tag.toLowerCase())) {
      return true;
    }
  }
  final text = prompt.text.toLowerCase();
  return text.contains('apology') ||
      text.contains('anger') ||
      text.contains('guilt') ||
      text.contains('forgive');
}

bool promptMatchesMood(Prompt prompt, PromptMood mood) {
  switch (mood) {
    case PromptMood.gentle:
      return prompt.intensity == 'gentle';
    case PromptMood.ordinaryMemories:
      return prompt.intensity == 'gentle' ||
          prompt.category == 'memories' ||
          prompt.sensitivityTags.any(
            (t) =>
                t == 'daily-life' ||
                t == 'sensory' ||
                t == 'food' ||
                t == 'humor' ||
                t == 'photos',
          );
    case PromptMood.familyStories:
      return prompt.intensity == 'family' ||
          prompt.sensitivityTags.any(
            (t) =>
                t == 'family' ||
                t == 'holidays' ||
                t == 'childhood' ||
                t == 'children' ||
                t == 'tradition',
          );
    case PromptMood.deeperReflection:
      return prompt.intensity == 'reflective' ||
          prompt.intensity == 'milestone' ||
          prompt.intensity == 'signs';
  }
}

/// Days before a “Not Today” prompt may appear again.
const promptDismissCooldownDays = 14;
