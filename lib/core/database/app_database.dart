// lib/core/database/app_database.dart
//
// Singleton SQLite database helper.
// Handles: opening, schema creation (DDL), and future migrations.

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/db_constants.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  // ── Public accessor ───────────────────────────────────────────────────────

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  // ── Open / init ───────────────────────────────────────────────────────────

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.dbName);

    return openDatabase(
      path,
      version: DbConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign key enforcement (disabled by default in SQLite).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ── Schema creation ───────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute(_createUsersTable);
    batch.execute(_createTouristsTable);
    batch.execute(_createParcelsTable);
    batch.execute(_createTreesTable);
    batch.execute(_createPhotosTable);
    batch.execute(_createSyncQueueTable);

    // Indexes for common lookups
    batch.execute(_indexTreeExternalId);
    batch.execute(_indexTreeParcelId);
    batch.execute(_indexTreeTouristId);
    batch.execute(_indexTreeSyncPending);
    batch.execute(_indexPhotoTreeId);
    batch.execute(_indexPhotoSyncPending);
    batch.execute(_indexSyncQueueStatus);

    await batch.commit(noResult: true);
  }

  // ── Migrations ────────────────────────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → v2 example (uncomment when needed):
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE ${DbConstants.tableTrees} ADD COLUMN new_field TEXT');
    // }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DDL — CREATE TABLE statements
  // ══════════════════════════════════════════════════════════════════════════

  static const String _createUsersTable = '''
    CREATE TABLE IF NOT EXISTS ${DbConstants.tableUsers} (
      ${DbConstants.colId}              TEXT    PRIMARY KEY,
      ${DbConstants.colUserName}        TEXT    NOT NULL,
      ${DbConstants.colUserEmail}       TEXT    NOT NULL UNIQUE,
      ${DbConstants.colUserPasswordHash} TEXT   NOT NULL,
      ${DbConstants.colUserRole}        TEXT    NOT NULL DEFAULT '${UserRoles.agent}',
      ${DbConstants.colCreatedAt}       TEXT    NOT NULL,
      ${DbConstants.colUpdatedAt}       TEXT    NOT NULL
    )
  ''';

  static const String _createTouristsTable = '''
    CREATE TABLE IF NOT EXISTS ${DbConstants.tableTourists} (
      ${DbConstants.colId}                  TEXT  PRIMARY KEY,
      ${DbConstants.colTouristName}         TEXT  NOT NULL,
      ${DbConstants.colTouristEmail}        TEXT,
      ${DbConstants.colTouristNationality}  TEXT,
      ${DbConstants.colTouristPhone}        TEXT,
      ${DbConstants.colCreatedAt}           TEXT  NOT NULL
    )
  ''';

  static const String _createParcelsTable = '''
    CREATE TABLE IF NOT EXISTS ${DbConstants.tableParcels} (
      ${DbConstants.colId}                  TEXT  PRIMARY KEY,
      ${DbConstants.colParcelName}          TEXT  NOT NULL,
      ${DbConstants.colParcelCode}          TEXT  NOT NULL UNIQUE,
      ${DbConstants.colParcelPark}          TEXT,
      ${DbConstants.colParcelAreaHa}        REAL,
      ${DbConstants.colParcelLatitude}      REAL,
      ${DbConstants.colParcelLongitude}     REAL,
      ${DbConstants.colParcelNotes}         TEXT,
      ${DbConstants.colParcelShapefileName} TEXT,
      ${DbConstants.colCreatedAt}           TEXT  NOT NULL,
      ${DbConstants.colUpdatedAt}           TEXT  NOT NULL
    )
  ''';

  static const String _createTreesTable = '''
    CREATE TABLE IF NOT EXISTS ${DbConstants.tableTrees} (
      ${DbConstants.colId}                    TEXT  PRIMARY KEY,
      ${DbConstants.colTreeExternalId}        TEXT  NOT NULL UNIQUE,
      ${DbConstants.colTreeSpeciesScientific} TEXT,
      ${DbConstants.colTreeSpeciesVernacular} TEXT,
      ${DbConstants.colTreePlanterName}       TEXT,
      ${DbConstants.colTreePlanterFunction}   TEXT,
      ${DbConstants.colTreePlantationDate}    TEXT,
      ${DbConstants.colTreeArea}              TEXT,
      ${DbConstants.colTreeFamily}            TEXT,
      ${DbConstants.colTreeHeightCm}          INTEGER,
      ${DbConstants.colTreeHoleNumber}        INTEGER,
      ${DbConstants.colTreeHealthStatus}      TEXT DEFAULT '${TreeHealthStatus.pending}',
      ${DbConstants.colTreeLatitude}          REAL,
      ${DbConstants.colTreeLongitude}         REAL,
      ${DbConstants.colTreeNotes}             TEXT,
      ${DbConstants.colTreeParcelId}          TEXT REFERENCES ${DbConstants.tableParcels}(${DbConstants.colId}) ON DELETE SET NULL,
      ${DbConstants.colTreeTouristId}         TEXT REFERENCES ${DbConstants.tableTourists}(${DbConstants.colId}) ON DELETE SET NULL,
      ${DbConstants.colTreePlantedByUserId}   TEXT REFERENCES ${DbConstants.tableUsers}(${DbConstants.colId}) ON DELETE SET NULL,
      ${DbConstants.colSyncPending}           INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colCreatedAt}             TEXT    NOT NULL,
      ${DbConstants.colUpdatedAt}             TEXT    NOT NULL
    )
  ''';

  static const String _createPhotosTable = '''
    CREATE TABLE IF NOT EXISTS ${DbConstants.tablePhotos} (
      ${DbConstants.colId}                   TEXT  PRIMARY KEY,
      ${DbConstants.colPhotoUrl}             TEXT  NOT NULL DEFAULT '',
      ${DbConstants.colPhotoLocalPath}       TEXT,
      ${DbConstants.colPhotoType}            TEXT  NOT NULL DEFAULT '${PhotoTypeValues.monthly}',
      ${DbConstants.colPhotoTreeId}          TEXT REFERENCES ${DbConstants.tableTrees}(${DbConstants.colId}) ON DELETE CASCADE,
      ${DbConstants.colPhotoUploadedByUserId} TEXT REFERENCES ${DbConstants.tableUsers}(${DbConstants.colId}) ON DELETE SET NULL,
      ${DbConstants.colSyncPending}          INTEGER NOT NULL DEFAULT 1,
      ${DbConstants.colCreatedAt}            TEXT    NOT NULL
    )
  ''';

  static const String _createSyncQueueTable = '''
    CREATE TABLE IF NOT EXISTS ${DbConstants.tableSyncQueue} (
      ${DbConstants.colId}              TEXT    PRIMARY KEY,
      ${DbConstants.colSyncTypeAction}  TEXT    NOT NULL,
      ${DbConstants.colSyncTableTarget} TEXT    NOT NULL,
      ${DbConstants.colSyncEntityId}    TEXT    NOT NULL,
      ${DbConstants.colSyncPayloadJson} TEXT    NOT NULL,
      ${DbConstants.colSyncAttempts}    INTEGER NOT NULL DEFAULT 0,
      ${DbConstants.colSyncStatus}      TEXT    NOT NULL DEFAULT '${SyncStatus.pending}',
      ${DbConstants.colCreatedAt}       TEXT    NOT NULL
    )
  ''';

  // ── Indexes ───────────────────────────────────────────────────────────────

  static const String _indexTreeExternalId = '''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_trees_external_id
    ON ${DbConstants.tableTrees}(${DbConstants.colTreeExternalId})
  ''';

  static const String _indexTreeParcelId = '''
    CREATE INDEX IF NOT EXISTS idx_trees_parcel_id
    ON ${DbConstants.tableTrees}(${DbConstants.colTreeParcelId})
  ''';

  static const String _indexTreeTouristId = '''
    CREATE INDEX IF NOT EXISTS idx_trees_tourist_id
    ON ${DbConstants.tableTrees}(${DbConstants.colTreeTouristId})
  ''';

  static const String _indexTreeSyncPending = '''
    CREATE INDEX IF NOT EXISTS idx_trees_sync_pending
    ON ${DbConstants.tableTrees}(${DbConstants.colSyncPending})
    WHERE ${DbConstants.colSyncPending} = 1
  ''';

  static const String _indexPhotoTreeId = '''
    CREATE INDEX IF NOT EXISTS idx_photos_tree_id
    ON ${DbConstants.tablePhotos}(${DbConstants.colPhotoTreeId})
  ''';

  static const String _indexPhotoSyncPending = '''
    CREATE INDEX IF NOT EXISTS idx_photos_sync_pending
    ON ${DbConstants.tablePhotos}(${DbConstants.colSyncPending})
    WHERE ${DbConstants.colSyncPending} = 1
  ''';

  static const String _indexSyncQueueStatus = '''
    CREATE INDEX IF NOT EXISTS idx_sync_queue_status
    ON ${DbConstants.tableSyncQueue}(${DbConstants.colSyncStatus})
  ''';

  // ══════════════════════════════════════════════════════════════════════════
  // Generic CRUD helpers used by all repositories
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    await db.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<void> runInTransaction(Future<void> Function(Transaction txn) action) async {
    final db = await database;
    await db.transaction(action);
  }

  // ── Dev helpers ───────────────────────────────────────────────────────────

  /// Drop and recreate all tables. Use only during development.
  Future<void> resetDatabase() async {
    final db = await database;
    final tables = [
      DbConstants.tableSyncQueue,
      DbConstants.tablePhotos,
      DbConstants.tableTrees,
      DbConstants.tableParcels,
      DbConstants.tableTourists,
      DbConstants.tableUsers,
    ];
    for (final t in tables) {
      await db.execute('DROP TABLE IF EXISTS $t');
    }
    await _onCreate(db, DbConstants.dbVersion);
  }
}
