
import 'dart:convert';
import 'dart:io';
import 'package:mobile_app/domain/i_photo_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/db_constants.dart';
import '../core/database/app_database.dart';
import '../models/photo.dart';

class PhotoRepository implements IPhotoRepository {
  final _db = AppDatabase.instance;
  final _uuid = const Uuid();

  // ── READ ──────────────────────────────────────────────────────────────────

  @override
  Future<List<Photo>> getByTree(String treeId) async {
    final rows = await _db.query(
      DbConstants.tablePhotos,
      where: '${DbConstants.colPhotoTreeId} = ?',
      whereArgs: [treeId],
      orderBy: '${DbConstants.colCreatedAt} DESC',
    );
    return rows.map(Photo.fromMap).toList();
  }

  @override
  Future<List<Photo>> getPendingUpload() async {
    final rows = await _db.query(
      DbConstants.tablePhotos,
      where: '${DbConstants.colSyncPending} = ?',
      whereArgs: [1],
      orderBy: DbConstants.colCreatedAt,
    );
    return rows.map(Photo.fromMap).toList();
  }

  // ── SAVE LOCALLY ──────────────────────────────────────────────────────────

  @override
  Future<Photo> saveLocally(
    File file,
    String treeId,
    PhotoType type,
  ) async {
    final destPath = await _buildLocalPath(treeId);
    final savedFile = await file.copy(destPath);

    final photo = Photo(
      id: _uuid.v4(),
      url: '',
      localPath: savedFile.path,
      type: type,
      treeId: treeId,
      syncPending: true,
      createdAt: DateTime.now(),
    );

    await _db.runInTransaction((txn) async {
      await txn.insert(
        DbConstants.tablePhotos,
        photo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        DbConstants.tableSyncQueue,
        {
          DbConstants.colId: _uuid.v4(),
          DbConstants.colSyncTypeAction: SyncActions.uploadPhoto,
          DbConstants.colSyncTableTarget: DbConstants.tablePhotos,
          DbConstants.colSyncEntityId: photo.id,
          DbConstants.colSyncPayloadJson: jsonEncode({
            'photo_id': photo.id,
            'tree_id': treeId,
            'local_path': savedFile.path,
            'type': type.name,
          }),
          DbConstants.colSyncAttempts: 0,
          DbConstants.colSyncStatus: SyncStatus.pending,
          DbConstants.colCreatedAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return photo;
  }

  // ── MARK UPLOADED ─────────────────────────────────────────────────────────

  @override
  Future<void> markUploaded(String id, String url) async {
    await _db.update(
      DbConstants.tablePhotos,
      {
        DbConstants.colPhotoUrl: url,
        DbConstants.colSyncPending: 0,
      },
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  // ── UPLOAD (called by SyncService) ────────────────────────────────────────

  @override
  Future<Photo> upload(Photo photo) async {
    // Actual HTTP upload is done in SyncService.
    // This method updates the local record after a successful upload.
    await _db.update(
      DbConstants.tablePhotos,
      {
        DbConstants.colPhotoUrl: photo.url,
        DbConstants.colSyncPending: 0,
      },
      where: '${DbConstants.colId} = ?',
      whereArgs: [photo.id],
    );
    return photo.copyWith(syncPending: false);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    final rows = await _db.query(
      DbConstants.tablePhotos,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final localPath = rows.first[DbConstants.colPhotoLocalPath] as String?;
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) await file.delete();
      }
    }
    await _db.delete(
      DbConstants.tablePhotos,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String> _buildLocalPath(String treeId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(
      p.join(appDir.path, AppConstants.photoDirName, treeId),
    );
    if (!await photoDir.exists()) await photoDir.create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(photoDir.path, 'photo_$timestamp.jpg');
  }
}
