import 'package:flutter/foundation.dart';

/// Privacy-safe analytics: approved event names only, no PII or entry content.
///
/// Public trust advantage: we never send sensitive entry text, loved-one names,
/// exact locations, private media, or search queries (see PRIVACY_TRUST.md).
class PrivacySafeAnalytics {
  PrivacySafeAnalytics._();

  static final PrivacySafeAnalytics instance = PrivacySafeAnalytics._();

  static const _allowedEvents = {
    'account_created',
    'memorial_created',
    'first_entry_saved',
    'entry_saved',
    'entry_deleted',
    'export_started',
    'export_completed',
    'prompt_opened',
    'subscription_restore_tapped',
    'subscription_started',
    'gift_purchased',
    'gift_redeemed',
    'biometric_enabled',
    'biometric_disabled',
    'onboarding_completed',
    'search_performed',
    'review_prompt_shown',
    'review_leave_tapped',
    'review_not_now',
    'review_do_not_ask',
  };

  /// Keys that must never appear in analytics payloads (PRD + public promise).
  static const blockedParameterKeys = {
    'body',
    'title',
    'name',
    'displayName',
    'email',
    'text',
    'query',
    'searchQuery',
    'lovedOneName',
    'memorialName',
    'location',
    'exactLocation',
    'latitude',
    'longitude',
    'mediaPath',
    'localPath',
    'remotePath',
    'transcript',
    'photo',
    'audio',
    'video',
  };

  void log(String eventName, {Map<String, Object?> parameters = const {}}) {
    if (!_allowedEvents.contains(eventName)) {
      assert(() {
        debugPrint('Analytics: blocked unapproved event $eventName');
        return true;
      }());
      return;
    }
    final safeParams = _sanitize(parameters);
    if (kDebugMode) {
      debugPrint('Analytics: $eventName $safeParams');
    }
    // Wire to Firebase Analytics when configured.
  }

  void logEntrySaved({required String type}) {
    log('entry_saved', parameters: {'type': type});
  }

  Map<String, Object?> _sanitize(Map<String, Object?> params) {
    final out = <String, Object?>{};
    for (final entry in params.entries) {
      if (blockedParameterKeys.contains(entry.key)) {
        continue;
      }
      out[entry.key] = entry.value;
    }
    return out;
  }
}
