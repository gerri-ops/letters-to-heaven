import '../../data/models/models.dart';
import '../shared/filtered_entries_screen.dart';

/// @deprecated Prefer [LibraryScreen]. Kept for older deep links.
class JournalScreen extends FilteredEntriesScreen {
  const JournalScreen({super.key})
      : super(
          title: 'Letters',
          intro: 'Letters and words you still need somewhere to go.',
          types: const {EntryType.letter},
        );
}
