import 'dart:io';
import '../../models/photo.dart';

abstract class IPhotoRepository {
  Future<List<Photo>> getByTree(String treeId);
  Future<Photo> saveLocally(File file, String treeId, PhotoType type);
  Future<Photo> upload(Photo photo);
  Future<List<Photo>> getPendingUpload();
  Future<void> markUploaded(String id, String url);
}