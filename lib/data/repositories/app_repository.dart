import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../models/models.dart';
import '../../core/billing/gift_premium_plan.dart';
import '../../core/billing/plan_entitlements.dart';
import '../../core/billing/premium_pricing.dart';
import '../../core/media/media_policy.dart';
import '../../core/media/media_upload_limits.dart';

class EntryLimitExceeded implements Exception {
  EntryLimitExceeded(this.limit);

  final int limit;

  @override
  String toString() =>
      'Basic includes up to $limit saved entries. Premium has no limit.';
}

class MemorialLimitExceeded implements Exception {
  MemorialLimitExceeded(this.limit);

  final int limit;

  @override
  String toString() =>
      'Make a separate private place for each person or pet you want to remember. '
      'Basic includes $limit memorial; Premium unlocks more.';
}

class PhotoLimitExceeded implements Exception {
  PhotoLimitExceeded(this.limit);

  final int limit;

  @override
  String toString() =>
      'Basic includes $limit photo per entry. Premium unlocks unlimited photos.';
}

class GiftRedeemException implements Exception {
  GiftRedeemException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Issued gift purchase (local until store IAP validates the product).
class IssuedGiftCode {
  const IssuedGiftCode({
    required this.code,
    required this.createdAt,
  });

  final String code;
  final DateTime createdAt;
}

/// Application data access with local persistence and cloud sync hooks.
class AppRepository {
  AppRepository({AppDatabase? database})
      : _database = database ?? AppDatabase();

  /// Basic saved-entry cap; Premium is unlimited.
  static const int freeTierEntryLimit = PlanEntitlements.basicEntryLimit;

  /// Prefer [PremiumPricing.annualPriceUsd]; kept for older call sites.
  static const double annualPremiumPriceUsd = PremiumPricing.annualPriceUsd;

  final AppDatabase _database;
  final List<Entry> _syncQueue = [];

  AppDatabase get database => _database;

  /// Paid subscription flag only (excludes trial).
  Future<bool> isSubscribed() => _database.getPremiumFlag();

  /// Effective premium access: paid plan, active free trial, or active gift year.
  Future<bool> isPremium({DateTime? now}) async {
    if (await isSubscribed()) {
      return true;
    }
    if (await isTrialActive(now: now)) {
      return true;
    }
    return isGiftPremiumActive(now: now);
  }

  Future<void> setPremium(bool value) => _database.setPremiumFlag(value);

  Future<DateTime?> getPremiumTrialStartedAt() =>
      _database.getPremiumTrialStartedAt();

  Future<bool> isTrialActive({DateTime? now}) async {
    final started = await getPremiumTrialStartedAt();
    if (started == null) {
      return false;
    }
    final end = started.add(const Duration(days: PremiumPricing.freeTrialDays));
    return (now ?? DateTime.now()).isBefore(end);
  }

  Future<DateTime?> trialEndsAt() async {
    final started = await getPremiumTrialStartedAt();
    if (started == null) {
      return null;
    }
    return started.add(const Duration(days: PremiumPricing.freeTrialDays));
  }

  /// Starts a one-time local premium trial if none has been used.
  Future<bool> startPremiumTrial({DateTime? now}) async {
    final existing = await getPremiumTrialStartedAt();
    if (existing != null) {
      return isTrialActive(now: now);
    }
    await _database.setPremiumTrialStartedAt(now ?? DateTime.now());
    return true;
  }

  Future<void> clearPremiumTrial() =>
      _database.setPremiumTrialStartedAt(null);

  /// Active non-renewing gift year (never sets the auto-renewing paid flag).
  Future<bool> isGiftPremiumActive({DateTime? now}) async {
    final expires = await giftPremiumExpiresAt();
    if (expires == null) {
      return false;
    }
    return expires.isAfter(now ?? DateTime.now());
  }

  Future<DateTime?> giftPremiumExpiresAt() =>
      _database.getGiftPremiumExpiresAt();

  /// Purchases a local gift code for sharing. Store IAP will replace this stub.
  /// The gift never auto-renews ([GiftPremiumPlan.autoRenews] is false).
  Future<IssuedGiftCode> purchaseGiftLocal({DateTime? now}) async {
    assert(!GiftPremiumPlan.autoRenews);
    final createdAt = now ?? DateTime.now();
    final token = const Uuid().v4().replaceAll('-', '').substring(0, 8).toUpperCase();
    final code = 'LTH-GIFT-$token';
    await _database.addIssuedGiftCode(code);
    return IssuedGiftCode(code: code, createdAt: createdAt);
  }

