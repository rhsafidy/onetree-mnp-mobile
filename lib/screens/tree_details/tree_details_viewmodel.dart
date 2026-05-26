// lib/screens/tree_details/tree_details_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../models/photo.dart';
import '../../models/tree.dart';
import '../../repositories/photo_repository.dart';
import '../../repositories/tree_repository.dart';

class TreeDetailsViewModel extends ChangeNotifier {
  final _treeRepo  = TreeRepository();
  final _photoRepo = PhotoRepository();

  Tree?        _tree;
  List<Photo>  _photos    = [];
  bool         _isLoading = false;
  String?      _error;

  Tree?       get tree      => _tree;
  List<Photo> get photos    => _photos;
  bool        get isLoading => _isLoading;
  String?     get error     => _error;

  Future<void> load(Tree tree) async {
    _tree      = tree;
    _isLoading = true;
    notifyListeners();

    try {
      _photos = await _photoRepo.getByTree(tree.id);
    } catch (e) {
      _error = 'Failed to load photos: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_tree == null) return;
    final updated = await _treeRepo.getById(_tree!.id);
    if (updated != null) {
      _tree   = updated;
      _photos = await _photoRepo.getByTree(updated.id);
      notifyListeners();
    }
  }
}
