/// Non-renewing gift of Letters to Heaven Premium.
///
/// Friends and family often want to give something when they do not know what
/// to say. This is a one-year plan that does not renew for the recipient.
abstract final class GiftPremiumPlan {
  static const String productName = 'One Year of Letters to Heaven Premium';
  static const double priceUsd = 39.99;

  /// Calendar year of access from the day the gift is redeemed.
  static const int durationDays = 365;

  /// Hard product rule: gifts never auto-renew for the recipient.
  static const bool autoRenews = false;

  /// Store product id for a non-renewing / non-subscription IAP when enabled.
  static const String productId = 'lth_premium_gift_1y_nonrenewing';

  static String get priceLabel => '\$${priceUsd.toStringAsFixed(2)}';

  static String get offerLabel => '$productName, $priceLabel';

  static const String giftMessage =
      'I know there are things you may want to remember, write, or keep. '
      'There is no schedule and no expectation. This is here whenever you need it.';

  static const String nonRenewingNotice =
      'This gift does not renew. When the year ends, Premium simply ends unless '
      'they choose a plan later.';

  static const String purchaserIntro =
      'Grief products are often bought by friends and family who do not know '
      'what to say. A year of Premium gives them a private place to remember, '
      'write, and keep—without a subscription that keeps charging.';

  static const String giveCta = 'Give One Year of Premium';
  static const String redeemCta = 'Redeem a Gift';
  static const String shareCta = 'Share Gift Message & Code';

  /// Phrases that must never appear on gift surfaces.
  static const bannedPhrases = <String>[
    'I hope this helps you heal',
    'A gift to move forward',
    'Your grief journey starts here',
    'Find closure',
    'Feel better every day',
  ];
}
