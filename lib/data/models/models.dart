/// Domain models for Letters to Heaven.
library;

enum EntryType {
  letter,
  memory,
  meaningfulMoment,
  keepsake,
}

/// Maps stored / legacy type names onto the four MVP entry types.
EntryType entryTypeFromStorage(String? name) {
  if (name == null || name.isEmpty) {
    return EntryType.memory;
  }
  switch (name) {
    case 'letter':
    case 'gratitude':
      return EntryType.letter;
    case 'memory':
    case 'interview':
    case 'tradition':
    case 'milestone':
      return EntryType.memory;
    case 'meaningfulMoment':
    case 'sign':
    case 'cardinalVisit':
    case 'reflection':
      return EntryType.meaningfulMoment;
    case 'keepsake':
    case 'recipe':
    case 'note':
      return EntryType.keepsake;
    default:
      try {
        return EntryType.values.byName(name);
      } catch (_) {
        return EntryType.memory;
      }
  }
}

enum EntryStatus {
  draft,
  saved,
  archived,
}

enum PrivacyState {
  private,
  familyOnly,
  sharedLink,
}

enum SyncState {
  localOnly,
  pendingUpload,
  synced,
  pendingDownload,
  conflict,
}

enum ExportJobStatus {
  queued,
  processing,
  completed,
  failed,
}

enum EntitlementTier {
  free,
  premium,
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.tier = EntitlementTier.free,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final EntitlementTier tier;

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    EntitlementTier? tier,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tier: tier ?? this.tier,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'tier': tier.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tier: EntitlementTier.values.byName(
        json['tier'] as String? ?? EntitlementTier.free.name,
      ),
    );
  }
}

class Memorial {
  const Memorial({
    required this.id,
    required this.ownerUid,
    required this.displayName,
    this.relationship,
    this.birthDate,
    this.passingDate,
    this.photoUrl,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.syncState = SyncState.localOnly,
  });

  final String id;
  final String ownerUid;
  final String displayName;
  final String? relationship;
  final DateTime? birthDate;
  final DateTime? passingDate;
  final String? photoUrl;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncState syncState;

