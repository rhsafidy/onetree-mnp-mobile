// lib/repositories/tourist_repository.dart

import 'package:mobile_app/domain/i_tourist_repository.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/db_constants.dart';
import '../core/database/app_database.dart';

import '../models/tourist.dart';

class TouristRepository implements ITouristRepository {
  final _db = AppDatabase.instance;
  final _uuid = const Uuid();

  @override
  Future<Tourist> create(Tourist tourist) async {
    final newTourist = Tourist(
      id: _uuid.v4(),
      name: tourist.name,
      email: tourist.email,
      nationality: tourist.nationality,
      phone: tourist.phone,
      createdAt: DateTime.now(),
    );
    await _db.insert(DbConstants.tableTourists, newTourist.toMap());
    return newTourist;
  }

  @override
  Future<Tourist?> getById(String id) async {
    final rows = await _db.query(
      DbConstants.tableTourists,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Tourist.fromMap(rows.first);
  }

  @override
  Future<List<Tourist>> search(String query) async {
    final like = '%$query%';
    final rows = await _db.query(
      DbConstants.tableTourists,
      where: '''
        ${DbConstants.colTouristName}  LIKE ? OR
        ${DbConstants.colTouristEmail} LIKE ?
      ''',
      whereArgs: [like, like],
      orderBy: DbConstants.colTouristName,
    );
    return rows.map(Tourist.fromMap).toList();
  }

  @override
  Future<Tourist> update(Tourist tourist) async {
    final updated = tourist.copyWith();
    await _db.update(
      DbConstants.tableTourists,
      updated.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [tourist.id],
    );
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableTourists,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  @override 
  Future<List<Tourist>> getAll() async {
    final rows = await _db.query(
      DbConstants.tableTourists,
      orderBy: '${DbConstants.colCreatedAt} DESC',
    );
    return rows.map(Tourist.fromMap).toList();
  }
}
