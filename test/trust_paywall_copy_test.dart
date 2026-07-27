import 'package:flutter_test/flutter_test.dart';
import 'package:letters_to_heaven/core/billing/trust_paywall_copy.dart';
import 'package:letters_to_heaven/core/marketing/commercial_position.dart';

void main() {
  test('commercial position uses the recommended headline and promise', () {
    expect(
      CommercialPosition.headline,
      'Save the little things before time carries them away.',
    );
    expect(
      CommercialPosition.marketAs,
      'The private place that catches a memory before it disappears.',
    );
    expect(CommercialPosition.subscriptionPromise, contains(r'$4.99 a month'));
    expect(CommercialPosition.subscriptionPromise, contains('keepsake'));
    expect(CommercialPosition.doNotMarketAs, hasLength(3));
  });

  test('trust paywall mirrors commercial subscription promise', () {
    expect(TrustPaywallCopy.headline, CommercialPosition.headline);
    expect(
      TrustPaywallCopy.supporting,
      CommercialPosition.subscriptionPromise,
    );
    expect(TrustPaywallCopy.startTrialLabel, 'Start 14-Day Free Trial');
    expect(TrustPaywallCopy.continueBasicLabel, 'Continue With Basic');
    expect(TrustPaywallCopy.benefits, hasLength(6));
    expect(
      TrustPaywallCopy.benefits.any((b) => b.toLowerCase().contains('prompt')),
      isFalse,
      reason: 'Do not sell Premium primarily as a prompt library',
    );

    final surface = [
      TrustPaywallCopy.headline,
      TrustPaywallCopy.supporting,
      ...TrustPaywallCopy.benefits,
      TrustPaywallCopy.trustStatement,
      TrustPaywallCopy.startTrialLabel,
      TrustPaywallCopy.continueBasicLabel,
    ].join(' ');

    for (final banned in TrustPaywallCopy.bannedPhrases) {
      expect(
        surface.toLowerCase().contains(banned.toLowerCase()),
        isFalse,
        reason: 'Banned phrase leaked into paywall: $banned',
      );
    }
  });
}
