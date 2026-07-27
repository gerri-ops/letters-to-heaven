import '../../data/models/models.dart';

/// A custom field stored in [Entry.extensionJson].
class EntryFieldDef {
  const EntryFieldDef({
    required this.key,
    required this.label,
    this.hint,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final String? hint;
  final int maxLines;
}

/// Optional soft template within a core entry type (not a separate type).
class EntryTemplateOption {
  const EntryTemplateOption({
    required this.id,
    required this.label,
    this.hint,
  });

  final String id;
  final String label;
  final String? hint;
}

/// Tailored writing template for each core [EntryType].
class EntryTypeTemplate {
  const EntryTypeTemplate({
    required this.newTitle,
    required this.editTitle,
    required this.guidance,
    required this.titleLabel,
    required this.titleHint,
    required this.bodyLabel,
    required this.bodyHint,
    this.bodyMaxLines = 10,
    this.fields = const [],
    this.templateOptions = const [],
    this.showEntryDate = false,
    this.entryDateLabel = 'When this happened',
    this.emphasizePhotos = false,
  });

  final String newTitle;
  final String editTitle;
  final String guidance;
  final String titleLabel;
  final String titleHint;
  final String bodyLabel;
  final String bodyHint;
  final int bodyMaxLines;
  final List<EntryFieldDef> fields;
  final List<EntryTemplateOption> templateOptions;
  final bool showEntryDate;
  final String entryDateLabel;
  final bool emphasizePhotos;
}

EntryTypeTemplate templateFor(EntryType type) {
  switch (type) {
    case EntryType.letter:
      return const EntryTypeTemplate(
        newTitle: 'New letter',
        editTitle: 'Edit letter',
        guidance:
            'Write in your own voice. This app never generates messages '
            'from someone who has died.',
        titleLabel: 'Subject (optional)',
        titleHint: 'Leave blank if you want',
        bodyLabel: 'Your letter',
        bodyHint: 'Say what you need to say—one sentence is enough.',
        bodyMaxLines: 14,
        templateOptions: [
          EntryTemplateOption(id: 'unsaid', label: 'Unsaid words'),
          EntryTemplateOption(id: 'update', label: 'An update'),
          EntryTemplateOption(id: 'apology', label: 'Apology'),
          EntryTemplateOption(id: 'gratitude', label: 'Gratitude'),
          EntryTemplateOption(id: 'anger', label: 'Anger'),
          EntryTemplateOption(id: 'longing', label: 'Longing'),
        ],
      );
    case EntryType.memory:
      return const EntryTypeTemplate(
        newTitle: 'New memory',
        editTitle: 'Edit memory',
        guidance:
            'Capture one story or detail so it stays vivid—ordinary moments count.',
        titleLabel: 'Title (optional)',
        titleHint: 'A short name you will recognize later',
        bodyLabel: 'The memory',
        bodyHint:
            'A phrase, habit, joke, place, trip, or anything you do not want to lose.',
        bodyMaxLines: 12,
        showEntryDate: true,
        entryDateLabel: 'When it happened (optional)',
        emphasizePhotos: true,
        templateOptions: [
          EntryTemplateOption(id: 'story', label: 'Story'),
          EntryTemplateOption(id: 'habit', label: 'Habit or quote'),
          EntryTemplateOption(id: 'trip', label: 'Trip'),
          EntryTemplateOption(id: 'interview', label: 'Someone else’s story'),
          EntryTemplateOption(id: 'tradition', label: 'Tradition'),
          EntryTemplateOption(id: 'milestone', label: 'Milestone'),
        ],
        fields: [
          EntryFieldDef(
            key: 'place',
            label: 'Place (optional)',
            hint: 'Kitchen, beach, their favorite chair…',
          ),
        ],
      );
    case EntryType.meaningfulMoment:
      return const EntryTypeTemplate(
        newTitle: 'New meaningful moment',
        editTitle: 'Edit meaningful moment',
        guidance:
            'Save what felt meaningful to you—no need to explain it away.',
        titleLabel: 'What stood out (optional)',
        titleHint: 'A short name for this moment',
        bodyLabel: 'What you experienced',
        bodyHint:
            'A dream, cardinal, song, feather, coincidence, or quiet sign.',
        bodyMaxLines: 10,
        showEntryDate: true,
        entryDateLabel: 'When you noticed it',
        templateOptions: [
          EntryTemplateOption(id: 'dream', label: 'Dream'),
          EntryTemplateOption(id: 'cardinal', label: 'Cardinal'),
          EntryTemplateOption(id: 'song', label: 'Song'),
          EntryTemplateOption(id: 'feather', label: 'Feather or nature'),
          EntryTemplateOption(id: 'coincidence', label: 'Coincidence'),
          EntryTemplateOption(id: 'sign', label: 'Sign'),
        ],
        fields: [
          EntryFieldDef(
            key: 'place',
            label: 'Where you were (optional)',
            hint: 'Window, driveway, walk…',
          ),
        ],
      );
    case EntryType.keepsake:
      return const EntryTypeTemplate(
        newTitle: 'New keepsake',
        editTitle: 'Edit keepsake',
        guidance:
            'Keep the image, sound, recipe, or document with a few words if you want.',
        titleLabel: 'Name (optional)',
        titleHint: 'What you will call this keepsake',
        bodyLabel: 'A note (optional)',
        bodyHint: 'Context you want beside the file—or leave blank.',
        bodyMaxLines: 8,
        emphasizePhotos: true,
        templateOptions: [
          EntryTemplateOption(id: 'photo', label: 'Photo'),
          EntryTemplateOption(id: 'audio', label: 'Audio'),
          EntryTemplateOption(id: 'voice', label: 'Voice keepsake'),
          EntryTemplateOption(id: 'video', label: 'Video'),
          EntryTemplateOption(id: 'recipe', label: 'Recipe'),
          EntryTemplateOption(id: 'document', label: 'Document'),
        ],
        fields: [
          EntryFieldDef(
            key: 'ingredients',
            label: 'Ingredients (if a recipe)',
            hint: 'Optional',
            maxLines: 4,
          ),
          EntryFieldDef(
            key: 'speaker',
            label: 'Who is speaking (if voice)',
            hint: 'Optional',
          ),
          EntryFieldDef(
            key: 'transcript',
            label: 'Transcript (if voice)',
            hint: 'Optional',
            maxLines: 5,
          ),
        ],
      );
  }
}

String? fieldLabelForKey(EntryType type, String key) {
  for (final field in templateFor(type).fields) {
    if (field.key == key) {
      return field.label;
    }
  }
  const fallback = {
    'place': 'Place',
    'mood': 'Mood',
    'ingredients': 'Ingredients',
    'instructions': 'How to make it',
    'template': 'Template',
  };
  return fallback[key];
}
