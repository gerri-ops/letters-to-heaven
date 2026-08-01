import '../../data/models/models.dart';

/// User-facing labels for the four MVP entry types.
String entryTypeLabel(EntryType type) {
  switch (type) {
    case EntryType.letter:
      return 'Letter';
    case EntryType.memory:
      return 'Memory';
    case EntryType.meaningfulMoment:
      return 'Meaningful Moment';
    case EntryType.keepsake:
      return 'Photo & media';
  }
}

/// Short supporting line for home / pickers.
String entryTypeBlurb(EntryType type) {
  switch (type) {
    case EntryType.letter:
      return 'Unsaid words, updates, apologies, gratitude, anger, longing.';
    case EntryType.memory:
      return 'Stories, habits, quotes, trips, ordinary details.';
    case EntryType.meaningfulMoment:
      return 'Dreams, cardinals, songs, feathers, coincidences, signs.';
    case EntryType.keepsake:
      return 'Photos, audio, video clips, recipes, documents.';
  }
}

EntryType? entryTypeFromName(String? name) {
  if (name == null || name.isEmpty) {
    return null;
  }
  return entryTypeFromStorage(name);
}

String greetingForTimeOfDay(DateTime now) {
  final hour = now.hour;
  if (hour < 12) {
    return 'Good morning';
  }
  if (hour < 17) {
    return 'Good afternoon';
  }
  return 'Good evening';
}
