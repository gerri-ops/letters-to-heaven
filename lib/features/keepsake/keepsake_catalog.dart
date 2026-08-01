import '../../data/models/models.dart';

/// Premium Keepsake Builder book focus categories.
enum KeepsakeBookType {
  lettersToHeaven,
  favoriteMemories,
  familyRecipe,
  storiesAndTraditions,
  signsAndDreams,
  memorialInterview,
}

extension KeepsakeBookTypeX on KeepsakeBookType {
  String get title {
    switch (this) {
      case KeepsakeBookType.lettersToHeaven:
        return 'Letters to Heaven book';
      case KeepsakeBookType.favoriteMemories:
        return 'Favorite Memories book';
      case KeepsakeBookType.familyRecipe:
        return 'Family Recipe book';
      case KeepsakeBookType.storiesAndTraditions:
        return 'Stories and Traditions book';
      case KeepsakeBookType.signsAndDreams:
        return 'Signs and Dreams journal';
      case KeepsakeBookType.memorialInterview:
        return 'Memorial interview collection';
    }
  }

  String get shortLabel {
    switch (this) {
      case KeepsakeBookType.lettersToHeaven:
        return 'Letters';
      case KeepsakeBookType.favoriteMemories:
        return 'Memories';
      case KeepsakeBookType.familyRecipe:
        return 'Recipes';
      case KeepsakeBookType.storiesAndTraditions:
        return 'Stories & traditions';
      case KeepsakeBookType.signsAndDreams:
        return 'Signs & dreams';
      case KeepsakeBookType.memorialInterview:
        return 'Interviews';
    }
  }

  String get blurb {
    switch (this) {
      case KeepsakeBookType.lettersToHeaven:
        return 'Unsaid words gathered into a private book you can hold.';
      case KeepsakeBookType.favoriteMemories:
        return 'The stories and details you never want to lose.';
      case KeepsakeBookType.familyRecipe:
        return 'Kitchen memories, recipes, and the tastes of home.';
      case KeepsakeBookType.storiesAndTraditions:
        return 'Family ways, holidays, and the rituals that shaped you.';
      case KeepsakeBookType.signsAndDreams:
        return 'Cardinals, dreams, songs, and moments that felt meaningful.';
      case KeepsakeBookType.memorialInterview:
        return 'Questions answered, stories collected, voice preserved in print.';
    }
  }

  /// Soft filter hints — still allow manual selection overrides.
  bool matchesEntry(Entry entry) {
    final tags = entry.tags.map((t) => t.toLowerCase()).toList();
    final ext = entry.extensionJson;
    final template = ext['template']?.toString().toLowerCase() ?? '';
    final body = entry.body.toLowerCase();
    final title = entry.title.toLowerCase();

    switch (this) {
      case KeepsakeBookType.lettersToHeaven:
        return entry.type == EntryType.letter;
      case KeepsakeBookType.favoriteMemories:
        return entry.isFavorite || entry.type == EntryType.memory;
      case KeepsakeBookType.familyRecipe:
        return template.contains('recipe') ||
            tags.any((t) => t.contains('recipe') || t.contains('food')) ||
            title.contains('recipe') ||
            body.contains('ingredient');
      case KeepsakeBookType.storiesAndTraditions:
        return tags.any((t) =>
                t.contains('tradition') ||
                t.contains('holiday') ||
                t.contains('family')) ||
            template.contains('tradition');
      case KeepsakeBookType.signsAndDreams:
        return entry.type == EntryType.meaningfulMoment ||
            tags.any((t) =>
                t.contains('sign') ||
                t.contains('dream') ||
                t.contains('cardinal'));
      case KeepsakeBookType.memorialInterview:
        return template.contains('interview') ||
            tags.any((t) => t.contains('interview') || t.contains('question'));
    }
  }

  List<Entry> suggestedEntries(List<Entry> all) =>
      all.where(matchesEntry).toList();
}

/// Categories that currently have matching saved content.
List<KeepsakeBookType> availableBookTypesFor(List<Entry> entries) {
  return KeepsakeBookType.values
      .where((type) => entries.any(type.matchesEntry))
      .toList();
}

/// Giftable export styles — the three keepsake creations that make the product unique.
enum ExportTheme {
  /// Full memorial journal PDF with cream pages and garden accents.
  journalPdf,

  /// Clean, quiet layout — elegant and simple to print.
  simple,

