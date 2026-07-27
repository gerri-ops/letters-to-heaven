import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/billing/plan_entitlements.dart';
import 'package:letters_to_heaven/data/local/app_database.dart';
import 'package:letters_to_heaven/data/models/models.dart';
import 'package:letters_to_heaven/data/repositories/app_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppRepository repo;

  setUp(() async {
    final db = AppDatabase(
      dbName: 'repo_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await db.database;
    repo = AppRepository(database: db);
  });

  test('creates memorial and saves first letter', () async {
    final memorial = await repo.createMemorial(
      id: 'mem-1',
      ownerUid: 'user-1',
      displayName: 'Mom',
      relationship: 'Parent',
    );
    expect(memorial.displayName, 'Mom');

    final entry = await repo.upsertEntry(
      Entry(
        id: 'entry-1',
        memorialId: memorial.id,
        ownerUid: 'user-1',
        type: EntryType.letter,
        title: 'Hello',
        body: 'I wish I could tell you...',
        status: EntryStatus.saved,
      ),
    );
    expect(entry.status, EntryStatus.saved);

    final listed = await repo.listEntries(memorialId: memorial.id);
    expect(listed, hasLength(1));
    expect(listed.first.body, contains('wish'));
  });

  test('Basic caps saved entries at plan limit', () async {
    await repo.setPremium(false);
    final memorial = await repo.createMemorial(
      id: 'mem-2',
      ownerUid: 'user-1',
      displayName: 'Dad',
    );

    for (var i = 0; i < PlanEntitlements.basicEntryLimit; i++) {
      await repo.upsertEntry(
        Entry(
          id: 'e-$i',
          memorialId: memorial.id,
          ownerUid: 'user-1',
          type: EntryType.memory,
          title: 'Memory $i',
          body: 'Story $i',
          status: EntryStatus.saved,
        ),
      );
    }
    final listed = await repo.listEntries(memorialId: memorial.id);
    expect(listed, hasLength(PlanEntitlements.basicEntryLimit));

    expect(
      () => repo.upsertEntry(
        Entry(
          id: 'e-over',
          memorialId: memorial.id,
          ownerUid: 'user-1',
          type: EntryType.memory,
          title: 'One more',
          body: 'Nope',
          status: EntryStatus.saved,
        ),
      ),
      throwsA(isA<EntryLimitExceeded>()),
    );
  });

  test('Basic limits to one memorial', () async {
    await repo.setPremium(false);
    await repo.createMemorial(
      id: 'mem-a',
      ownerUid: 'user-1',
      displayName: 'Mom',
    );
    expect(
      () => repo.createMemorial(
        id: 'mem-b',
        ownerUid: 'user-1',
        displayName: 'Dad',
      ),
      throwsA(isA<MemorialLimitExceeded>()),
    );
  });

  test('search finds entry by body text', () async {
    final memorial = await repo.createMemorial(
      id: 'mem-3',
      ownerUid: 'user-1',
      displayName: 'Friend',
    );
    await repo.upsertEntry(
      Entry(
        id: 'cardinal-1',
        memorialId: memorial.id,
        ownerUid: 'user-1',
        type: EntryType.meaningfulMoment,
        title: 'Morning visit',
        body: 'A bright cardinal sat on the fence.',
        status: EntryStatus.saved,
      ),
    );

    final results = await repo.searchEntries(
      query: 'cardinal',
      memorialId: memorial.id,
    );
    expect(results, isNotEmpty);
  });
}
