import '../../models/user.dart';

abstract class IUserRepository {
  Future<User?> login(String email, String password);
  Future<User?> getById(String id);
  Future<void> saveSession(User user);
  Future<User?> getCurrentSession();
  Future<void> logout();
}