  /// Redeems a gift code for [GiftPremiumPlan.durationDays] of Premium.
  /// Does not enable auto-renewing subscription.
  Future<DateTime> redeemGiftCode(String rawCode, {DateTime? now}) async {
    assert(!GiftPremiumPlan.autoRenews);
    final code = rawCode.trim().toUpperCase();
    if (!_looksLikeGiftCode(code)) {
      throw GiftRedeemException(
        'That does not look like a Letters to Heaven gift code.',
      );
    }
    final redeemed = await _database.getGiftCodesRedeemed();
    if (redeemed.contains(code)) {
      throw GiftRedeemException('This gift code was already redeemed here.');
    }
    final start = now ?? DateTime.now();
    final existing = await giftPremiumExpiresAt();
    // Stack remaining gift time if still active; never renew automatically.
    final base = (existing != null && existing.isAfter(start)) ? existing : start;
    final expires = base.add(const Duration(days: GiftPremiumPlan.durationDays));
    await _database.setGiftPremiumExpiresAt(expires);
    await _database.addRedeemedGiftCode(code);
    return expires;
  }

  Future<void> clearGiftPremium() => _database.clearGiftPremium();

  bool _looksLikeGiftCode(String code) {
    final normalized = code.replaceAll(' ', '');
    return RegExp(r'^LTH-GIFT-[A-Z0-9]{6,12}$').hasMatch(normalized);
  }

  Future<Memorial> createMemorial({
    required String id,
    required String ownerUid,
    required String displayName,
    String? relationship,
    DateTime? birthDate,
    DateTime? passingDate,
    String? photoUrl,
    String? notes,
  }) async {
    final premium = await isPremium();
    final existing = await listMemorials(ownerUid: ownerUid);
    if (!PlanEntitlements.canCreateMemorial(
      premium: premium,
      existingMemorialCount: existing.length,
    )) {
      throw MemorialLimitExceeded(PlanEntitlements.basicMemorialLimit);
    }
    final now = DateTime.now();
    final memorial = Memorial(
      id: id,
      ownerUid: ownerUid,
      displayName: displayName,
      relationship: relationship,
      birthDate: birthDate,
      passingDate: passingDate,
      photoUrl: photoUrl,
      notes: notes,
      createdAt: now,
      updatedAt: now,
      syncState: SyncState.pendingUpload,
    );
    await _database.insertMemorial(memorial);
    return memorial;
  }

  Future<Memorial?> getMemorial(String id) => _database.getMemorialById(id);

  Future<void> updateMemorial(
    Memorial memorial, {
    bool forceState = false,
  }) async {
    final updated = forceState
        ? memorial
        : memorial.copyWith(
            updatedAt: DateTime.now(),
            syncState: SyncState.pendingUpload,
          );
    await _database.updateMemorial(updated);
  }

  Future<void> upsertMemorialRemote(Memorial memorial) =>
      _database.insertMemorial(memorial);

  Future<Entry?> getEntryById(String id) => _database.getEntryById(id);

  Future<List<RemembranceDate>> listRemembranceDates(String memorialId) =>
      _database.listRemembranceDates(memorialId: memorialId);

  Future<RemembranceDate> upsertRemembranceDate(
    RemembranceDate date, {
    bool forceState = false,
  }) async {
    final toSave = forceState
        ? date
        : date.copyWith(syncState: SyncState.pendingUpload);
    await _database.upsertRemembranceDate(toSave);
    return toSave;
  }

  Future<void> wipeLocalData() => _database.wipeAllUserData();

  Future<void> reassignOwnerUid({
    required String fromUid,
    required String toUid,
  }) =>
      _database.reassignOwnerUid(fromUid: fromUid, toUid: toUid);

  Future<MediaAttachment> upsertMedia(
    MediaAttachment media, {
    bool forceState = false,
  }) async {
    final premium = await isPremium();
    final MediaAttachment toSave;
    if (forceState) {
      toSave = media;
    } else if (premium &&
        MediaPolicy.instance.cloudStorageEnabled &&
        media.mimeType != null &&
        media.mimeType!.startsWith('image/')) {
      toSave = media.copyWith(
        syncState: SyncState.pendingUpload,
        mimeType: MediaUploadLimits.webpMimeType,
        fileName: _webpFileName(media.fileName),
      );
    } else if (premium && MediaPolicy.instance.cloudStorageEnabled) {
      toSave = media.copyWith(syncState: SyncState.pendingUpload);
    } else {
      toSave = media.copyWith(
        syncState: SyncState.localOnly,
        remotePath: null,
      );
    }
    await _database.upsertMedia(toSave);
    return toSave;
  }

