import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/reviews/review_request_copy.dart';
import 'package:letters_to_heaven/core/reviews/review_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('review copy matches product recommendation', () {
    expect(
      ReviewRequestCopy.question,
      'Has Letters to Heaven helped you keep something that matters?',
    );
    expect(
      ReviewRequestCopy.supporting,
      'A short App Store review can help another grieving person find a '
      'private place for their memories.',
    );
    expect(ReviewRequestCopy.leaveReview, 'Leave a Review');
    expect(ReviewRequestCopy.notNow, 'Not Now');
    expect(ReviewRequestCopy.doNotAskAgain, 'Do Not Ask Again');
    expect(ReviewRequestCopy.allowedMoments, hasLength(5));
  });

  test('do not ask again blocks every safe trigger', () async {
    final service = ReviewRequestService.instance;
    await service.setDoNotAskAgain();
    for (final trigger in ReviewTrigger.values) {
      expect(await service.canAsk(trigger: trigger), isFalse);
    }
  });

  test('voluntary returns require several distinct visit days', () async {
    final service = ReviewRequestService.instance;
    final base = DateTime(2026, 1, 1);
    expect(
      await service.canAsk(
        trigger: ReviewTrigger.voluntaryReturns,
        now: base,
      ),
      isFalse,
    );
    for (var i = 0; i < ReviewRequestService.voluntaryReturnDaysRequired; i++) {
      await service.recordVoluntaryVisit(now: base.add(Duration(days: i)));
    }
    expect(
      await service.canAsk(
        trigger: ReviewTrigger.voluntaryReturns,
        now: base.add(const Duration(days: 10)),
      ),
      isTrue,
    );
  });

  test('not now applies a cooldown', () async {
    final service = ReviewRequestService.instance;
    final now = DateTime(2026, 3, 1);
    await service.markNotNow(now: now);
    expect(
      await service.canAsk(
        trigger: ReviewTrigger.keepsakeExported,
        now: now.add(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(
      await service.canAsk(
        trigger: ReviewTrigger.keepsakeExported,
        now: now.add(ReviewRequestService.notNowCooldown).add(
              const Duration(days: 1),
            ),
      ),
      isTrue,
    );
  });
}
