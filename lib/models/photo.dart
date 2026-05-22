enum PhotoType { plantation, monthly, replanting }

class Photo {
  final String id;
  final String url;
  final String? localPath;
  final PhotoType type;
  final String? treeId;
  final String? uploadedByUserId;
  final bool syncPending;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.url,
    this.localPath,
    this.type = PhotoType.monthly,
    this.treeId,
    this.uploadedByUserId,
    this.syncPending = false,
    required this.createdAt,
  });

  factory Photo.fromMap(Map<String, dynamic> map) => Photo(
        id: map['id'] as String,
        url: map['url'] as String,
        localPath: map['local_path'] as String?,
        type: PhotoType.values.firstWhere(
          (t) => t.name == (map['type'] as String? ?? 'monthly'),
          orElse: () => PhotoType.monthly,
        ),
        treeId: map['tree_id'] as String?,
        uploadedByUserId: map['uploaded_by_user_id'] as String?,
        syncPending: (map['sync_pending'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'local_path': localPath,
        'type': type.name,
        'tree_id': treeId,
        'uploaded_by_user_id': uploadedByUserId,
        'sync_pending': syncPending ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  Photo copyWith({
    String? url,
    String? localPath,
    bool? syncPending,
  }) =>
      Photo(
        id: id,
        url: url ?? this.url,
        localPath: localPath ?? this.localPath,
        type: type,
        treeId: treeId,
        uploadedByUserId: uploadedByUserId,
        syncPending: syncPending ?? this.syncPending,
        createdAt: createdAt,
      );
}