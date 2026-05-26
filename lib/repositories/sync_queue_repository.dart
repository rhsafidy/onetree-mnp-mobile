// lib/repositories/sync_queue_repository.dart

import 'package:mobile_app/models/sync_queue_entry.dart';

import '../core/constants/db_constants.dart';
import '../core/database/app_database.dart';

class SyncQueueRepository {
  final _db = AppDatabase.instance;

  Future<List<SyncQueueEntry>> getPending() async {
    final rows = await _db.query(
      DbConstants.tableSyncQueue,
      where: '${DbConstants.colSyncStatus} = ?',
      whereArgs: [SyncStatus.pending],
      orderBy: DbConstants.colCreatedAt,
    );
    return rows.map(SyncQueueEntry.fromMap).toList();
  }

  Future<List<SyncQueueEntry>> getAll() async {
    final rows = await _db.query(
      DbConstants.tableSyncQueue,
      orderBy: DbConstants.colCreatedAt,
    );
    return rows.map(SyncQueueEntry.fromMap).toList();
  }

  Future<void> markInProgress(String id) async {
    await _db.update(
      DbConstants.tableSyncQueue,
      {DbConstants.colSyncStatus: SyncStatus.inProgress},
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> markDone(String id) async {
    await _db.delete(
      DbConstants.tableSyncQueue,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(String id) async {
    await _db.rawQuery('''
      UPDATE ${DbConstants.tableSyncQueue}
      SET
        ${DbConstants.colSyncStatus}   = CASE
          WHEN ${DbConstants.colSyncAttempts} + 1 >= ${DbConstants.syncMaxRetries}
          THEN '${SyncStatus.failed}'
          ELSE '${SyncStatus.pending}'
        END,
        ${DbConstants.colSyncAttempts} = ${DbConstants.colSyncAttempts} + 1
      WHERE ${DbConstants.colId} = ?
    ''', [id]);
  }

  Future<int> getPendingCount() async {
    final rows = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DbConstants.tableSyncQueue}
      WHERE ${DbConstants.colSyncStatus} != '${SyncStatus.failed}'
    ''');
    return rows.first['count'] as int;
  }

  Future<void> clearFailed() async {
    await _db.delete(
      DbConstants.tableSyncQueue,
      where: '${DbConstants.colSyncStatus} = ?',
      whereArgs: [SyncStatus.failed],
    );
  }
}
