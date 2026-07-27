import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/analytics/analytics.dart';
import 'package:letters_to_heaven/core/privacy/privacy_trust_copy.dart';

void main() {
  test('privacy trust messages match product copy', () {
    expect(PrivacyTrustCopy.messages, hasLength(9));
    expect(
      PrivacyTrustCopy.messages,
      contains('Your journal is private by default.'),
    );
    expect(
      PrivacyTrustCopy.messages,
      contains('We do not sell personal memories.'),
    );
    expect(
      PrivacyTrustCopy.messages,
      contains('No advertisements appear beside your entries.'),
    );
    expect(
      PrivacyTrustCopy.messages,
      contains('Your writing is not used to train an AI model.'),
    );
    expect(
      PrivacyTrustCopy.messages,
      contains('You control every export and invitation.'),
    );
    expect(
      PrivacyTrustCopy.messages,
      contains('Delete your data whenever you choose.'),
    );
    expect(
      PrivacyTrustCopy.messages,
      contains('Existing memories remain available after cancellation.'),
    );
    expect(
      PrivacyTrustCopy.messages,
      contains(
        'Letters to Heaven will never pretend to speak as the person you lost.',
      ),
    );
  });

  test('analytics blocks sensitive payload keys from the PRD', () {
    for (final key in [
      'body',
      'title',
      'name',
      'displayName',
      'query',
      'searchQuery',
      'lovedOneName',
      'location',
      'exactLocation',
      'latitude',
      'longitude',
      'mediaPath',
      'transcript',
    ]) {
      expect(
        PrivacySafeAnalytics.blockedParameterKeys.contains(key),
        isTrue,
        reason: 'Expected blocked analytics key: $key',
      );
    }
    expect(PrivacyTrustCopy.neverInAnalytics, hasLength(5));
  });
}
