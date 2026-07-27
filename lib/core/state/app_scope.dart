import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../analytics/analytics.dart';
import '../firebase/auth_service.dart';
import '../reminders/reminder_copy.dart';
import '../retention/retention_copy.dart';
import '../security/biometric_lock.dart';
import '../sync/sync_service.dart';
import '../../features/prompts/prompt_mood.dart';

/// Soft first-step choice from onboarding Screen 2.
abstract final class OnboardingIntent {
  static const sentence = 'sentence';
  static const detail = 'detail';
  static const photo = 'photo';
  static const voice = 'voice';
  static const lookAround = 'lookAround';
}

class AppState extends ChangeNotifier {
  AppState({
    required this.repository,
    required this.syncService,
    required this.biometricLock,
  });

  final AppRepository repository;
  final SyncService syncService;
  final BiometricLockService biometricLock;

  static const _keyUid = 'user_uid';
  static const _keyDisplayName = 'user_display_name';
  static const _keyEmail = 'user_email';
  static const _keyMemorialId = 'current_memorial_id';
  static const _keyOnboardingDone = 'onboarding_complete';
  static const _keyFirstSaveSuccessSeen = 'first_save_success_seen';
  static const _keyFirstSavePaywallOffered = 'first_save_paywall_offered';
  static const _keyPrivacyAccepted = 'privacy_accepted';
  static const _keyPaceAccepted = 'pace_promise_accepted';
  static const _keyOnboardingIntent = 'onboarding_intent';
  static const _keyHiddenCategories = 'hidden_prompt_categories';
  static const _keyRemindersPaused = 'reminders_paused';
  static const _keyReducedMotion = 'reduced_motion';
  static const _keyDismissedPrompt = 'dismissed_home_prompt_id';
  static const _keyDismissedPromptDay = 'dismissed_home_prompt_day';
  static const _keyPromptMood = 'prompt_mood';
  static const _keyAllowDifficultPrompts = 'allow_difficult_prompts';
  static const _keyPromptDismissHistory = 'prompt_dismiss_history';
  static const _keyReminderOptIn = 'reminder_opt_in_choice';
  static const _keyReminderShowName = 'reminder_show_loved_one_name';
  static const _keyReminderShowPhotos = 'reminder_show_photos';
  static const _keyReminderDefaultHour = 'reminder_default_hour';
  static const _keyReminderDefaultMinute = 'reminder_default_minute';
  static const _keyReminderSilencePermanent = 'reminder_silence_permanent';
  static const _keyMemoryQuestionCadence = 'memory_question_cadence';
  static const _keyMonthlyKeepsakePreview = 'monthly_keepsake_preview';
  static const _keyMemoryResurfacing = 'memory_resurfacing_mode';
  static const _keyLastKeepsakePreviewYm = 'last_keepsake_preview_ym';
  static const _keyLastMemoryQuestionKey = 'last_memory_question_key';
  static const _keyFamilyContributionWaiting = 'family_contribution_waiting';

