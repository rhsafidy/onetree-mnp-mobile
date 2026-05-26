// lib/repositories/tree_repository.dart

import 'dart:convert';
import 'package:mobile_app/domain/i_tree_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/db_constants.dart';
import '../core/database/app_database.dart';
import '../models/tree.dart';

class TreeRepository implements ITreeRepository {
  final _db = AppDatabase.instance;
  final _uuid = const Uuid();

  // ── READ ──────────────────────────────────────────────────────────────────

  @override
  Future<Tree?> getByQRCode(String externalId) async {
    final rows = await _db.query(
      DbConstants.tableTrees,
      where: '${DbConstants.colTreeExternalId} = ?',
      whereArgs: [externalId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tree.fromMap(rows.first);
  }

  @override
  Future<Tree?> getById(String id) async {
    final rows = await _db.query(
      DbConstants.tableTrees,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tree.fromMap(rows.first);
  }

  @override
  Future<List<Tree>> getAll() async {
    final rows = await _db.query(
      DbConstants.tableTrees,
      orderBy: '${DbConstants.colCreatedAt} DESC',
    );
    return rows.map(Tree.fromMap).toList();
  }

  @override
  Future<List<Tree>> getByParcel(String parcelId) async {
    final rows = await _db.query(
      DbConstants.tableTrees,
      where: '${DbConstants.colTreeParcelId} = ?',
      whereArgs: [parcelId],
      orderBy: DbConstants.colTreeHoleNumber,
    );
    return rows.map(Tree.fromMap).toList();
  }

  @override
  Future<List<Tree>> getPendingSync() async {
    final rows = await _db.query(
      DbConstants.tableTrees,
      where: '${DbConstants.colSyncPending} = ?',
      whereArgs: [1],
      orderBy: DbConstants.colCreatedAt,
    );
    return rows.map(Tree.fromMap).toList();
  }

  Future<List<Tree>> getByStatus(String status) async {
    final rows = await _db.query(
      DbConstants.tableTrees,
      where: '${DbConstants.colTreeHealthStatus} = ?',
      whereArgs: [status],
    );
    return rows.map(Tree.fromMap).toList();
  }

  Future<List<Tree>> getByTourist(String touristId) async {
    final rows = await _db.query(
      DbConstants.tableTrees,
      where: '${DbConstants.colTreeTouristId} = ?',
      whereArgs: [touristId],
    );
    return rows.map(Tree.fromMap).toList();
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  @override
  Future<Tree> createPlantation(Tree tree) async {
    final newTree = Tree(
      id: tree.id.isNotEmpty ? tree.id : _uuid.v4(),
      externalId: tree.externalId,
      speciesScientific: tree.speciesScientific,
      speciesVernacular: tree.speciesVernacular,
      planterName: tree.planterName,
      planterFunction: tree.planterFunction,
      plantationDate: tree.plantationDate ?? DateTime.now(),
      area: tree.area,
      family: tree.family,
      heightCm: tree.heightCm,
      holeNumber: tree.holeNumber,
      healthStatus: tree.healthStatus ?? TreeHealthStatus.planted,
      latitude: tree.latitude,
      longitude: tree.longitude,
      notes: tree.notes,
      parcelId: tree.parcelId,
      touristId: tree.touristId,
      plantedByUserId: tree.plantedByUserId,
      syncPending: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.runInTransaction((txn) async {
      await txn.insert(
        DbConstants.tableTrees,
        newTree.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        DbConstants.tableSyncQueue,
        _buildSyncEntry(SyncActions.create, newTree.id, newTree.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return newTree;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  @override
  Future<Tree> update(Tree tree) async {
    final updated = tree.copyWith(syncPending: true);

    await _db.runInTransaction((txn) async {
      await txn.update(
        DbConstants.tableTrees,
        updated.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [tree.id],
      );
      await txn.insert(
        DbConstants.tableSyncQueue,
        _buildSyncEntry(SyncActions.update, tree.id, updated.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return updated;
  }

  @override
  Future<void> markSynced(String id) async {
    await _db.update(
      DbConstants.tableTrees,
      {DbConstants.colSyncPending: 0},
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  // ── REPLACE (Phase 5 — Replanting) ───────────────────────────────────────

  @override
  Future<void> replace(String id, Tree newTree) async {
    // Keep the same QR code (externalId) and history.
    // Only update health status and plantation data.
    final replacement = newTree.copyWith(
      healthStatus: TreeHealthStatus.planted,
      syncPending: true,
    );

    await _db.runInTransaction((txn) async {
      await txn.update(
        DbConstants.tableTrees,
        replacement.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
      await txn.insert(
        DbConstants.tableSyncQueue,
        _buildSyncEntry(SyncActions.update, id, replacement.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableTrees,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  // ── Stats helpers ─────────────────────────────────────────────────────────

  Future<Map<String, int>> getStatusCounts() async {
    final rows = await _db.rawQuery('''
      SELECT ${DbConstants.colTreeHealthStatus} as status, COUNT(*) as count
      FROM ${DbConstants.tableTrees}
      GROUP BY ${DbConstants.colTreeHealthStatus}
    ''');
    return {for (final r in rows) r['status'] as String: r['count'] as int};
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Map<String, dynamic> _buildSyncEntry(
    String action,
    String entityId,
    Map<String, dynamic> payload,
  ) =>
      {
        DbConstants.colId: _uuid.v4(),
        DbConstants.colSyncTypeAction: action,
        DbConstants.colSyncTableTarget: DbConstants.tableTrees,
        DbConstants.colSyncEntityId: entityId,
        DbConstants.colSyncPayloadJson: jsonEncode(payload),
        DbConstants.colSyncAttempts: 0,
        DbConstants.colSyncStatus: SyncStatus.pending,
        DbConstants.colCreatedAt: DateTime.now().toIso8601String(),
      };
}
