/// Freeform scrapbook placement on an entry page (normalized 0–1 coords).
class EntryPlacement {
  const EntryPlacement({
    required this.id,
    required this.x,
    required this.y,
    this.scale = 0.28,
    this.rotation = 0,
    this.mediaId,
    this.localPath,
  });

  final String id;

  /// Top-left as fraction of canvas width/height.
  final double x;
  final double y;

  /// Width as fraction of canvas width.
  final double scale;
  final double rotation;
  final String? mediaId;
  final String? localPath;

  EntryPlacement copyWith({
    String? id,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    String? mediaId,
    String? localPath,
  }) {
    return EntryPlacement(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      mediaId: mediaId ?? this.mediaId,
      localPath: localPath ?? this.localPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': 'photo',
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
        if (mediaId != null) 'mediaId': mediaId,
        if (localPath != null) 'localPath': localPath,
      };

  factory EntryPlacement.fromJson(Map<String, dynamic> json) {
    return EntryPlacement(
      id: json['id'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.1,
      y: (json['y'] as num?)?.toDouble() ?? 0.1,
      scale: (json['scale'] as num?)?.toDouble() ?? 0.28,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      mediaId: json['mediaId'] as String?,
      localPath: json['localPath'] as String?,
    );
  }
}

List<EntryPlacement> placementsFromExtension(Map<String, dynamic> ext) {
  final raw = ext['placements'];
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .where((e) {
        final kind = e['kind'] as String? ?? 'photo';
        // Stickers were removed; keep photos only.
        return kind == 'photo';
      })
      .map(EntryPlacement.fromJson)
      .where((p) => p.id.isNotEmpty)
      .toList();
}
