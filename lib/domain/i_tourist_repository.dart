import '../../models/touriste.dart';

abstract class ITouristeRepository {
  Future<Touriste> creer(Touriste touriste);
  Future<Touriste?> getById(String id);
  Future<List<Touriste>> rechercher(String query);
  Future<Touriste> mettreAJour(Touriste touriste);
  Future<void> supprimer(String id);
}