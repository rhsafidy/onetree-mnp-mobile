// lib/screens/client_info_insert/client_form_screen_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../models/tourist.dart';
import '../../models/tree.dart';
import '../../repositories/tourist_repository.dart';
import '../../repositories/tree_repository.dart';

class ClientFormViewModel extends ChangeNotifier {
  final _touristRepo = TouristRepository();
  final _treeRepo    = TreeRepository();

  bool    _isSaving = false;
  bool    _success  = false;
  String? _error;

  bool    get isSaving => _isSaving;
  bool    get success  => _success;
  String? get error    => _error;

  Future<bool> save({
    required Tree   tree,
    required String name,
    String?         email,
    String?         nationality,
    String?         phone,
  }) async {
    _isSaving = true;
    _error    = null;
    notifyListeners();

    try {
      // 1. Create tourist record
      final tourist = await _touristRepo.create(Tourist(
        id:          '',          // generated in repo
        name:        name,
        email:       email?.isEmpty == true ? null : email,
        nationality: nationality?.isEmpty == true ? null : nationality,
        phone:       phone?.isEmpty == true ? null : phone,
        createdAt:   DateTime.now(),
      ));

      // 2. Link tourist to tree (attribution)
      await _treeRepo.update(tree.copyWith(
        touristId:   tourist.id,
        healthStatus: 'pending', // stays pending until planting
        syncPending:  true,
      ));

      _success = true;
    } catch (e) {
      _error = 'Failed to register tourist: $e';
    }

    _isSaving = false;
    notifyListeners();
    return _success;
  }
}
