// lib/screens/trees_list/trees_list_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../models/tree.dart';
import '../../models/parcel.dart';
import '../../repositories/tree_repository.dart';

class TreesListViewModel extends ChangeNotifier {
  final _treeRepo = TreeRepository();

  List<Tree>  _trees     = [];
  List<Tree>  _filtered  = [];
  bool        _isLoading = false;
  String?     _error;
  String      _search    = '';
  String?     _statusFilter;

  List<Tree>  get trees       => _filtered;
  bool        get isLoading   => _isLoading;
  String?     get error       => _error;
  String?     get statusFilter => _statusFilter;

  static const List<String?> statusOptions = [
    null, 'pending', 'planted', 'monitored', 'dead', 'replaced',
  ];

  Future<void> load(Parcel parcel) async {
    _isLoading = true;
    _error     = null;
    notifyListeners();

    try {
      _trees = await _treeRepo.getByParcel(parcel.id);
      _applyFilters();
    } catch (e) {
      _error = 'Failed to load trees: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String q) {
    _search = q.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filtered = _trees.where((t) {
      final matchSearch = _search.isEmpty ||
          (t.speciesVernacular?.toLowerCase().contains(_search) ?? false) ||
          (t.speciesScientific?.toLowerCase().contains(_search) ?? false) ||
          t.externalId.toLowerCase().contains(_search);
      final matchStatus = _statusFilter == null || t.healthStatus == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();
  }
}
