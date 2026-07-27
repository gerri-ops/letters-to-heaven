/// Recommended Premium pricing and trial for Letters to Heaven.
///
/// Store products should match these display amounts when IAP is enabled.
abstract final class PremiumPricing {
  static const double monthlyPriceUsd = 4.99;
  static const double annualPriceUsd = 39.99;

  /// Annual plan shown as a monthly equivalent: $39.99 ÷ 12 ≈ $3.33.
  static const double annualMonthlyEquivalentUsd = 3.33;

  /// $4.99 × 12 − $39.99 = $19.89.
  static const double annualSavingsVsMonthlyUsd = 19.89;

  /// Fourteen days gives time to try several memory types and a keepsake preview
  /// without pressuring someone to journal before they are ready.
  static const int freeTrialDays = 14;

  static String get monthlyLabel =>
      '\$${monthlyPriceUsd.toStringAsFixed(2)} per month';

  static String get annualLabel =>
      '\$${annualPriceUsd.toStringAsFixed(2)} per year';

  static String get annualDisplayedAsMonthly =>
      '\$${annualMonthlyEquivalentUsd.toStringAsFixed(2)} per month, '
      'billed annually';

  static String get annualSavingsCopy =>
      'The annual plan saves \$${annualSavingsVsMonthlyUsd.toStringAsFixed(2)} '
      'compared with twelve monthly payments.';

  static String get freeTrialCopy =>
      '$freeTrialDays-day premium trial. Time to save several kinds of '
      'memories and see a keepsake preview—without a countdown on Home.';
}
