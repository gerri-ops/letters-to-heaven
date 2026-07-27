import 'package:flutter/foundation.dart';

import '../../data/models/models.dart';
import '../../data/repositories/app_repository.dart';
import '../firebase/auth_service.dart';
import '../firebase/firebase_bootstrap.dart';
import '../firebase/firestore_client.dart';
import '../media/cloud_media_uploader.dart';
import '../media/local_file_io.dart'
    if (dart.library.html) '../media/local_file_web.dart' as io;
import '../media/media_policy.dart';
import '../reviews/review_request_copy.dart';
import '../reviews/review_request_service.dart';

/// Pushes local changes to Firestore/Storage and pulls remote data for
/// signed-in accounts.
class SyncService {
  SyncService(this._repository);

  final AppRepository _repository;
  final _firestore = FirestoreClient.instance;

  Future<void> enqueueEntry(Entry entry) async {
    await _repository.upsertEntry(
      entry.copyWith(syncState: SyncState.pendingUpload),
    );
  }

  bool get _canSyncServer =>
      FirebaseBootstrap.isReady && AuthService.instance.currentUser != null;

  /// Full sync for registered accounts: pull remote → push pending → media.
  Future<void> syncNow({String? displayName, String? email}) async {
    if (!_canSyncServer) {
      return;
    }
    if (!(await _repository.isPremium())) {
      return;
    }
    final uid = AuthService.instance.firebaseUid!;
    try {
      await _firestore.upsertUserProfile(
        uid: uid,
        displayName: displayName?.isNotEmpty == true
            ? displayName!
            : (email?.split('@').first ?? 'Member'),
        email: email,
      );
      await pullRemote(ownerUid: uid);
      await flushPendingUploads();
    } catch (e, st) {
      debugPrint('Sync failed: $e\n$st');
    }
  }

  Future<void> flushPendingUploads() async {
    await _repository.flushSyncQueue();

    if (_canSyncServer) {
      await _pushPendingDocuments();
    }

    if (!MediaPolicy.instance.cloudStorageEnabled) {
      return;
    }
    if (!_canSyncServer) {
      return;
    }
    if (!(await _repository.isPremium())) {
      return;
    }

    final pending = await _repository.listPendingMediaUploads();
    var uploaded = 0;
    for (final media in pending) {
      try {
        if (!await io.fileExists(media.localPath)) {
          await _repository.upsertMedia(
            media.copyWith(syncState: SyncState.localOnly),
            forceState: true,
          );
          continue;
        }
        final remotePath = await CloudMediaUploader.instance.upload(media);
        await _repository.upsertMedia(
          media.copyWith(
            remotePath: remotePath,
            syncState: SyncState.synced,
            ownerUid: AuthService.instance.firebaseUid ?? media.ownerUid,
          ),
          forceState: true,
        );
        uploaded++;
      } catch (e) {
        debugPrint('Media upload failed for ${media.id}: $e');
        await _repository.upsertMedia(
          media.copyWith(syncState: SyncState.pendingUpload),
          forceState: true,
        );
      }
    }
    if (uploaded > 0) {
      await ReviewRequestService.instance.queueTrigger(
        ReviewTrigger.backupCompleted,
      );
    }
  }

  Future<void> _pushPendingDocuments() async {
    final uid = AuthService.instance.firebaseUid!;

    final memorials = await _repository.listPendingMemorialUploads();
    for (final memorial in memorials) {
      try {
        final data = memorial.toJson()
          ..['ownerUid'] = uid
          ..['syncState'] = SyncState.synced.name;
        await _firestore.upsertDocument(
          collectionPath: 'users/$uid/memorials',
          documentId: memorial.id,
          data: data,
        );
        await _repository.markMemorialSynced(memorial.id);
      } catch (e) {
        debugPrint('Memorial sync failed for ${memorial.id}: $e');
      }
    }

    final entries = await _repository.listPendingEntryUploads();
    for (final entry in entries) {
      try {
        final data = entry.toJson()
          ..['ownerUid'] = uid
          ..['syncState'] = SyncState.synced.name;
        await _firestore.upsertDocument(
          collectionPath: 'users/$uid/entries',
          documentId: entry.id,
          data: data,
        );
        await _repository.markEntrySynced(entry.id);
      } catch (e) {
        debugPrint('Entry sync failed for ${entry.id}: $e');
      }
    }

    final dates = await _repository.listPendingRemembranceUploads();
    for (final date in dates) {
      try {
        final data = date.toJson()
          ..['ownerUid'] = uid
          ..['syncState'] = SyncState.synced.name;
        await _firestore.upsertDocument(
          collectionPath: 'users/$uid/remembranceDates',
          documentId: date.id,
          data: data,
        );
        await _repository.markRemembranceSynced(date.id);
      } catch (e) {
        debugPrint('Remembrance sync failed for ${date.id}: $e');
      }
    }
  }

  Future<void> pullRemote({required String ownerUid}) async {
    if (!_canSyncServer) {
      return;
    }
    final uid = AuthService.instance.firebaseUid ?? ownerUid;

    try {
      final remoteMemorials = await _firestore.listDocuments(
        collectionPath: 'users/$uid/memorials',
      );
      for (final raw in remoteMemorials) {
        try {
          final remote = Memorial.fromJson({
            ...raw,
            'syncState': SyncState.synced.name,
          });
          final local = await _repository.getMemorial(remote.id);
          if (_shouldApplyRemote(
            localUpdated: local?.updatedAt,
            remoteUpdated: remote.updatedAt,
          )) {
            await _repository.upsertMemorialRemote(remote);
          }
        } catch (e) {
          debugPrint('Skip remote memorial: $e');
        }
      }

      final remoteEntries = await _firestore.listDocuments(
        collectionPath: 'users/$uid/entries',
      );
      for (final raw in remoteEntries) {
        try {
          final remote = Entry.fromJson({
            ...raw,
            'syncState': SyncState.synced.name,
          });
          final local = await _repository.getEntryById(remote.id);
          if (_shouldApplyRemote(
            localUpdated: local?.updatedAt,
            remoteUpdated: remote.updatedAt,
            localPending: local?.syncState == SyncState.pendingUpload,
          )) {
            await _repository.upsertEntry(remote, forceState: true);
          }
        } catch (e) {
          debugPrint('Skip remote entry: $e');
        }
      }

      final remoteDates = await _firestore.listDocuments(
        collectionPath: 'users/$uid/remembranceDates',
      );
      for (final raw in remoteDates) {
        try {
          final remote = RemembranceDate.fromJson({
            ...raw,
            'syncState': SyncState.synced.name,
          });
          await _repository.upsertRemembranceDate(remote, forceState: true);
        } catch (e) {
          debugPrint('Skip remote remembrance: $e');
        }
      }
    } catch (e, st) {
      debugPrint('Pull remote failed: $e\n$st');
    }
  }

  bool _shouldApplyRemote({
    required DateTime? localUpdated,
    required DateTime? remoteUpdated,
    bool localPending = false,
  }) {
    if (localPending) {
      return false;
    }
    if (localUpdated == null) {
      return true;
    }
    if (remoteUpdated == null) {
      return false;
    }
    return !remoteUpdated.isBefore(localUpdated);
  }

  List<Entry> pendingEntries() => _repository.peekSyncQueue();
}
