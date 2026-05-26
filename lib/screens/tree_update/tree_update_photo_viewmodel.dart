// lib/screens/tree_update/tree_update_photo_viewmodel.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/photo.dart';
import '../../repositories/photo_repository.dart';

class TreeUpdatePhotoViewModel extends ChangeNotifier {
  final _photoRepo = PhotoRepository();

  File?   _selectedFile;
  bool    _isSaving  = false;
  bool    _success   = false;
  String? _error;

  File?   get selectedFile => _selectedFile;
  bool    get isSaving     => _isSaving;
  bool    get success      => _success;
  String? get error        => _error;
  bool    get hasPhoto     => _selectedFile != null;

  void setPhoto(File file) {
    _selectedFile = file;
    _error        = null;
    notifyListeners();
  }

  Future<bool> save(String treeId, PhotoType type) async {
    if (_selectedFile == null) {
      _error = 'Please take a photo first.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error    = null;
    notifyListeners();

    try {
      await _photoRepo.saveLocally(_selectedFile!, treeId, type);
      _success = true;
    } catch (e) {
      _error = 'Failed to save photo: $e';
    }

    _isSaving = false;
    notifyListeners();
    return _success;
  }
}