  String? uid;
  String displayName = '';
  String? email;
  Memorial? currentMemorial;
  bool premium = false;
  /// True when access comes from an active free trial (not a paid plan).
  bool onPremiumTrial = false;
  /// True when access comes from a non-renewing gift year.
  bool onGiftPremium = false;
  /// End of the free trial, if one was started. Never shown as a home countdown.
  DateTime? premiumTrialEndsAt;
  /// End of gift Premium, if active. Never auto-renews.
  DateTime? giftPremiumExpiresAt;
  bool onboardingComplete = false;
  /// True after the one-time “Saved. That is enough for today.” screen.
  bool firstSaveSuccessSeen = false;
  /// True after we offered the trust paywall once after the first save.
  bool firstSavePaywallOffered = false;
  bool privacyAccepted = false;
  bool paceAccepted = false;
  String? onboardingIntent;
  bool remindersPaused = false;
  bool reducedMotion = false;
  Set<String> hiddenPromptCategories = {};
  String? dismissedHomePromptId;
  /// Local calendar day (`yyyy-MM-dd`) the home prompt was dismissed.
  String? dismissedHomePromptDay;
  /// promptId → ISO dismiss timestamp (Not Today cooldown).
  Map<String, String> promptDismissHistory = {};
  PromptMood promptMood = PromptMood.gentle;
  bool allowDifficultPrompts = false;
  ReminderOptInChoice reminderOptInChoice = ReminderOptInChoice.unset;
  bool reminderShowLovedOneName = false;
  bool reminderShowPhotos = false;
  int reminderDefaultHour = 10;
  int reminderDefaultMinute = 0;
  bool reminderSilencePermanent = false;
  MemoryQuestionCadence memoryQuestionCadence = MemoryQuestionCadence.off;
  bool monthlyKeepsakePreview = false;
  MemoryResurfacingMode memoryResurfacingMode = MemoryResurfacingMode.off;
  String? lastKeepsakePreviewYearMonth;
  String? lastMemoryQuestionKey;
  /// Family Circle: quiet flag when a contribution awaits review.
  bool familyContributionWaiting = false;
  bool initialized = false;
  /// Bumped whenever journal content changes so shell tabs can refresh.
  int contentEpoch = 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    uid = prefs.getString(_keyUid);
    displayName = prefs.getString(_keyDisplayName) ?? '';
    email = prefs.getString(_keyEmail);
    onboardingComplete = prefs.getBool(_keyOnboardingDone) ?? false;
    firstSaveSuccessSeen = prefs.getBool(_keyFirstSaveSuccessSeen) ?? false;
    firstSavePaywallOffered =
        prefs.getBool(_keyFirstSavePaywallOffered) ?? false;
    privacyAccepted = prefs.getBool(_keyPrivacyAccepted) ?? false;
    paceAccepted = prefs.getBool(_keyPaceAccepted) ?? false;
    onboardingIntent = prefs.getString(_keyOnboardingIntent);
    // Existing installs already past welcome should not be forced back.
    if (!privacyAccepted &&
        (onboardingComplete || uid != null || prefs.getString(_keyMemorialId) != null)) {
      privacyAccepted = true;
      paceAccepted = true;
      await prefs.setBool(_keyPrivacyAccepted, true);
      await prefs.setBool(_keyPaceAccepted, true);
    }
    remindersPaused = prefs.getBool(_keyRemindersPaused) ?? false;
    reducedMotion = prefs.getBool(_keyReducedMotion) ?? false;
    dismissedHomePromptId = prefs.getString(_keyDismissedPrompt);
    dismissedHomePromptDay = prefs.getString(_keyDismissedPromptDay);
    final moodName = prefs.getString(_keyPromptMood);
    promptMood = PromptMood.values.firstWhere(
      (m) => m.name == moodName,
      orElse: () => PromptMood.gentle,
    );
    allowDifficultPrompts =
        prefs.getBool(_keyAllowDifficultPrompts) ?? false;
    final dismissRaw = prefs.getString(_keyPromptDismissHistory);
    if (dismissRaw != null && dismissRaw.isNotEmpty) {
      final map = jsonDecode(dismissRaw) as Map<String, dynamic>;
      promptDismissHistory =
          map.map((k, v) => MapEntry(k, v.toString()));
    }
    final optInName = prefs.getString(_keyReminderOptIn);
    reminderOptInChoice = ReminderOptInChoice.values.firstWhere(
      (c) => c.name == optInName,
      orElse: () => ReminderOptInChoice.unset,
    );
    reminderShowLovedOneName =
        prefs.getBool(_keyReminderShowName) ?? false;
    reminderShowPhotos = prefs.getBool(_keyReminderShowPhotos) ?? false;
    reminderDefaultHour = prefs.getInt(_keyReminderDefaultHour) ?? 10;
    reminderDefaultMinute = prefs.getInt(_keyReminderDefaultMinute) ?? 0;
    reminderSilencePermanent =
        prefs.getBool(_keyReminderSilencePermanent) ?? false;
    memoryQuestionCadence = MemoryQuestionCadence.values.firstWhere(
      (c) => c.name == prefs.getString(_keyMemoryQuestionCadence),
      orElse: () => MemoryQuestionCadence.off,
    );
    monthlyKeepsakePreview =
        prefs.getBool(_keyMonthlyKeepsakePreview) ?? false;
    memoryResurfacingMode = MemoryResurfacingMode.values.firstWhere(
      (m) => m.name == prefs.getString(_keyMemoryResurfacing),
      orElse: () => MemoryResurfacingMode.off,
    );
    lastKeepsakePreviewYearMonth =
        prefs.getString(_keyLastKeepsakePreviewYm);
    lastMemoryQuestionKey = prefs.getString(_keyLastMemoryQuestionKey);
    familyContributionWaiting =
        prefs.getBool(_keyFamilyContributionWaiting) ?? false;
    final hiddenRaw = prefs.getString(_keyHiddenCategories);
    if (hiddenRaw != null && hiddenRaw.isNotEmpty) {
      final list = jsonDecode(hiddenRaw) as List<dynamic>;
      hiddenPromptCategories = list.map((e) => e.toString()).toSet();
    }
    // Prefer the live Firebase Auth uid when signed in.
    final firebaseUid = AuthService.instance.firebaseUid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      uid = firebaseUid;
      await prefs.setString(_keyUid, firebaseUid);
    }
    await _refreshPremiumState();
    final memorialId = prefs.getString(_keyMemorialId);
    if (memorialId != null) {
      currentMemorial = await repository.getMemorial(memorialId);
    }
    if (currentMemorial == null && uid != null) {
      final memorials = await repository.listMemorials(ownerUid: uid);
      if (memorials.isNotEmpty) {
        currentMemorial = memorials.first;
        await prefs.setString(_keyMemorialId, currentMemorial!.id);
      }
    }
    initialized = true;
    notifyListeners();

    // Registered accounts: pull cloud data, then push any pending local writes.
    if (AuthService.instance.currentUser != null) {
      // ignore: unawaited_futures
      syncService.syncNow(displayName: displayName, email: email).then((_) async {
        if (!initialized) {
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        if (currentMemorial == null && uid != null) {
          final memorials = await repository.listMemorials(ownerUid: uid);
          if (memorials.isNotEmpty) {
            currentMemorial = memorials.first;
            await prefs.setString(_keyMemorialId, currentMemorial!.id);
            notifyContentChanged();
          }
        } else {
          notifyContentChanged();
        }
      });
    }
  }

  Future<void> saveAccount({
    required String newUid,
    required String newDisplayName,
    String? newEmail,
  }) async {
    final previousUid = uid;
    uid = newUid;
    displayName = newDisplayName;
    email = newEmail;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, newUid);
    await prefs.setString(_keyDisplayName, newDisplayName);
    if (newEmail != null) {
      await prefs.setString(_keyEmail, newEmail);
    } else {
      await prefs.remove(_keyEmail);
    }
    if (previousUid != null &&
        previousUid != newUid &&
        previousUid.startsWith('local_')) {
      await repository.reassignOwnerUid(fromUid: previousUid, toUid: newUid);
      if (currentMemorial != null && currentMemorial!.ownerUid == previousUid) {
        currentMemorial = currentMemorial!.copyWith(ownerUid: newUid);
      }
      notifyContentChanged();
    }
    PrivacySafeAnalytics.instance.log('account_created');
    notifyListeners();
    // Registered accounts sync journal data to Firestore.
    // ignore: unawaited_futures
    syncService.syncNow(displayName: newDisplayName, email: newEmail);
  }

  /// True when the user has a Firebase/email account (not device-only).
  bool get hasCloudAccount {
    if (AuthService.instance.currentUser != null) {
      return true;
    }
    final id = uid;
    if (id == null || id.startsWith('local_')) {
      return false;
    }
    return email != null && email!.isNotEmpty;
  }

  /// Creates a device-local identity so writing works before email/password.
  Future<void> ensureLocalSession() async {
    if (uid != null && uid!.isNotEmpty) {
      return;
    }
    final localUid = 'local_${const Uuid().v4()}';
    uid = localUid;
    displayName = displayName;
    email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, localUid);
    notifyListeners();
  }

  Future<void> acceptPrivacy() async {
    privacyAccepted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPrivacyAccepted, true);
    await ensureLocalSession();
    notifyListeners();
  }

  Future<void> acceptPacePromise() async {
    paceAccepted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPaceAccepted, true);
    notifyListeners();
  }

  Future<void> setOnboardingIntent(String intent) async {
    onboardingIntent = intent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOnboardingIntent, intent);
    notifyListeners();
  }

  Future<void> syncCloud() => syncService.syncNow(
        displayName: displayName,
        email: email,
      );

  Future<void> setCurrentMemorial(Memorial memorial) async {
    currentMemorial = memorial;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMemorialId, memorial.id);
    notifyContentChanged();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
    PrivacySafeAnalytics.instance.log('onboarding_completed');
    notifyListeners();
  }

  Future<void> markFirstSaveSuccessSeen() async {
    firstSaveSuccessSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstSaveSuccessSeen, true);
    notifyListeners();
  }

  Future<void> markFirstSavePaywallOffered() async {
    firstSavePaywallOffered = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstSavePaywallOffered, true);
    notifyListeners();
  }

  /// After first save: offer trust paywall once if not already Premium.
  Future<bool> shouldOfferFirstSavePaywall() async {
    if (premium || firstSavePaywallOffered) {
      return false;
    }
    return true;
  }

  /// Whether this save should open the gentle first-save success screen.
  bool shouldShowFirstSaveSuccess({required bool isDraft}) {
    return !isDraft && !firstSaveSuccessSeen;
  }

  Future<void> refreshPremium() async {
    await _refreshPremiumState();
    notifyListeners();
  }

  Future<void> _refreshPremiumState() async {
    premium = await repository.isPremium();
    final subscribed = await repository.isSubscribed();
    onPremiumTrial = !subscribed && await repository.isTrialActive();
    premiumTrialEndsAt =
        onPremiumTrial ? await repository.trialEndsAt() : null;
    onGiftPremium = !subscribed && await repository.isGiftPremiumActive();
    giftPremiumExpiresAt =
        onGiftPremium ? await repository.giftPremiumExpiresAt() : null;
  }

  Future<void> setPremiumLocal(bool value) async {
    await repository.setPremium(value);
    await _refreshPremiumState();
    notifyListeners();
  }

  /// Starts the 14-day premium trial. Does not place a countdown on Home.
  Future<bool> startPremiumTrialLocal() async {
    final started = await repository.startPremiumTrial();
    await _refreshPremiumState();
    notifyListeners();
    return started;
  }

  /// Redeems a non-renewing one-year gift. Does not start an auto-renewing plan.
  Future<DateTime> redeemGiftCodeLocal(String code) async {
    final expires = await repository.redeemGiftCode(code);
    await _refreshPremiumState();
    notifyListeners();
    return expires;
  }

  Future<IssuedGiftCode> purchaseGiftLocal() async {
    final issued = await repository.purchaseGiftLocal();
    notifyListeners();
    return issued;
  }

  Future<void> setHiddenPromptCategories(Set<String> categories) async {
    hiddenPromptCategories = categories;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHiddenCategories, jsonEncode(categories.toList()));
    notifyListeners();
  }

  Future<void> setRemindersPaused(bool value) async {
    remindersPaused = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemindersPaused, value);
    notifyListeners();
  }

  Future<void> setPromptMood(PromptMood mood) async {
    promptMood = mood;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPromptMood, mood.name);
    notifyListeners();
  }

  Future<void> setAllowDifficultPrompts(bool value) async {
    allowDifficultPrompts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAllowDifficultPrompts, value);
    notifyListeners();
  }

  Future<void> dismissHomePrompt(String promptId) async {
    dismissedHomePromptId = promptId;
    dismissedHomePromptDay = _localDayKey(DateTime.now());
    promptDismissHistory[promptId] = DateTime.now().toUtc().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDismissedPrompt, promptId);
    await prefs.setString(_keyDismissedPromptDay, dismissedHomePromptDay!);
    await prefs.setString(
      _keyPromptDismissHistory,
      jsonEncode(promptDismissHistory),
    );
    notifyListeners();
  }

  bool isHomePromptDismissedToday(String promptId, {DateTime? now}) {
    final day = _localDayKey(now ?? DateTime.now());
    return dismissedHomePromptId == promptId && dismissedHomePromptDay == day;
  }

  bool isPromptOnDismissCooldown(String promptId, {DateTime? now}) {
    final raw = promptDismissHistory[promptId];
    if (raw == null) {
      return false;
    }
    final dismissedAt = DateTime.tryParse(raw);
    if (dismissedAt == null) {
      return false;
    }
    final end = dismissedAt.add(const Duration(days: promptDismissCooldownDays));
    return (now ?? DateTime.now()).isBefore(end);
  }

  bool get shouldOfferReminderOptIn =>
      !reminderSilencePermanent &&
      (reminderOptInChoice == ReminderOptInChoice.unset ||
          reminderOptInChoice == ReminderOptInChoice.askMeLater);

  bool get remindersWanted =>
      !reminderSilencePermanent &&
      !remindersPaused &&
      reminderOptInChoice == ReminderOptInChoice.remindMe;

  Future<void> setReminderOptInChoice(ReminderOptInChoice choice) async {
    reminderOptInChoice = choice;
    if (choice == ReminderOptInChoice.returnOnMyOwn) {
      remindersPaused = true;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminderOptIn, choice.name);
    if (choice == ReminderOptInChoice.returnOnMyOwn) {
      await prefs.setBool(_keyRemindersPaused, true);
    }
    notifyListeners();
  }

  Future<void> setReminderPrivacy({
    bool? showLovedOneName,
    bool? showPhotos,
  }) async {
    if (showLovedOneName != null) {
      reminderShowLovedOneName = showLovedOneName;
    }
    if (showPhotos != null) {
      reminderShowPhotos = showPhotos;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderShowName, reminderShowLovedOneName);
    await prefs.setBool(_keyReminderShowPhotos, reminderShowPhotos);
    notifyListeners();
  }

  Future<void> setReminderDefaultTime({
    required int hour,
    required int minute,
  }) async {
    reminderDefaultHour = hour.clamp(0, 23);
    reminderDefaultMinute = minute.clamp(0, 59);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderDefaultHour, reminderDefaultHour);
    await prefs.setInt(_keyReminderDefaultMinute, reminderDefaultMinute);
    notifyListeners();
  }

  Future<void> setReminderSilencePermanent(bool value) async {
    reminderSilencePermanent = value;
    if (value) {
      remindersPaused = true;
      reminderOptInChoice = ReminderOptInChoice.returnOnMyOwn;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderSilencePermanent, value);
    await prefs.setBool(_keyRemindersPaused, remindersPaused);
    await prefs.setString(_keyReminderOptIn, reminderOptInChoice.name);
    notifyListeners();
  }

  Future<void> setMemoryQuestionCadence(MemoryQuestionCadence cadence) async {
    memoryQuestionCadence = cadence;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMemoryQuestionCadence, cadence.name);
    notifyListeners();
  }

  Future<void> setMonthlyKeepsakePreview(bool value) async {
    monthlyKeepsakePreview = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMonthlyKeepsakePreview, value);
    notifyListeners();
  }

  Future<void> setMemoryResurfacingMode(MemoryResurfacingMode mode) async {
    memoryResurfacingMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMemoryResurfacing, mode.name);
    notifyListeners();
  }

  Future<void> markMemoryQuestionShown(String periodKey) async {
    lastMemoryQuestionKey = periodKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastMemoryQuestionKey, periodKey);
    notifyListeners();
  }

  Future<void> markKeepsakePreviewShown(String yearMonth) async {
    lastKeepsakePreviewYearMonth = yearMonth;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastKeepsakePreviewYm, yearMonth);
    notifyListeners();
  }

  /// Family Circle: set when a contribution awaits owner review.
  Future<void> setFamilyContributionWaiting(bool value) async {
    familyContributionWaiting = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFamilyContributionWaiting, value);
    notifyListeners();
  }

  Future<void> setReducedMotion(bool value) async {
    reducedMotion = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReducedMotion, value);
    notifyListeners();
  }

  static String _localDayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Call after creating/updating/deleting entries so Home and tab lists reload.
  void notifyContentChanged() {
    contentEpoch++;
    notifyListeners();
  }

  Future<void> wipeSession() async {
    uid = null;
    displayName = '';
    email = null;
    currentMemorial = null;
    onboardingComplete = false;
    firstSaveSuccessSeen = false;
    firstSavePaywallOffered = false;
    privacyAccepted = false;
    paceAccepted = false;
    onboardingIntent = null;
    premium = false;
    onPremiumTrial = false;
    onGiftPremium = false;
    premiumTrialEndsAt = null;
    giftPremiumExpiresAt = null;
    await repository.setPremium(false);
    await repository.clearPremiumTrial();
    await repository.clearGiftPremium();
    await AuthService.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyMemorialId);
    await prefs.remove(_keyOnboardingIntent);
    await prefs.setBool(_keyOnboardingDone, false);
    await prefs.setBool(_keyFirstSaveSuccessSeen, false);
    await prefs.setBool(_keyFirstSavePaywallOffered, false);
    await prefs.setBool(_keyPrivacyAccepted, false);
    await prefs.setBool(_keyPaceAccepted, false);
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    required super.notifier,
    required super.child,
    super.key,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
