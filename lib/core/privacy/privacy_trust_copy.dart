/// Plain-language privacy trust messages — a product feature, not buried legalese.
abstract final class PrivacyTrustCopy {
  static const screenTitle = 'Your privacy';
  static const screenIntro =
      'Trust should be easy to read. These promises live in the product—'
      'not only in a long legal policy.';

  static const privateByDefault = 'Your journal is private by default.';
  static const doNotSell = 'We do not sell personal memories.';
  static const noAds =
      'No advertisements appear beside your entries.';
  static const noAiTraining =
      'Your writing is not used to train an AI model.';
  static const youControlExportInvite =
      'You control every export and invitation.';
  static const deleteAnytime = 'Delete your data whenever you choose.';
  static const remainsAfterCancel =
      'Existing memories remain available after cancellation.';
  static const neverPretend =
      'Letters to Heaven will never pretend to speak as the person you lost.';

  static const notCounseling =
      'Technology protects and organizes the memory. It does not tell you '
      'what the memory means—and it is not grief counseling.';

  /// Primary trust messages shown throughout the product.
  static const messages = <String>[
    privateByDefault,
    doNotSell,
    noAds,
    noAiTraining,
    youControlExportInvite,
    deleteAnytime,
    remainsAfterCancel,
    neverPretend,
    notCounseling,
  ];

  static const analyticsAdvantageHeadline =
      'What we never put in analytics';

  static const analyticsAdvantageBody =
      'We do not send sensitive entry text, loved-one names, exact locations, '
      'private media, or search queries in analytics payloads. Product events '
      'use approved names only—so privacy is a public trust advantage, not a '
      'hidden footnote.';

  static const neverInAnalytics = <String>[
    'Sensitive entry text',
    'Loved-one names',
    'Exact locations',
    'Private media',
    'Search queries',
  ];

  static const openTrustLabel = 'Read our privacy promises';
  static const legalPolicyLabel = 'Privacy policy';
  static const legalPolicyUrl =
      'https://cardinalmemorials.com/privacy-policy/#lthapp';
  static const legalPolicySubtitle =
      'cardinalmemorials.com/privacy-policy/#lthapp';
  static const settingsSectionTitle = 'Privacy & trust';
}
