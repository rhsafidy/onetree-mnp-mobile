// lib/core/database/database_seeder.dart
//
// Seeds the local SQLite database with initial data.
// Call DatabaseSeeder.seed() once after first launch (dev / staging only).
// In production, data comes from the API sync.

import 'package:uuid/uuid.dart';
import '../constants/db_constants.dart';
import 'app_database.dart';

class DatabaseSeeder {
  DatabaseSeeder._();

  static final _uuid = const Uuid();

  static Future<void> seed() async {
    final db = AppDatabase.instance;

    // Guard: only seed if tables are empty
    final existing = await db.query(DbConstants.tableUsers, limit: 1);
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toIso8601String();

    // ── 1. Users (MNP agents) ────────────────────────────────────────────
    final adminId = _uuid.v4();
    final agentId = _uuid.v4();
    final receptionistId = _uuid.v4();

    await db.insert(DbConstants.tableUsers, {
      DbConstants.colId: adminId,
      DbConstants.colUserName: 'Admin MNP',
      DbConstants.colUserEmail: 'admin@mnp.mg',
      DbConstants.colUserPasswordHash: 'hashed_password_here',
      DbConstants.colUserRole: UserRoles.admin,
      DbConstants.colCreatedAt: now,
      DbConstants.colUpdatedAt: now,
    });

    await db.insert(DbConstants.tableUsers, {
      DbConstants.colId: agentId,
      DbConstants.colUserName: 'Agent Mantadia',
      DbConstants.colUserEmail: 'agent@mnp.mg',
      DbConstants.colUserPasswordHash: 'hashed_password_here',
      DbConstants.colUserRole: UserRoles.agent,
      DbConstants.colCreatedAt: now,
      DbConstants.colUpdatedAt: now,
    });

    await db.insert(DbConstants.tableUsers, {
      DbConstants.colId: receptionistId,
      DbConstants.colUserName: 'Hotesse Accueil',
      DbConstants.colUserEmail: 'accueil@mnp.mg',
      DbConstants.colUserPasswordHash: 'hashed_password_here',
      DbConstants.colUserRole: UserRoles.receptionist,
      DbConstants.colCreatedAt: now,
      DbConstants.colUpdatedAt: now,
    });

    // ── 2. Parcels (Mantadia restoration zones) ──────────────────────────
    final parcel1Id = _uuid.v4();
    final parcel2Id = _uuid.v4();
    final parcel3Id = _uuid.v4();

    await db.insert(DbConstants.tableParcels, {
      DbConstants.colId: parcel1Id,
      DbConstants.colParcelName: 'North-East Zone — Block A',
      DbConstants.colParcelCode: 'PARC-01',
      DbConstants.colParcelPark: 'Mantadia National Park',
      DbConstants.colParcelAreaHa: 2.5,
      DbConstants.colParcelLatitude: -18.8150,
      DbConstants.colParcelLongitude: 48.4210,
      DbConstants.colParcelNotes: 'Primary restoration zone. 250 holes prepared.',
      DbConstants.colCreatedAt: now,
      DbConstants.colUpdatedAt: now,
    });

    await db.insert(DbConstants.tableParcels, {
      DbConstants.colId: parcel2Id,
      DbConstants.colParcelName: 'South Valley — Block B',
      DbConstants.colParcelCode: 'PARC-02',
      DbConstants.colParcelPark: 'Mantadia National Park',
      DbConstants.colParcelAreaHa: 1.8,
      DbConstants.colParcelLatitude: -18.8310,
      DbConstants.colParcelLongitude: 48.4180,
      DbConstants.colParcelNotes: 'Secondary zone. Mixed endemic species.',
      DbConstants.colCreatedAt: now,
      DbConstants.colUpdatedAt: now,
    });

    await db.insert(DbConstants.tableParcels, {
      DbConstants.colId: parcel3Id,
      DbConstants.colParcelName: 'Ridge Line — Block C',
      DbConstants.colParcelCode: 'PARC-03',
      DbConstants.colParcelPark: 'Mantadia National Park',
      DbConstants.colParcelAreaHa: 3.2,
      DbConstants.colParcelLatitude: -18.8080,
      DbConstants.colParcelLongitude: 48.4250,
      DbConstants.colParcelNotes: 'High altitude zone. Canopy restoration priority.',
      DbConstants.colCreatedAt: now,
      DbConstants.colUpdatedAt: now,
    });

    // ── 3. Pre-attributed Trees (QR codes ready for sale) ────────────────
    final treeData = [
      ('QR-00001', 'Dalbergia baronii', 'Palissandre', parcel1Id, 1),
      ('QR-00002', 'Ocotea cymosa', 'Varongy', parcel1Id, 2),
      ('QR-00003', 'Canarium madagascariensis', 'Ramy', parcel1Id, 3),
      ('QR-00004', 'Weinmannia rutenbergii', 'Hafotra', parcel2Id, 1),
      ('QR-00005', 'Tambourissa sp.', 'Ambora', parcel2Id, 2),
    ];

    for (final (qrCode, scientific, vernacular, parcelId, hole) in treeData) {
      await db.insert(DbConstants.tableTrees, {
        DbConstants.colId: _uuid.v4(),
        DbConstants.colTreeExternalId: qrCode,
        DbConstants.colTreeSpeciesScientific: scientific,
        DbConstants.colTreeSpeciesVernacular: vernacular,
        DbConstants.colTreeHoleNumber: hole,
        DbConstants.colTreeHealthStatus: TreeHealthStatus.pending,
        DbConstants.colTreeParcelId: parcelId,
        DbConstants.colSyncPending: 0,
        DbConstants.colCreatedAt: now,
        DbConstants.colUpdatedAt: now,
      });
    }
  }
}
