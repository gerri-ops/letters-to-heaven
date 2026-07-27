import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../analytics/analytics.dart';
import 'review_request_copy.dart';
import '../../features/reviews/review_request_sheet.dart';

/// Asks for App Store reviews only after safe success moments.
///
/// Never ask immediately after someone writes a painful letter.
class ReviewRequestService {
  ReviewRequestService._();

  static final ReviewRequestService instance = ReviewRequestService._();

  static const _keyDoNotAsk = 'review_do_not_ask';
  static const _keyReviewed = 'review_left';
  static const _keyNotNowUntil = 'review_not_now_until';
  static const _keyVisitDays = 'review_visit_days';
  static const _keyLastShownAt = 'review_last_shown_at';
  static const _keyAskedForTrigger = 'review_asked_triggers';
  static const _keyQueuedTriggers = 'review_queued_triggers';

  /// Distinct calendar days before [ReviewTrigger.voluntaryReturns] may fire.
  static const int voluntaryReturnDaysRequired = 4;

  /// Cooldown after "Not Now" before another ask.
  static const Duration notNowCooldown = Duration(days: 21);

  /// Minimum gap between any two review prompts.
  static const Duration minGapBetweenPrompts = Duration(days: 14);

  static const androidPackageId = 'com.cardinalmemorials.letters_to_heaven';

  /// Set when the App Store listing is live.
  static const iosAppStoreId = '';

  final InAppReview _inAppReview = InAppReview.instance;

  Future<bool> get doNotAskAgain async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDoNotAsk) ?? false;
  }

  Future<void> setDoNotAskAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDoNotAsk, true);
  }

  Future<void> markReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReviewed, true);
  }

  Future<void> markNotNow({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final until = (now ?? DateTime.now()).add(notNowCooldown);
    await prefs.setString(_keyNotNowUntil, until.toUtc().toIso8601String());
  }

  /// Records a voluntary app open day (Home after onboarding).
  Future<int> recordVoluntaryVisit({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final day = _dayKey(now ?? DateTime.now());
    final days = prefs.getStringList(_keyVisitDays) ?? <String>[];
    if (!days.contains(day)) {
      days.add(day);
      await prefs.setStringList(_keyVisitDays, days);
    }
    return days.length;
  }

  Future<int> voluntaryVisitDayCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyVisitDays) ?? <String>[]).length;
  }

  /// Queue a safe moment to present later (e.g. after stepping away from writing).
  Future<void> queueTrigger(ReviewTrigger trigger) async {
    final prefs = await SharedPreferences.getInstance();
    final queued = prefs.getStringList(_keyQueuedTriggers) ?? <String>[];
    if (!queued.contains(trigger.name)) {
      queued.add(trigger.name);
      await prefs.setStringList(_keyQueuedTriggers, queued);
    }
  }

  Future<bool> canAsk({
    required ReviewTrigger trigger,
    DateTime? now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyDoNotAsk) ?? false) {
      return false;
    }
    if (prefs.getBool(_keyReviewed) ?? false) {
      return false;
    }

    final clock = now ?? DateTime.now();
    final notNowRaw = prefs.getString(_keyNotNowUntil);
    if (notNowRaw != null) {
      final until = DateTime.tryParse(notNowRaw);
      if (until != null && clock.isBefore(until)) {
        return false;
      }
    }

    final lastShownRaw = prefs.getString(_keyLastShownAt);
    if (lastShownRaw != null) {
      final last = DateTime.tryParse(lastShownRaw);
      if (last != null && clock.difference(last) < minGapBetweenPrompts) {
        return false;
      }
    }

    final asked = prefs.getStringList(_keyAskedForTrigger) ?? <String>[];
    if (asked.contains(trigger.name)) {
      return false;
    }

    if (trigger == ReviewTrigger.voluntaryReturns) {
      final days = prefs.getStringList(_keyVisitDays) ?? <String>[];
      if (days.length < voluntaryReturnDaysRequired) {
        return false;
      }
    }

    return true;
  }

  /// Shows the soft review sheet if eligible for this safe success moment.
  Future<void> maybeAsk(
    BuildContext context, {
    required ReviewTrigger trigger,
    bool queueIfWritingExit = false,
  }) async {
    if (queueIfWritingExit) {
      await queueTrigger(trigger);
      return;
    }
    if (!await canAsk(trigger: trigger)) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _present(context, trigger);
  }

  /// Presents at most one queued or voluntary-return prompt (call from Home).
  Future<void> presentFromHome(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await recordVoluntaryVisit();

    final queued = prefs.getStringList(_keyQueuedTriggers) ?? <String>[];
    for (final name in List<String>.from(queued)) {
      ReviewTrigger? trigger;
      for (final value in ReviewTrigger.values) {
        if (value.name == name) {
          trigger = value;
          break;
        }
      }
      if (trigger == null) {
        queued.remove(name);
        continue;
      }
      if (await canAsk(trigger: trigger)) {
        queued.remove(name);
        await prefs.setStringList(_keyQueuedTriggers, queued);
        if (!context.mounted) {
          return;
        }
        await _present(context, trigger);
        return;
      }
    }

    if (await canAsk(trigger: ReviewTrigger.voluntaryReturns)) {
      if (!context.mounted) {
        return;
      }
      await _present(context, ReviewTrigger.voluntaryReturns);
    }
  }

  Future<void> _present(BuildContext context, ReviewTrigger trigger) async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getStringList(_keyAskedForTrigger) ?? <String>[];
    if (!asked.contains(trigger.name)) {
      asked.add(trigger.name);
      await prefs.setStringList(_keyAskedForTrigger, asked);
    }
    await prefs.setString(
      _keyLastShownAt,
      DateTime.now().toUtc().toIso8601String(),
    );

    PrivacySafeAnalytics.instance.log(
      'review_prompt_shown',
      parameters: {'trigger': trigger.analyticsName},
    );

    if (!context.mounted) {
      return;
    }

    final choice = await showReviewRequestSheet(context);
    if (!context.mounted || choice == null) {
      return;
    }

    switch (choice) {
      case ReviewRequestChoice.leaveReview:
        PrivacySafeAnalytics.instance.log('review_leave_tapped');
        await markReviewed();
        await openStoreReview();
      case ReviewRequestChoice.notNow:
        PrivacySafeAnalytics.instance.log('review_not_now');
        await markNotNow();
      case ReviewRequestChoice.doNotAskAgain:
        PrivacySafeAnalytics.instance.log('review_do_not_ask');
        await setDoNotAskAgain();
    }
  }

  Future<void> openStoreReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        return;
      }
    } catch (e) {
      debugPrint('In-app review unavailable: $e');
    }

    try {
      await _inAppReview.openStoreListing(
        appStoreId: iosAppStoreId.isEmpty ? null : iosAppStoreId,
      );
    } catch (e) {
      debugPrint('Store listing open failed: $e');
      final uri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$androidPackageId',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Family Circle hook — call when an owner accepts a contribution.
  Future<void> onFamilyContributionAccepted(BuildContext context) {
    return maybeAsk(
      context,
      trigger: ReviewTrigger.familyContributionAccepted,
    );
  }

  String _dayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
