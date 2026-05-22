import '../../models/parcel.dart';

abstract class IParcelRepository {
  Future<List<Parcel>> getAll();
  Future<Parcel?> getById(String id);
  Future<Parcel?> getByCode(String code);
  Future<Parcel> create(Parcel parcel);
  Future<Parcel> update(Parcel parcel);
}