import '../../data/models/models.dart';
import '../shared/filtered_entries_screen.dart';

/// All saved entries across the four MVP types.
class LibraryScreen extends FilteredEntriesScreen {
  const LibraryScreen({super.key})
      : super(
          title: 'Library',
          intro: 'Letters, memories, meaningful moments, and keepsakes—in one place.',
          types: const {
            EntryType.letter,
            EntryType.memory,
            EntryType.meaningfulMoment,
            EntryType.keepsake,
          },
        );
}
