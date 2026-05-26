import '../../models/tourist.dart';

abstract class ITouristRepository {
  Future<Tourist> create(Tourist tourist);
  Future<Tourist?> getById(String id);
  Future<List<Tourist>> search(String query);
  Future<Tourist> update(Tourist tourist);
  Future<void> delete(String id);
}