  String _webpFileName(String? name) {
    if (name == null || name.isEmpty) {
      return 'photo.webp';
    }
    final base = name.replaceAll(RegExp(r'\.[^.]+$'), '');
    return '$base.webp';
  }

  Future<List<MediaAttachment>> listMediaForEntry(String entryId) =>
      _database.listMediaForEntry(entryId);

  Future<List<MediaAttachment>> listPendingMediaUploads() =>
      _database.listPendingMediaUploads();

  Future<List<Memorial>> listPendingMemorialUploads() =>
      _database.listPendingMemorialUploads();

  Future<List<Entry>> listPendingEntryUploads() =>
      _database.listPendingEntryUploads();

  Future<List<RemembranceDate>> listPendingRemembranceUploads() =>
      _database.listPendingRemembranceUploads();

  Future<void> markMemorialSynced(String id) =>
      _database.markMemorialSynced(id);

  Future<void> markEntrySynced(String id) => _database.markEntrySynced(id);

  Future<void> markRemembranceSynced(String id) =>
      _database.markRemembranceSynced(id);

  Future<int> queueLocalMediaForCloudBackup() =>
      _database.markLocalMediaPendingUpload();

  Future<void> deleteMedia(String mediaId) => _database.deleteMedia(mediaId);

  Future<List<Memorial>> listMemorials({String? ownerUid}) =>
      _database.listMemorials(ownerUid: ownerUid);

  Future<Entry> upsertEntry(Entry entry, {bool forceState = false}) async {
    if (!forceState) {
      await _enforceBasicEntryLimit(entry);
    }
    final now = DateTime.now();
    final premium = forceState ? true : await isPremium();
    final toSave = forceState
        ? entry
        : entry.copyWith(
            updatedAt: now,
            createdAt: entry.createdAt ?? now,
            syncState: premium ? SyncState.pendingUpload : SyncState.localOnly,
          );
    await _database.upsertEntry(toSave);
    if (!forceState && premium) {
      _enqueueSync(toSave);
    }
    return toSave;
  }

  Future<void> _enforceBasicEntryLimit(Entry entry) async {
    if (await isPremium()) {
      return;
    }
    if (entry.status != EntryStatus.saved) {
      return;
    }
    final existing = await _database.getEntryById(entry.id);
    if (existing != null && existing.status == EntryStatus.saved) {
      return;
    }
    final count = await _database.countSavedEntries(memorialId: entry.memorialId);
    if (count >= PlanEntitlements.basicEntryLimit) {
      throw EntryLimitExceeded(PlanEntitlements.basicEntryLimit);
    }
  }

  Future<List<Entry>> listEntries({
    required String memorialId,
    bool includeDeleted = false,
    bool includeArchived = true,
  }) =>
      _database.listEntries(
        memorialId: memorialId,
        includeDeleted: includeDeleted,
        includeArchived: includeArchived,
      );

  Future<List<Entry>> searchEntries({
    required String query,
    String? memorialId,
  }) =>
      _database.searchEntries(query: query, memorialId: memorialId);

  Future<void> softDelete(String entryId) async {
    final deletedAt = DateTime.now();
    await _database.softDeleteEntry(entryId, deletedAt);
    final entry = await _database.getEntryById(entryId);
    if (entry != null) {
      _enqueueSync(entry);
    }
  }

  Future<void> archive(String entryId) async {
    await _database.archiveEntry(entryId);
    final entry = await _database.getEntryById(entryId);
    if (entry != null) {
      _enqueueSync(entry);
    }
  }

  Future<void> toggleFavorite(String entryId) async {
    final entry = await _database.getEntryById(entryId);
    if (entry == null) {
      return;
    }
    await _database.toggleFavorite(entryId, !entry.isFavorite);
    final updated = await _database.getEntryById(entryId);
    if (updated != null) {
      _enqueueSync(updated);
    }
  }

  List<Entry> peekSyncQueue() => List.unmodifiable(_syncQueue);

  /// Kept for compatibility; real push is handled by [SyncService].
  Future<void> flushSyncQueue() async {
    _syncQueue.clear();
  }

  Future<void> pullRemoteChanges({required String ownerUid}) async {
    // Implemented in SyncService via FirestoreClient.
  }

  void _enqueueSync(Object entity) {
    if (entity is Entry) {
      _syncQueue.removeWhere((e) => e.id == entity.id);
      _syncQueue.add(entity);
    }
  }
}
