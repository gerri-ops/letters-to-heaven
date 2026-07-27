import '../../data/models/models.dart';
import '../shared/filtered_entries_screen.dart';

/// @deprecated Prefer [LibraryScreen].
class MemoriesScreen extends FilteredEntriesScreen {
  const MemoriesScreen({super.key})
      : super(
          title: 'Memories',
          intro: 'Stories and ordinary details to hold close.',
          types: const {EntryType.memory},
        );
}
