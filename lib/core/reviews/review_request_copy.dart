/// Soft App Store review request — only after safe success moments.
abstract final class ReviewRequestCopy {
  static const question =
      'Has Letters to Heaven helped you keep something that matters?';

  static const supporting =
      'A short App Store review can help another grieving person find a '
      'private place for their memories.';

  static const leaveReview = 'Leave a Review';
  static const notNow = 'Not Now';
  static const doNotAskAgain = 'Do Not Ask Again';

  /// Moments that may invite a review (never writing a painful letter).
  static const allowedMoments = <String>[
    'A keepsake has exported successfully',
    'The third memory has been preserved',
    'A backup has completed',
    'A family contribution has been accepted',
    'The user has returned several times voluntarily',
  ];
}

/// Safe success moments that may surface a review request.
enum ReviewTrigger {
  /// Keepsake PDF shared/exported successfully.
  keepsakeExported,

  /// Third saved memory preserved (not a letter).
  thirdMemoryPreserved,

  /// Encrypted backup / sync finished successfully.
  backupCompleted,

  /// Family Circle: owner accepted a contribution (when shipped).
  familyContributionAccepted,

  /// Several voluntary return visits on different days.
  voluntaryReturns,
}

extension ReviewTriggerX on ReviewTrigger {
  String get analyticsName => name;
}
