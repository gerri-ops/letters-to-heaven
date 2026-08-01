/// Public Stripe Pricing Table config (safe to ship in the client).
///
/// Secret keys and Price IDs for webhooks stay in Firebase Functions secrets.
abstract final class StripePricingTableConfig {
  static const pricingTableId = 'prctbl_1Txx4WDJyVZEDaoIqlN5lxHe';
  static const publishableKey =
      'pk_live_51S06UADJyVZEDaoICOd8BXNTAWEMf7EYErW7eimHlrjGoZeW0QusDMJtJzfGdu9uYuICNcSyIu2U6YbSrnTNYPvq00RlPNT156';

  /// Hosted page that embeds the Pricing Table with client-reference-id.
  static const pricingPagePath = '/pricing.html';
}
