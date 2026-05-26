// lib/screens/tree_update/tree_update_form_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../models/tree.dart';
import '../../repositories/tree_repository.dart';
import '../../services/session_service.dart';

class TreeUpdateFormViewModel extends ChangeNotifier {
  final _treeRepo = TreeRepository();

  bool    _isSaving = false;
  String? _error;
  bool    _success  = false;

  bool    get isSaving => _isSaving;
  String? get error    => _error;
  bool    get success  => _success;

  Future<bool> saveUpdate({
    required Tree   original,
    required int?   heightCm,
    required String healthStatus,
    required double? latitude,
    required double? longitude,
    required String? notes,
  }) async {
    _isSaving = true;
    _error    = null;
    notifyListeners();

    try {
      final updated = original.copyWith(
        heightCm:       heightCm,
        healthStatus:   healthStatus,
        latitude:       latitude,
        longitude:      longitude,
        syncPending:    true,
        plantedByUserId: SessionService.instance.currentUser?.id,
      );
      await _treeRepo.update(updated);
      _success  = true;
    } catch (e) {
      _error = 'Failed to save: $e';
    }

    _isSaving = false;
    notifyListeners();
    return _success;
  }
}
