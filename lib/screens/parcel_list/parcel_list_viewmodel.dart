// lib/screens/parcel_list/parcel_list_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../models/parcel.dart';
import '../../repositories/parcel_repository.dart';
import '../../repositories/tree_repository.dart';

class ParcelListViewModel extends ChangeNotifier {
  final _parcelRepo = ParcelRepository();
  final _treeRepo   = TreeRepository();

  List<Parcel>      _parcels     = [];
  Map<String, int>  _treeCounts  = {};
  bool              _isLoading   = false;
  String?           _error;

  List<Parcel>     get parcels    => _parcels;
  Map<String, int> get treeCounts => _treeCounts;
  bool             get isLoading  => _isLoading;
  String?          get error      => _error;

  Future<void> load() async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _parcelRepo.getAll(),
        _treeRepo.getStatusCounts(),
        _parcelRepo.getTreeCounts(),
      ]);

      _parcels    = results[0] as List<Parcel>;
      _treeCounts = results[2] as Map<String, int>;
    } catch (e) {
      _error = 'Failed to load parcels: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  int treeCountFor(String parcelId) => _treeCounts[parcelId] ?? 0;
}
