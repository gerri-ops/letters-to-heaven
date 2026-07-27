import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// Local SQLite persistence for offline-first use.
///
/// Production builds should use [SQLCipher](https://www.zetetic.net/sqlcipher/)
/// (e.g. `sqflite_sqlcipher`) instead of plain sqflite and derive the key from
/// secure storage. The [settings] table stores `db_encrypt_passphrase` as a
/// development placeholder only.
class AppDatabase {
  AppDatabase({this.dbName = 'letters_to_heaven.db'});

  final String dbName;
  Database? _db;

  static const int _schemaVersion = 4;

  static const String settingsKeyPremium = 'is_premium';
  static const String settingsKeyPremiumTrialStartedAt =
      'premium_trial_started_at';
  static const String settingsKeyGiftPremiumExpiresAt =
      'gift_premium_expires_at';
  static const String settingsKeyGiftCodesIssued = 'gift_codes_issued';
  static const String settingsKeyGiftCodesRedeemed = 'gift_codes_redeemed';
  static const String settingsKeyEncryptPassphrase = 'db_encrypt_passphrase';

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) {
      return existing;
    }
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);
    return openDatabase(
      path,
      version: _schemaVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE memorials (
        id TEXT PRIMARY KEY,
        owner_uid TEXT NOT NULL,
        display_name TEXT NOT NULL,
        relationship TEXT,
        birth_date TEXT,
        passing_date TEXT,
        photo_url TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'localOnly'
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        memorial_id TEXT NOT NULL,
        owner_uid TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        status TEXT NOT NULL,
        privacy TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        prompt_id TEXT,
        tags TEXT,
        media_ids TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT,
        entry_date TEXT,
        hidden_from_export INTEGER NOT NULL DEFAULT 0,
        hidden_from_home INTEGER NOT NULL DEFAULT 0,
        private_return_date TEXT,
        extension_json TEXT,
        sync_state TEXT NOT NULL DEFAULT 'localOnly',
        FOREIGN KEY (memorial_id) REFERENCES memorials(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_entries_memorial ON entries(memorial_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_entries_search ON entries(title, body)
    ''');

    await db.execute('''
      CREATE TABLE media (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        owner_uid TEXT NOT NULL,
        local_path TEXT NOT NULL,
        remote_path TEXT,
        mime_type TEXT,
        file_name TEXT,
        bytes INTEGER,
        created_at TEXT,
        sync_state TEXT NOT NULL DEFAULT 'localOnly',
        FOREIGN KEY (entry_id) REFERENCES entries(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE remembrance_dates (
        id TEXT PRIMARY KEY,
        memorial_id TEXT NOT NULL,
        owner_uid TEXT NOT NULL,
        label TEXT NOT NULL,
        date TEXT NOT NULL,
        recurring INTEGER NOT NULL DEFAULT 1,
        notify_enabled INTEGER NOT NULL DEFAULT 0,
        notify_hour INTEGER NOT NULL DEFAULT 10,
        notify_minute INTEGER NOT NULL DEFAULT 0,
        show_loved_one_name INTEGER NOT NULL DEFAULT 0,
        show_photos INTEGER NOT NULL DEFAULT 0,
        pause_until TEXT,
        sync_state TEXT NOT NULL DEFAULT 'localOnly',
        FOREIGN KEY (memorial_id) REFERENCES memorials(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.insert('settings', {
      'key': settingsKeyEncryptPassphrase,
      'value': '',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE entries ADD COLUMN entry_date TEXT',
      );
      await db.execute(
        'ALTER TABLE entries ADD COLUMN hidden_from_export INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE entries ADD COLUMN extension_json TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE remembrance_dates ADD COLUMN notify_hour INTEGER NOT NULL DEFAULT 10',
      );
      await db.execute(
        'ALTER TABLE remembrance_dates ADD COLUMN notify_minute INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE remembrance_dates ADD COLUMN show_loved_one_name INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE remembrance_dates ADD COLUMN show_photos INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE remembrance_dates ADD COLUMN pause_until TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE entries ADD COLUMN hidden_from_home INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE entries ADD COLUMN private_return_date TEXT',
      );
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getPremiumFlag() async {
    final value = await getSetting(settingsKeyPremium);
    return value == 'true';
  }

  Future<void> setPremiumFlag(bool isPremium) async {
    await setSetting(settingsKeyPremium, isPremium.toString());
  }

  Future<DateTime?> getPremiumTrialStartedAt() async {
    final raw = await getSetting(settingsKeyPremiumTrialStartedAt);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> setPremiumTrialStartedAt(DateTime? startedAt) async {
    if (startedAt == null) {
      final db = await database;
      await db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: [settingsKeyPremiumTrialStartedAt],
      );
      return;
    }
    await setSetting(
      settingsKeyPremiumTrialStartedAt,
      startedAt.toUtc().toIso8601String(),
    );
  }

  Future<DateTime?> getGiftPremiumExpiresAt() async {
    final raw = await getSetting(settingsKeyGiftPremiumExpiresAt);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> setGiftPremiumExpiresAt(DateTime? expiresAt) async {
    if (expiresAt == null) {
      final db = await database;
      await db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: [settingsKeyGiftPremiumExpiresAt],
      );
      return;
    }
    await setSetting(
      settingsKeyGiftPremiumExpiresAt,
      expiresAt.toUtc().toIso8601String(),
    );
  }

  Future<List<String>> getGiftCodesIssued() async {
    final raw = await getSetting(settingsKeyGiftCodesIssued);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> addIssuedGiftCode(String code) async {
    final codes = await getGiftCodesIssued();
    if (!codes.contains(code)) {
      codes.add(code);
      await setSetting(settingsKeyGiftCodesIssued, jsonEncode(codes));
    }
  }

  Future<List<String>> getGiftCodesRedeemed() async {
    final raw = await getSetting(settingsKeyGiftCodesRedeemed);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> addRedeemedGiftCode(String code) async {
    final codes = await getGiftCodesRedeemed();
    if (!codes.contains(code)) {
      codes.add(code);
      await setSetting(settingsKeyGiftCodesRedeemed, jsonEncode(codes));
    }
  }

  Future<void> clearGiftPremium() async {
    await setGiftPremiumExpiresAt(null);
  }

  Future<void> insertMemorial(Memorial memorial) async {
    final db = await database;
    await db.insert(
      'memorials',
      _memorialToRow(memorial),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMemorial(Memorial memorial) async {
    final db = await database;
    await db.update(
      'memorials',
      _memorialToRow(memorial),
      where: 'id = ?',
      whereArgs: [memorial.id],
    );
  }

  Future<Memorial?> getMemorialById(String id) async {
    final db = await database;
    final rows = await db.query(
      'memorials',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _memorialFromRow(rows.first);
  }

  Future<List<Memorial>> listMemorials({String? ownerUid}) async {
    final db = await database;
    final rows = ownerUid == null
        ? await db.query('memorials', orderBy: 'display_name COLLATE NOCASE')
        : await db.query(
            'memorials',
            where: 'owner_uid = ?',
            whereArgs: [ownerUid],
            orderBy: 'display_name COLLATE NOCASE',
          );
    return rows.map(_memorialFromRow).toList();
  }

  Future<List<Memorial>> listPendingMemorialUploads() async {
    final db = await database;
    final rows = await db.query(
      'memorials',
      where: 'sync_state = ?',
      whereArgs: [SyncState.pendingUpload.name],
    );
    return rows.map(_memorialFromRow).toList();
  }

  Future<List<Entry>> listPendingEntryUploads() async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'sync_state = ?',
      whereArgs: [SyncState.pendingUpload.name],
      orderBy: 'updated_at ASC',
    );
    return rows.map(_entryFromRow).toList();
  }

  Future<List<RemembranceDate>> listPendingRemembranceUploads() async {
    final db = await database;
    final rows = await db.query(
      'remembrance_dates',
      where: 'sync_state = ?',
      whereArgs: [SyncState.pendingUpload.name],
    );
    return rows.map(_remembranceFromRow).toList();
  }

  Future<void> markMemorialSynced(String id) async {
    final db = await database;
    await db.update(
      'memorials',
      {'sync_state': SyncState.synced.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markEntrySynced(String id) async {
    final db = await database;
    await db.update(
      'entries',
      {'sync_state': SyncState.synced.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markRemembranceSynced(String id) async {
    final db = await database;
    await db.update(
      'remembrance_dates',
      {'sync_state': SyncState.synced.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> upsertEntry(Entry entry) async {
    final db = await database;
    await db.insert(
      'entries',
      _entryToRow(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Entry?> getEntryById(String id) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _entryFromRow(rows.first);
  }

  Future<List<Entry>> listEntries({
    required String memorialId,
    bool includeDeleted = false,
    bool includeArchived = true,
  }) async {
    final db = await database;
    final where = <String>['memorial_id = ?'];
    final args = <Object?>[memorialId];

    if (!includeDeleted) {
      where.add('deleted_at IS NULL');
    }
    if (!includeArchived) {
      where.add("status != 'archived'");
    }

    final rows = await db.query(
      'entries',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC, created_at DESC',
    );
    return rows.map(_entryFromRow).toList();
  }

  Future<int> countActiveEntries({String? memorialId}) async {
    final db = await database;
    if (memorialId != null) {
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) AS c FROM entries
        WHERE memorial_id = ? AND deleted_at IS NULL
        ''',
        [memorialId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS c FROM entries WHERE deleted_at IS NULL
      ''',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Entry>> searchEntries({
    required String query,
    String? memorialId,
  }) async {
    final db = await database;
    final pattern = '%${query.replaceAll('%', '')}%';
    final where = <String>[
      'deleted_at IS NULL',
      '(title LIKE ? OR body LIKE ? OR tags LIKE ?)',
    ];
    final args = <Object?>[pattern, pattern, pattern];
    if (memorialId != null) {
      where.insert(0, 'memorial_id = ?');
      args.insert(0, memorialId);
    }
    final rows = await db.query(
      'entries',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );
    return rows.map(_entryFromRow).toList();
  }

  Future<void> softDeleteEntry(String entryId, DateTime deletedAt) async {
    final db = await database;
    await db.update(
      'entries',
      {
        'deleted_at': deletedAt.toIso8601String(),
        'updated_at': deletedAt.toIso8601String(),
        'sync_state': SyncState.pendingUpload.name,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> archiveEntry(String entryId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'entries',
      {
        'status': EntryStatus.archived.name,
        'updated_at': now,
        'sync_state': SyncState.pendingUpload.name,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> toggleFavorite(String entryId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'entries',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
        'sync_state': SyncState.pendingUpload.name,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Map<String, Object?> _memorialToRow(Memorial m) => {
        'id': m.id,
        'owner_uid': m.ownerUid,
        'display_name': m.displayName,
        'relationship': m.relationship,
        'birth_date': m.birthDate?.toIso8601String(),
        'passing_date': m.passingDate?.toIso8601String(),
        'photo_url': m.photoUrl,
        'notes': m.notes,
        'created_at': m.createdAt?.toIso8601String(),
        'updated_at': m.updatedAt?.toIso8601String(),
        'sync_state': m.syncState.name,
      };

  Memorial _memorialFromRow(Map<String, Object?> row) {
    return Memorial(
      id: row['id']! as String,
      ownerUid: row['owner_uid']! as String,
      displayName: row['display_name']! as String,
      relationship: row['relationship'] as String?,
      birthDate: row['birth_date'] != null
          ? DateTime.parse(row['birth_date']! as String)
          : null,
      passingDate: row['passing_date'] != null
          ? DateTime.parse(row['passing_date']! as String)
          : null,
      photoUrl: row['photo_url'] as String?,
      notes: row['notes'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at']! as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at']! as String)
          : null,
      syncState: SyncState.values.byName(row['sync_state']! as String),
    );
  }

  Map<String, Object?> _entryToRow(Entry e) => {
        'id': e.id,
        'memorial_id': e.memorialId,
        'owner_uid': e.ownerUid,
        'type': e.type.name,
        'title': e.title,
        'body': e.body,
        'status': e.status.name,
        'privacy': e.privacy.name,
        'is_favorite': e.isFavorite ? 1 : 0,
        'prompt_id': e.promptId,
        'tags': jsonEncode(e.tags),
        'media_ids': jsonEncode(e.mediaIds),
        'created_at': e.createdAt?.toIso8601String(),
        'updated_at': e.updatedAt?.toIso8601String(),
        'deleted_at': e.deletedAt?.toIso8601String(),
        'entry_date': e.entryDate?.toIso8601String(),
        'hidden_from_export': e.hiddenFromExport ? 1 : 0,
        'hidden_from_home': e.hiddenFromHome ? 1 : 0,
        'private_return_date': e.privateReturnDate?.toIso8601String(),
        'extension_json': e.extensionJson.isEmpty
            ? null
            : jsonEncode(e.extensionJson),
        'sync_state': e.syncState.name,
      };

  Entry _entryFromRow(Map<String, Object?> row) {
    return Entry(
      id: row['id']! as String,
      memorialId: row['memorial_id']! as String,
      ownerUid: row['owner_uid']! as String,
      type: entryTypeFromStorage(row['type'] as String?),
      title: row['title']! as String,
      body: row['body']! as String,
      status: EntryStatus.values.byName(row['status']! as String),
      privacy: PrivacyState.values.byName(row['privacy']! as String),
      isFavorite: (row['is_favorite'] as int? ?? 0) == 1,
      promptId: row['prompt_id'] as String?,
      tags: _decodeStringList(row['tags'] as String?),
      mediaIds: _decodeStringList(row['media_ids'] as String?),
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at']! as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at']! as String)
          : null,
      deletedAt: row['deleted_at'] != null
          ? DateTime.parse(row['deleted_at']! as String)
          : null,
      entryDate: row['entry_date'] != null
          ? DateTime.parse(row['entry_date']! as String)
          : null,
      hiddenFromExport: (row['hidden_from_export'] as int? ?? 0) == 1,
      hiddenFromHome: (row['hidden_from_home'] as int? ?? 0) == 1,
      privateReturnDate: row['private_return_date'] != null
          ? DateTime.parse(row['private_return_date']! as String)
          : null,
      extensionJson: _decodeExtensionJson(row['extension_json'] as String?),
      syncState: SyncState.values.byName(row['sync_state']! as String),
    );
  }

  Map<String, dynamic> _decodeExtensionJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return Map<String, dynamic>.from(decoded);
    }
    return const {};
  }

  Future<List<RemembranceDate>> listRemembranceDates({
    required String memorialId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'remembrance_dates',
      where: 'memorial_id = ?',
      whereArgs: [memorialId],
      orderBy: 'date ASC',
    );
    return rows.map(_remembranceFromRow).toList();
  }

  Future<void> upsertRemembranceDate(RemembranceDate date) async {
    final db = await database;
    await db.insert(
      'remembrance_dates',
      {
        'id': date.id,
        'memorial_id': date.memorialId,
        'owner_uid': date.ownerUid,
        'label': date.label,
        'date': date.date.toIso8601String(),
        'recurring': date.recurring ? 1 : 0,
        'notify_enabled': date.notifyEnabled ? 1 : 0,
        'notify_hour': date.notifyHour,
        'notify_minute': date.notifyMinute,
        'show_loved_one_name': date.showLovedOneName ? 1 : 0,
        'show_photos': date.showPhotos ? 1 : 0,
        'pause_until': date.pauseUntil?.toIso8601String(),
        'sync_state': date.syncState.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  RemembranceDate _remembranceFromRow(Map<String, Object?> row) {
    return RemembranceDate(
      id: row['id']! as String,
      memorialId: row['memorial_id']! as String,
      ownerUid: row['owner_uid']! as String,
      label: row['label']! as String,
      date: DateTime.parse(row['date']! as String),
      recurring: (row['recurring'] as int? ?? 1) == 1,
      notifyEnabled: (row['notify_enabled'] as int? ?? 0) == 1,
      notifyHour: row['notify_hour'] as int? ?? 10,
      notifyMinute: row['notify_minute'] as int? ?? 0,
      showLovedOneName: (row['show_loved_one_name'] as int? ?? 0) == 1,
      showPhotos: (row['show_photos'] as int? ?? 0) == 1,
      pauseUntil: row['pause_until'] != null
          ? DateTime.tryParse(row['pause_until']! as String)
          : null,
      syncState: SyncState.values.byName(row['sync_state']! as String),
    );
  }

  /// Moves local device data to a newly created cloud account uid.
  Future<void> reassignOwnerUid({
    required String fromUid,
    required String toUid,
  }) async {
    if (fromUid == toUid) {
      return;
    }
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        'memorials',
        'entries',
        'media',
        'remembrance_dates',
      ]) {
        final values = <String, Object?>{'owner_uid': toUid};
        if (table != 'media') {
          values['sync_state'] = SyncState.pendingUpload.name;
        }
        await txn.update(
          table,
          values,
          where: 'owner_uid = ?',
          whereArgs: [fromUid],
        );
      }
    });
  }

  Future<void> wipeAllUserData() async {
    final db = await database;
    await db.delete('entries');
    await db.delete('memorials');
    await db.delete('media');
    await db.delete('remembrance_dates');
  }

  Future<MediaAttachment> upsertMedia(MediaAttachment media) async {
    final db = await database;
    await db.insert(
      'media',
      {
        'id': media.id,
        'entry_id': media.entryId,
        'owner_uid': media.ownerUid,
        'local_path': media.localPath,
        'remote_path': media.remotePath,
        'mime_type': media.mimeType,
        'file_name': media.fileName,
        'bytes': media.bytes,
        'created_at':
            (media.createdAt ?? DateTime.now()).toIso8601String(),
        'sync_state': media.syncState.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return media;
  }

  Future<List<MediaAttachment>> listMediaForEntry(String entryId) async {
    final db = await database;
    final rows = await db.query(
      'media',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_mediaFromRow).toList();
  }

  Future<List<MediaAttachment>> listPendingMediaUploads() async {
    final db = await database;
    final rows = await db.query(
      'media',
      where: 'sync_state = ?',
      whereArgs: [SyncState.pendingUpload.name],
      orderBy: 'created_at ASC',
    );
    return rows.map(_mediaFromRow).toList();
  }

  Future<int> markLocalMediaPendingUpload() async {
    final db = await database;
    return db.update(
      'media',
      {'sync_state': SyncState.pendingUpload.name},
      where: 'sync_state = ? OR remote_path IS NULL OR remote_path = ?',
      whereArgs: [SyncState.localOnly.name, ''],
    );
  }

  Future<void> deleteMedia(String mediaId) async {
    final db = await database;
    await db.delete('media', where: 'id = ?', whereArgs: [mediaId]);
  }

  MediaAttachment _mediaFromRow(Map<String, Object?> row) {
    return MediaAttachment(
      id: row['id']! as String,
      entryId: row['entry_id']! as String,
      ownerUid: row['owner_uid']! as String,
      localPath: row['local_path']! as String,
      remotePath: row['remote_path'] as String?,
      mimeType: row['mime_type'] as String?,
      fileName: row['file_name'] as String?,
      bytes: row['bytes'] as int?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at']! as String)
          : null,
      syncState: SyncState.values.byName(
        row['sync_state'] as String? ?? SyncState.localOnly.name,
      ),
    );
  }

  List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded.map((e) => e.toString()).toList();
  }
}
