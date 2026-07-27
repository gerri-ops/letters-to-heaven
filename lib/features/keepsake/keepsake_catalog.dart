import '../../data/models/models.dart';

/// Premium Keepsake Builder book formats — the product’s commercial moat.
enum KeepsakeBookType {
  lettersToHeaven,
  favoriteMemories,
  familyRecipe,
  storiesAndTraditions,
  signsAndDreams,
  remembranceBooklet,
  memorialInterview,
  onePageRemembrance,
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
      case KeepsakeBookType.remembranceBooklet:
        return 'Birthday or anniversary remembrance booklet';
      case KeepsakeBookType.memorialInterview:
        return 'Memorial interview collection';
      case KeepsakeBookType.onePageRemembrance:
        return 'One-page remembrance print';
    }
  }

  String get shortLabel {
    switch (this) {
      case KeepsakeBookType.lettersToHeaven:
        return 'Letters book';
      case KeepsakeBookType.favoriteMemories:
        return 'Favorite memories';
      case KeepsakeBookType.familyRecipe:
        return 'Recipe book';
      case KeepsakeBookType.storiesAndTraditions:
        return 'Stories & traditions';
      case KeepsakeBookType.signsAndDreams:
        return 'Signs & dreams';
      case KeepsakeBookType.remembranceBooklet:
        return 'Remembrance booklet';
      case KeepsakeBookType.memorialInterview:
        return 'Interview collection';
      case KeepsakeBookType.onePageRemembrance:
        return 'One-page print';
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
      case KeepsakeBookType.remembranceBooklet:
        return 'A gentle booklet for birthdays, anniversaries, and hard days.';
      case KeepsakeBookType.memorialInterview:
        return 'Questions answered, stories collected, voice preserved in print.';
      case KeepsakeBookType.onePageRemembrance:
        return 'A single printable page for a frame, service, or quiet shelf.';
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
        return entry.type == EntryType.memory ||
            tags.any((t) =>
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
      case KeepsakeBookType.remembranceBooklet:
        return true;
      case KeepsakeBookType.memorialInterview:
        return template.contains('interview') ||
            tags.any((t) => t.contains('interview') || t.contains('question'));
      case KeepsakeBookType.onePageRemembrance:
        return entry.isFavorite || true;
    }
  }

  List<Entry> suggestedEntries(List<Entry> all) {
    final matched = all.where(matchesEntry).toList();
    if (matched.isNotEmpty) {
      return matched;
    }
    return all;
  }
}

/// Giftable export styles for the Premium Keepsake Builder.
enum ExportTheme {
  /// Cream pages, cardinal accents, garden artwork — giftable keepsake print.
  cardinalGarden,

  /// Soft neutrals, calm type — elegant and quiet.
  softNeutral,

  /// Greyscale, no fills — lighter home printing.
  inkSavingSimple,
}

extension ExportThemeX on ExportTheme {
  String get label {
    switch (this) {
      case ExportTheme.cardinalGarden:
        return 'Cardinal Garden';
      case ExportTheme.softNeutral:
        return 'Soft Neutral';
      case ExportTheme.inkSavingSimple:
        return 'Ink-Saving Simple';
    }
  }

  String get blurb {
    switch (this) {
      case ExportTheme.cardinalGarden:
        return 'Cream pages, cardinal red, and garden accents—made to feel giftable.';
      case ExportTheme.softNeutral:
        return 'Quiet neutrals and clean type—elegant on screen and in print.';
      case ExportTheme.inkSavingSimple:
        return 'Greyscale only, no heavy fills—lighter printing at home.';
    }
  }

  /// Legacy aliases used in older call sites / docs.
  static ExportTheme fromLegacyName(String? name) {
    switch (name) {
      case 'journal':
        return ExportTheme.cardinalGarden;
      case 'simple':
        return ExportTheme.softNeutral;
      case 'inkSaving':
        return ExportTheme.inkSavingSimple;
      default:
        for (final t in ExportTheme.values) {
          if (t.name == name) return t;
        }
        return ExportTheme.cardinalGarden;
    }
  }
}

/// Conversion copy for the premium keepsake preview.
abstract final class KeepsakePreviewCopy {
  static const headline = 'You have already begun a keepsake.';
  static const supporting =
      'Your words, photos, and voices can become a private book whenever you choose—'
      'the clearest reason Premium exists.';
  static const moatLine =
      'Letters to Heaven is a private rescue net for memories, and a path to a '
      'finished keepsake—not a grief program or a digital reprint of a thick journal.';
}
