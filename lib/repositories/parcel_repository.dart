// lib/repositories/parcel_repository.dart

import 'package:mobile_app/domain/i_parcel_repository.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/db_constants.dart';
import '../core/database/app_database.dart';
import '../models/parcel.dart';

class ParcelRepository implements IParcelRepository {
  final _db = AppDatabase.instance;
  final _uuid = const Uuid();

  @override
  Future<List<Parcel>> getAll() async {
    final rows = await _db.query(
      DbConstants.tableParcels,
      orderBy: DbConstants.colParcelCode,
    );
    return rows.map(Parcel.fromMap).toList();
  }

  @override
  Future<Parcel?> getById(String id) async {
    final rows = await _db.query(
      DbConstants.tableParcels,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Parcel.fromMap(rows.first);
  }

  @override
  Future<Parcel?> getByCode(String code) async {
    final rows = await _db.query(
      DbConstants.tableParcels,
      where: '${DbConstants.colParcelCode} = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Parcel.fromMap(rows.first);
  }

  @override
  Future<Parcel> create(Parcel parcel) async {
    final newParcel = Parcel(
      id: _uuid.v4(),
      name: parcel.name,
      code: parcel.code,
      park: parcel.park,
      areaHa: parcel.areaHa,
      latitude: parcel.latitude,
      longitude: parcel.longitude,
      notes: parcel.notes,
      shapefileName: parcel.shapefileName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.insert(DbConstants.tableParcels, newParcel.toMap());
    return newParcel;
  }

  @override
  Future<Parcel> update(Parcel parcel) async {
    final updated = parcel.copyWith();
    await _db.update(
      DbConstants.tableParcels,
      updated.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [parcel.id],
    );
    return updated;
  }

  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableParcels,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  /// Returns total tree count per parcel as a map {parcelId: count}.
  Future<Map<String, int>> getTreeCounts() async {
    final rows = await _db.rawQuery('''
      SELECT ${DbConstants.colTreeParcelId} as parcel_id, COUNT(*) as count
      FROM ${DbConstants.tableTrees}
      WHERE ${DbConstants.colTreeParcelId} IS NOT NULL
      GROUP BY ${DbConstants.colTreeParcelId}
    ''');
    return {
      for (final r in rows) r['parcel_id'] as String: r['count'] as int,
    };
  }
}
