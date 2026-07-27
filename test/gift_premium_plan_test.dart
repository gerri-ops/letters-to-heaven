import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/billing/gift_premium_plan.dart';
import 'package:letters_to_heaven/data/local/app_database.dart';
import 'package:letters_to_heaven/data/repositories/app_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('gift offer is one year, non-renewing, at annual gift price', () {
    expect(GiftPremiumPlan.productName, 'One Year of Letters to Heaven Premium');
    expect(GiftPremiumPlan.priceUsd, 39.99);
    expect(GiftPremiumPlan.durationDays, 365);
    expect(GiftPremiumPlan.autoRenews, isFalse);
    expect(
      GiftPremiumPlan.giftMessage,
      'I know there are things you may want to remember, write, or keep. '
      'There is no schedule and no expectation. This is here whenever you need it.',
    );
  });

  test('gift surfaces never use banned healing phrases', () {
    final surface = [
      GiftPremiumPlan.productName,
      GiftPremiumPlan.offerLabel,
      GiftPremiumPlan.giftMessage,
      GiftPremiumPlan.nonRenewingNotice,
      GiftPremiumPlan.purchaserIntro,
      GiftPremiumPlan.giveCta,
      GiftPremiumPlan.redeemCta,
      GiftPremiumPlan.shareCta,
    ].join(' ');

    for (final banned in GiftPremiumPlan.bannedPhrases) {
      expect(
        surface.toLowerCase().contains(banned.toLowerCase()),
        isFalse,
        reason: 'Banned gift phrase: $banned',
      );
    }
  });

  test('redeemed gift grants premium that expires and never sets paid flag',
      () async {
    final db = AppDatabase(
      dbName: 'gift_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    await db.database;
    final repo = AppRepository(database: db);
    final now = DateTime(2026, 1, 1, 12);

    expect(await repo.isPremium(now: now), isFalse);
    expect(GiftPremiumPlan.autoRenews, isFalse);

    final issued = await repo.purchaseGiftLocal(now: now);
    expect(issued.code, startsWith('LTH-GIFT-'));
    expect(await repo.isSubscribed(), isFalse);

    final expires = await repo.redeemGiftCode(issued.code, now: now);
    expect(expires, DateTime(2027, 1, 1, 12));
    expect(await repo.isGiftPremiumActive(now: now), isTrue);
    expect(await repo.isPremium(), isTrue);
    expect(await repo.isSubscribed(), isFalse);

    expect(
      await repo.isGiftPremiumActive(now: expires.add(const Duration(days: 1))),
      isFalse,
    );
    expect(
      () => repo.redeemGiftCode(issued.code, now: now),
      throwsA(isA<GiftRedeemException>()),
    );
  });
}
