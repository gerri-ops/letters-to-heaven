import '../../data/models/models.dart';

/// Letters to Heaven Basic vs Premium entitlements.
///
/// Basic is useful on purpose: writing is never hard-paywalled.
/// Search, privacy controls, and access to existing memories stay free forever.
/// Premium sells protection, media preservation, keepsake creation, and family legacy.
abstract final class PlanEntitlements {
  static const String basicName = 'Letters to Heaven Basic';
  static const String premiumName = 'Letters to Heaven Premium';

  static const int basicMemorialLimit = 1;
  static const int basicPhotosPerEntry = 1;
  static const int basicGentlePromptLimit = 10;

  /// Features that must never be locked behind Premium.
  static const neverPremiumOnly = <String>[
    'Search across your journal',
    'Privacy controls and plain-language trust promises',
    'Access to everything you already saved',
  ];

  static const basicFeatures = <String>[
    'One memorial',
    'Unlimited text letters and memories',
    'One photo per entry',
    'Ten gentle prompts',
    'Search and favorites',
    'Local device storage',
    'Biometric lock',
    'Plain-text and basic data export',
    'Access to crisis and bereavement resources',
    'Existing content remains available forever',
    'Private by default — no ads beside your entries',
  ];

  static const premiumFeatures = <String>[
    'Secure encrypted cloud backup',
    'Cross-device syncing',
    'Unlimited photos',
    'Voice recordings and audio uploads',
    'Voice transcription (private; never clones a loved one’s voice)',
    'Video keepsakes',
    'Full prompt and template library',
    'Multiple memorials — a separate private place for each person or pet',
    'One-year Premium gift (non-renewing) for friends and family',
    'Complete PDF Keepsake Builder (giftable books, not a data dump)',
    'Three keepsake exports: Journal PDF, Simple, and Ink Saver',
    'Private remembrance-date controls',
    'Family contributions when released',
    'Priority support',
  ];

  static const premiumSells =
      'Premium sells protection, media preservation, keepsake creation, '
      'and family legacy—not AI grief counseling, and not the right to write '
      'or to keep what you already saved.';

  static const noHardPaywallCopy =
      'Writing stays open on Basic. A hard paywall before a letter would '
      'damage trust; a free plan with nothing useful to do would feel predatory.';

  static int maxPhotosPerEntry({required bool premium}) =>
      premium ? 9999 : basicPhotosPerEntry;

  static int maxMemorials({required bool premium}) =>
      premium ? 9999 : basicMemorialLimit;

  static bool canAddPhoto({
    required bool premium,
    required int currentPhotoCount,
  }) {
    return currentPhotoCount < maxPhotosPerEntry(premium: premium);
  }

  static bool canCreateMemorial({
    required bool premium,
    required int existingMemorialCount,
  }) {
    return existingMemorialCount < maxMemorials(premium: premium);
  }

  /// First [basicGentlePromptLimit] gentle prompts for Basic; Premium sees all.
  static List<Prompt> promptsForPlan({
    required List<Prompt> all,
    required bool premium,
  }) {
    if (premium) {
      return all;
    }
    final gentle = all.where((p) => p.intensity == 'gentle').toList();
    if (gentle.length >= basicGentlePromptLimit) {
      return gentle.take(basicGentlePromptLimit).toList();
    }
    final ids = gentle.map((p) => p.id).toSet();
    final padded = [...gentle];
    for (final p in all) {
      if (padded.length >= basicGentlePromptLimit) {
        break;
      }
      if (!ids.contains(p.id)) {
        padded.add(p);
        ids.add(p.id);
      }
    }
    return padded;
  }

  static bool isPromptIncluded({
    required Prompt prompt,
    required List<Prompt> all,
    required bool premium,
  }) {
    if (premium) {
      return true;
    }
    return promptsForPlan(all: all, premium: false)
        .any((p) => p.id == prompt.id);
  }
}
