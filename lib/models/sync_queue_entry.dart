// lib/models/sync_queue_entry.dart

import '../core/constants/db_constants.dart';

class SyncQueueEntry {
  final String id;
  final String typeAction;
  final String tableTarget;
  final String entityId;
  final String payloadJson;
  final int attempts;
  final String status;
  final DateTime createdAt;

  const SyncQueueEntry({
    required this.id,
    required this.typeAction,
    required this.tableTarget,
    required this.entityId,
    required this.payloadJson,
    required this.attempts,
    required this.status,
    required this.createdAt,
  });

  factory SyncQueueEntry.fromMap(Map<String, dynamic> map) => SyncQueueEntry(
        id: map[DbConstants.colId] as String,
        typeAction: map[DbConstants.colSyncTypeAction] as String,
        tableTarget: map[DbConstants.colSyncTableTarget] as String,
        entityId: map[DbConstants.colSyncEntityId] as String,
        payloadJson: map[DbConstants.colSyncPayloadJson] as String,
        attempts: map[DbConstants.colSyncAttempts] as int,
        status: map[DbConstants.colSyncStatus] as String,
        createdAt: DateTime.parse(map[DbConstants.colCreatedAt] as String),
      );

  Map<String, dynamic> toMap() => {
        DbConstants.colId: id,
        DbConstants.colSyncTypeAction: typeAction,
        DbConstants.colSyncTableTarget: tableTarget,
        DbConstants.colSyncEntityId: entityId,
        DbConstants.colSyncPayloadJson: payloadJson,
        DbConstants.colSyncAttempts: attempts,
        DbConstants.colSyncStatus: status,
        DbConstants.colCreatedAt: createdAt.toIso8601String(),
      };
}