  Memorial copyWith({
    String? id,
    String? ownerUid,
    String? displayName,
    String? relationship,
    DateTime? birthDate,
    DateTime? passingDate,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncState? syncState,
  }) {
    return Memorial(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      birthDate: birthDate ?? this.birthDate,
      passingDate: passingDate ?? this.passingDate,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        'displayName': displayName,
        'relationship': relationship,
        'birthDate': birthDate?.toIso8601String(),
        'passingDate': passingDate?.toIso8601String(),
        'photoUrl': photoUrl,
        'notes': notes,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'syncState': syncState.name,
      };

  factory Memorial.fromJson(Map<String, dynamic> json) {
    return Memorial(
      id: json['id'] as String,
      ownerUid: json['ownerUid'] as String,
      displayName: json['displayName'] as String,
      relationship: json['relationship'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      passingDate: json['passingDate'] != null
          ? DateTime.parse(json['passingDate'] as String)
          : null,
      photoUrl: json['photoUrl'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      syncState: SyncState.values.byName(
        json['syncState'] as String? ?? SyncState.localOnly.name,
      ),
    );
  }
}

class Entry {
  const Entry({
    required this.id,
    required this.memorialId,
    required this.ownerUid,
    required this.type,
    required this.title,
    required this.body,
    this.status = EntryStatus.draft,
    this.privacy = PrivacyState.private,
    this.isFavorite = false,
    this.hiddenFromExport = false,
    this.hiddenFromHome = false,
    this.privateReturnDate,
    this.promptId,
    this.tags = const [],
    this.mediaIds = const [],
    this.entryDate,
    this.extensionJson = const {},
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncState = SyncState.localOnly,
  });

  final String id;
  final String memorialId;
  final String ownerUid;
  final EntryType type;
  final String title;
  final String body;
  final EntryStatus status;
  final PrivacyState privacy;
  final bool isFavorite;
  final bool hiddenFromExport;
  /// Soft-hide from Home without deleting (photographs and memories included).
  final bool hiddenFromHome;
  /// Optional private date when the writer may want to return.
  final DateTime? privateReturnDate;
  final String? promptId;
  final List<String> tags;
  final List<String> mediaIds;
  final DateTime? entryDate;
  final Map<String, dynamic> extensionJson;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final SyncState syncState;

  bool get isDeleted => deletedAt != null;

  /// Whether this entry should appear in Home recent lists.
  /// A private return date hides until that calendar day; after that it returns
  /// to Home even if [hiddenFromHome] is still set. Hide-for-now (no date)
  /// stays off Home until the writer unhides it.
  bool get isVisibleOnHome {
    final returnAt = privateReturnDate;
    if (returnAt != null) {
      final day = DateTime(returnAt.year, returnAt.month, returnAt.day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return !day.isAfter(today);
    }
    return !hiddenFromHome;
  }

  Entry copyWith({
    String? id,
    String? memorialId,
    String? ownerUid,
    EntryType? type,
    String? title,
    String? body,
    EntryStatus? status,
    PrivacyState? privacy,
    bool? isFavorite,
    bool? hiddenFromExport,
    bool? hiddenFromHome,
    DateTime? privateReturnDate,
    bool clearPrivateReturnDate = false,
    String? promptId,
    List<String>? tags,
    List<String>? mediaIds,
    DateTime? entryDate,
    Map<String, dynamic>? extensionJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    SyncState? syncState,
  }) {
    return Entry(
      id: id ?? this.id,
      memorialId: memorialId ?? this.memorialId,
      ownerUid: ownerUid ?? this.ownerUid,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      privacy: privacy ?? this.privacy,
      isFavorite: isFavorite ?? this.isFavorite,
      hiddenFromExport: hiddenFromExport ?? this.hiddenFromExport,
      hiddenFromHome: hiddenFromHome ?? this.hiddenFromHome,
      privateReturnDate: clearPrivateReturnDate
          ? null
          : (privateReturnDate ?? this.privateReturnDate),
      promptId: promptId ?? this.promptId,
      tags: tags ?? this.tags,
      mediaIds: mediaIds ?? this.mediaIds,
      entryDate: entryDate ?? this.entryDate,
      extensionJson: extensionJson ?? this.extensionJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memorialId': memorialId,
        'ownerUid': ownerUid,
        'type': type.name,
        'title': title,
        'body': body,
        'status': status.name,
        'privacy': privacy.name,
        'isFavorite': isFavorite,
        'hiddenFromExport': hiddenFromExport,
        'hiddenFromHome': hiddenFromHome,
        'privateReturnDate': privateReturnDate?.toIso8601String(),
        'promptId': promptId,
        'tags': tags,
        'mediaIds': mediaIds,
        'entryDate': entryDate?.toIso8601String(),
        'extensionJson': extensionJson,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
        'syncState': syncState.name,
      };

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as String,
      memorialId: json['memorialId'] as String,
      ownerUid: json['ownerUid'] as String,
      type: entryTypeFromStorage(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: EntryStatus.values.byName(
        json['status'] as String? ?? EntryStatus.draft.name,
      ),
      privacy: PrivacyState.values.byName(
        json['privacy'] as String? ?? PrivacyState.private.name,
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
      hiddenFromExport: json['hiddenFromExport'] as bool? ?? false,
      hiddenFromHome: json['hiddenFromHome'] as bool? ?? false,
      privateReturnDate: json['privateReturnDate'] != null
          ? DateTime.parse(json['privateReturnDate'] as String)
          : null,
      promptId: json['promptId'] as String?,
      entryDate: json['entryDate'] != null
          ? DateTime.parse(json['entryDate'] as String)
          : null,
      extensionJson: json['extensionJson'] is Map
          ? Map<String, dynamic>.from(json['extensionJson'] as Map)
          : const {},
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mediaIds: (json['mediaIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      syncState: SyncState.values.byName(
        json['syncState'] as String? ?? SyncState.localOnly.name,
      ),
    );
  }
}

class MediaAttachment {
  const MediaAttachment({
    required this.id,
    required this.entryId,
    required this.ownerUid,
    required this.localPath,
    this.remotePath,
    this.mimeType,
    this.fileName,
    this.bytes,
    this.createdAt,
    this.syncState = SyncState.localOnly,
  });

  final String id;
  final String entryId;
  final String ownerUid;
  final String localPath;
  final String? remotePath;
  final String? mimeType;
  final String? fileName;
  final int? bytes;
  final DateTime? createdAt;
  final SyncState syncState;

  MediaAttachment copyWith({
    String? id,
    String? entryId,
    String? ownerUid,
    String? localPath,
    String? remotePath,
    String? mimeType,
    String? fileName,
    int? bytes,
    DateTime? createdAt,
    SyncState? syncState,
  }) {
    return MediaAttachment(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      ownerUid: ownerUid ?? this.ownerUid,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      mimeType: mimeType ?? this.mimeType,
      fileName: fileName ?? this.fileName,
      bytes: bytes ?? this.bytes,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entryId': entryId,
        'ownerUid': ownerUid,
        'localPath': localPath,
        'remotePath': remotePath,
        'mimeType': mimeType,
        'fileName': fileName,
        'bytes': bytes,
        'createdAt': createdAt?.toIso8601String(),
        'syncState': syncState.name,
      };

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      id: json['id'] as String,
      entryId: json['entryId'] as String,
      ownerUid: json['ownerUid'] as String,
      localPath: json['localPath'] as String,
      remotePath: json['remotePath'] as String?,
      mimeType: json['mimeType'] as String?,
      fileName: json['fileName'] as String?,
      bytes: json['bytes'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      syncState: SyncState.values.byName(
        json['syncState'] as String? ?? SyncState.localOnly.name,
      ),
    );
  }
}

class Prompt {
  const Prompt({
    required this.id,
    required this.category,
    required this.text,
    required this.intensity,
    this.sensitivityTags = const [],
  });

  final String id;
  final String category;
  final String text;
  final String intensity;
  final List<String> sensitivityTags;

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      category: json['category'] as String,
      text: json['text'] as String,
      intensity: json['intensity'] as String,
      sensitivityTags: (json['sensitivityTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

class RemembranceDate {
  const RemembranceDate({
    required this.id,
    required this.memorialId,
    required this.ownerUid,
    required this.label,
    required this.date,
    this.recurring = true,
    this.notifyEnabled = false,
    this.notifyHour = 10,
    this.notifyMinute = 0,
    this.showLovedOneName = false,
    this.showPhotos = false,
    this.pauseUntil,
    this.syncState = SyncState.localOnly,
  });

  final String id;
  final String memorialId;
  final String ownerUid;
  final String label;
  final DateTime date;
  final bool recurring;
  final bool notifyEnabled;
  final int notifyHour;
  final int notifyMinute;
  final bool showLovedOneName;
  final bool showPhotos;
  final DateTime? pauseUntil;
  final SyncState syncState;

  RemembranceDate copyWith({
    String? id,
    String? memorialId,
    String? ownerUid,
    String? label,
    DateTime? date,
    bool? recurring,
    bool? notifyEnabled,
    int? notifyHour,
    int? notifyMinute,
    bool? showLovedOneName,
    bool? showPhotos,
    DateTime? pauseUntil,
    SyncState? syncState,
  }) {
    return RemembranceDate(
      id: id ?? this.id,
      memorialId: memorialId ?? this.memorialId,
      ownerUid: ownerUid ?? this.ownerUid,
      label: label ?? this.label,
      date: date ?? this.date,
      recurring: recurring ?? this.recurring,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      showLovedOneName: showLovedOneName ?? this.showLovedOneName,
      showPhotos: showPhotos ?? this.showPhotos,
      pauseUntil: pauseUntil ?? this.pauseUntil,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memorialId': memorialId,
        'ownerUid': ownerUid,
        'label': label,
        'date': date.toIso8601String(),
        'recurring': recurring,
        'notifyEnabled': notifyEnabled,
        'notifyHour': notifyHour,
        'notifyMinute': notifyMinute,
        'showLovedOneName': showLovedOneName,
        'showPhotos': showPhotos,
        'pauseUntil': pauseUntil?.toIso8601String(),
        'syncState': syncState.name,
      };

  factory RemembranceDate.fromJson(Map<String, dynamic> json) {
    return RemembranceDate(
      id: json['id'] as String,
      memorialId: json['memorialId'] as String,
      ownerUid: json['ownerUid'] as String,
      label: json['label'] as String,
      date: DateTime.parse(json['date'] as String),
      recurring: json['recurring'] as bool? ?? true,
      notifyEnabled: json['notifyEnabled'] as bool? ?? false,
      notifyHour: json['notifyHour'] as int? ?? 10,
      notifyMinute: json['notifyMinute'] as int? ?? 0,
      showLovedOneName: json['showLovedOneName'] as bool? ?? false,
      showPhotos: json['showPhotos'] as bool? ?? false,
      pauseUntil: json['pauseUntil'] != null
          ? DateTime.tryParse(json['pauseUntil'] as String)
          : null,
      syncState: SyncState.values.byName(
        json['syncState'] as String? ?? SyncState.localOnly.name,
      ),
    );
  }
}

class ExportJob {
  const ExportJob({
    required this.id,
    required this.ownerUid,
    required this.memorialId,
    this.status = ExportJobStatus.queued,
    this.downloadUrl,
    this.errorMessage,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String ownerUid;
  final String memorialId;
  final ExportJobStatus status;
  final String? downloadUrl;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        'memorialId': memorialId,
        'status': status.name,
        'downloadUrl': downloadUrl,
        'errorMessage': errorMessage,
        'createdAt': createdAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory ExportJob.fromJson(Map<String, dynamic> json) {
    return ExportJob(
      id: json['id'] as String,
      ownerUid: json['ownerUid'] as String,
      memorialId: json['memorialId'] as String,
      status: ExportJobStatus.values.byName(
        json['status'] as String? ?? ExportJobStatus.queued.name,
      ),
      downloadUrl: json['downloadUrl'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

class Entitlement {
  const Entitlement({
    required this.id,
    required this.ownerUid,
    required this.tier,
    this.productId,
    this.expiresAt,
    this.source,
  });

  final String id;
  final String ownerUid;
  final EntitlementTier tier;
  final String? productId;
  final DateTime? expiresAt;
  final String? source;

  bool get isPremium =>
      tier == EntitlementTier.premium &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        'tier': tier.name,
        'productId': productId,
        'expiresAt': expiresAt?.toIso8601String(),
        'source': source,
      };

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    return Entitlement(
      id: json['id'] as String,
      ownerUid: json['ownerUid'] as String,
      tier: EntitlementTier.values.byName(
        json['tier'] as String? ?? EntitlementTier.free.name,
      ),
      productId: json['productId'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      source: json['source'] as String?,
    );
  }
}
