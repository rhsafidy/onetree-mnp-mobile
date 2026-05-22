import '../../models/tree.dart';

abstract class ITreeRepository {
  Future<Tree?> getByQRCode(String externalId);
  Future<Tree?> getById(String id);
  Future<List<Tree>> getAll();
  Future<List<Tree>> getByParcel(String parcelId);
  Future<List<Tree>> getPendingSync();
  Future<Tree> createPlantation(Tree tree);
  Future<Tree> update(Tree tree);
  Future<void> markSynced(String id);
  Future<void> replace(String id, Tree newTree);
}