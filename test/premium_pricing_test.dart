import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/billing/plan_entitlements.dart';
import 'package:letters_to_heaven/core/billing/premium_pricing.dart';
import 'package:letters_to_heaven/data/local/app_database.dart';
import 'package:letters_to_heaven/data/models/models.dart';
import 'package:letters_to_heaven/data/repositories/app_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('recommended pricing math matches product copy', () {
    expect(PremiumPricing.monthlyPriceUsd, 4.99);
    expect(PremiumPricing.annualPriceUsd, 39.99);
    expect(PremiumPricing.annualMonthlyEquivalentUsd, 3.33);
    expect(PremiumPricing.freeTrialDays, 14);
    final twelveMonthly = PremiumPricing.monthlyPriceUsd * 12;
    final savings = twelveMonthly - PremiumPricing.annualPriceUsd;
    expect(savings, closeTo(PremiumPricing.annualSavingsVsMonthlyUsd, 0.001));
  });

  test('Basic includes ten gentle prompts; Premium unlocks all', () {
    final all = List.generate(
      20,
      (i) => Prompt(
        id: 'p$i',
        category: 'letters',
        text: 'Prompt $i',
        intensity: i < 12 ? 'gentle' : 'reflective',
      ),
    );
    final basic = PlanEntitlements.promptsForPlan(all: all, premium: false);
    expect(basic, hasLength(PlanEntitlements.basicGentlePromptLimit));
    expect(basic.every((p) => p.intensity == 'gentle'), isTrue);
    expect(
      PlanEntitlements.promptsForPlan(all: all, premium: true),
      hasLength(20),
    );
  });

  test('Basic enforces saved entry cap', () async {
    final db = AppDatabase(
      dbName: 'basic_entry_cap_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await db.database;
    final repo = AppRepository(database: db);
    await repo.setPremium(false);
    final memorial = await repo.createMemorial(
      id: 'mem-u',
      ownerUid: 'user-1',
      displayName: 'Mom',
    );
    for (var i = 0; i < PlanEntitlements.basicEntryLimit; i++) {
      await repo.upsertEntry(
        Entry(
          id: 'e-$i',
          memorialId: memorial.id,
          ownerUid: 'user-1',
          type: EntryType.letter,
          title: 'Letter $i',
          body: 'Body $i',
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
          type: EntryType.letter,
          title: 'Over',
          body: 'Body',
          status: EntryStatus.saved,
        ),
      ),
      throwsA(isA<EntryLimitExceeded>()),
    );
  });

  test('Basic allows one memorial only', () async {
    final db = AppDatabase(
      dbName: 'basic_mem_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await db.database;
    final repo = AppRepository(database: db);
    await repo.setPremium(false);
    await repo.createMemorial(
      id: 'mem-1',
      ownerUid: 'user-1',
      displayName: 'Mom',
    );
    expect(
      () => repo.createMemorial(
        id: 'mem-2',
        ownerUid: 'user-1',
        displayName: 'Dad',
      ),
      throwsA(isA<MemorialLimitExceeded>()),
    );
  });

  test('14-day trial grants premium without paid flag', () async {
    final db = AppDatabase(
      dbName: 'trial_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await db.database;
    final repo = AppRepository(database: db);

    expect(await repo.isPremium(), isFalse);
    final startedAt = DateTime.now();
    expect(await repo.startPremiumTrial(now: startedAt), isTrue);
    expect(await repo.isSubscribed(), isFalse);
    expect(
      await repo.isTrialActive(now: startedAt.add(const Duration(days: 7))),
      isTrue,
    );
    expect(await repo.isPremium(), isTrue);
    expect(
      await repo.isTrialActive(now: startedAt.add(const Duration(days: 14))),
      isFalse,
    );
    expect(
      await repo.startPremiumTrial(now: startedAt.add(const Duration(days: 20))),
      isFalse,
    );
  });
}
