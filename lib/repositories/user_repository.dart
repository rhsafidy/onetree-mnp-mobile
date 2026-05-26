// lib/repositories/user_repository.dart

import 'package:mobile_app/domain/i_user_repository.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/db_constants.dart';
import '../core/database/app_database.dart';
import '../models/user.dart';

class UserRepository implements IUserRepository {
  final _db = AppDatabase.instance;
  final _uuid = const Uuid();

  @override
  Future<User?> login(String email, String password) async {
    // NOTE: In production, hash the password before comparing.
    // Here we simply look up by email; password check is done by the API.
    final rows = await _db.query(
      DbConstants.tableUsers,
      where: '${DbConstants.colUserEmail} = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  @override
  Future<User?> getById(String id) async {
    final rows = await _db.query(
      DbConstants.tableUsers,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  @override
  Future<void> saveSession(User user) async {
    await _db.insert(DbConstants.tableUsers, user.toMap());
  }

  @override
  Future<User?> getCurrentSession() async {
    // Session is stored in SharedPreferences — see SessionService.
    // This method retrieves the full User object from local DB.
    return null;
  }

  @override
  Future<void> logout() async {
    // Clear session token from SharedPreferences — see SessionService.
  }

  Future<User> create(User user) async {
    final newUser = User(
      id: _uuid.v4(),
      name: user.name,
      email: user.email,
      passwordHash: user.passwordHash,
      role: user.role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.insert(DbConstants.tableUsers, newUser.toMap());
    return newUser;
  }

  Future<List<User>> getAll() async {
    final rows = await _db.query(
      DbConstants.tableUsers,
      orderBy: DbConstants.colUserName,
    );
    return rows.map(User.fromMap).toList();
  }

  Future<void> delete(String id) async {
    await _db.delete(
      DbConstants.tableUsers,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }
}