  /// Greyscale, no heavy fills — lighter home printing.
  inkSaver,
}

extension ExportThemeX on ExportTheme {
  String get label {
    switch (this) {
      case ExportTheme.journalPdf:
        return 'Journal PDF';
      case ExportTheme.simple:
        return 'Simple';
      case ExportTheme.inkSaver:
        return 'Ink Saver';
    }
  }

  String get shortLabel {
    switch (this) {
      case ExportTheme.journalPdf:
        return 'Journal';
      case ExportTheme.simple:
        return 'Simple';
      case ExportTheme.inkSaver:
        return 'Ink Saver';
    }
  }

  String get blurb {
    switch (this) {
      case ExportTheme.journalPdf:
        return 'A finished memorial journal—cream pages, garden accents, ready to print or gift.';
      case ExportTheme.simple:
        return 'Quiet type and clean pages—elegant on screen and easy to print.';
      case ExportTheme.inkSaver:
        return 'Greyscale only, no heavy fills—lighter printing at home.';
    }
  }

  /// Legacy aliases used in older call sites / docs / query params.
  static ExportTheme fromLegacyName(String? name) {
    switch (name) {
      case 'journal':
      case 'journalPdf':
      case 'cardinalGarden':
      case 'Garden':
        return ExportTheme.journalPdf;
      case 'simple':
      case 'softNeutral':
      case 'Neutral':
        return ExportTheme.simple;
      case 'inkSaving':
      case 'inkSaver':
      case 'inkSavingSimple':
        return ExportTheme.inkSaver;
      default:
        for (final t in ExportTheme.values) {
          if (t.name == name) return t;
        }
        return ExportTheme.journalPdf;
    }
  }
}

/// Conversion copy for the premium keepsake preview.
abstract final class KeepsakePreviewCopy {
  static const headline = 'Turn what you saved into a keepsake you can hold.';
  static const supporting =
      'Three printable exports—Journal PDF, Simple, and Ink Saver—make Letters '
      'to Heaven more than a private journal. Your words become a finished book.';
  static const moatLine =
      'Keepsake creation is what makes this app unique: a private rescue net for '
      'memories, and a path to a finished print—not a grief program or a digital '
      'reprint of a thick journal.';
  static const stylesLine = 'Journal PDF · Simple · Ink Saver';
}

/// Placeholder pages for the keepsake preview when the journal is still empty.
abstract final class KeepsakePreviewSamples {
  static const templateEntryPrefix = 'keepsake_template_';

  static bool isTemplateId(String id) => id.startsWith(templateEntryPrefix);

  static List<Entry> templateEntries(Memorial memorial) {
    final now = DateTime.now();
    return [
      Entry(
        id: '${templateEntryPrefix}letter',
        memorialId: memorial.id,
        ownerUid: memorial.ownerUid,
        type: EntryType.letter,
        title: 'Sample letter page',
        body:
            'This is how your words will look in Journal PDF—quiet type on cream '
            'paper, ready to print or gift.',
        status: EntryStatus.saved,
        entryDate: now,
        createdAt: now,
      ),
      Entry(
        id: '${templateEntryPrefix}memory',
        memorialId: memorial.id,
        ownerUid: memorial.ownerUid,
        type: EntryType.memory,
        title: 'Sample memory page',
        body:
            'A small detail, saved before it fades, becomes part of a finished book.',
        status: EntryStatus.saved,
        entryDate: now,
        createdAt: now,
      ),
    ];
  }
}

/// Empty set means "All" focus — include every visible entry.
KeepsakeBookType primaryBookType(Set<KeepsakeBookType> types) {
  if (types.isEmpty) {
    return KeepsakeBookType.lettersToHeaven;
  }
  return types.first;
}

String bookFocusSlug(Set<KeepsakeBookType> types) {
  if (types.isEmpty) {
    return 'all';
  }
  return primaryBookType(types)
      .shortLabel
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w]+'), '_');
}

List<Entry> suggestedEntriesForBookTypes(
  Set<KeepsakeBookType> types,
  List<Entry> all,
) {
  if (types.isEmpty) {
    return List<Entry>.from(all);
  }
  final seen = <String>{};
  final merged = <Entry>[];
  for (final type in types) {
    for (final entry in type.suggestedEntries(all)) {
      if (seen.add(entry.id)) {
        merged.add(entry);
      }
    }
  }
  return merged;
}
