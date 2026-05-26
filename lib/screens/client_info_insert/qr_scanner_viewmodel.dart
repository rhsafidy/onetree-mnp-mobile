// lib/screens/client_info_insert/qr_scanner_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../../models/tree.dart';
import '../../repositories/tree_repository.dart';

enum QRScanState { scanning, loading, found, alreadyUsed, notFound, error }

class QRScannerViewModel extends ChangeNotifier {
  final _treeRepo = TreeRepository();

  QRScanState _state      = QRScanState.scanning;
  Tree?       _tree;
  String?     _scannedId;
  String?     _error;
  bool        _hasScanned = false;

  QRScanState get state      => _state;
  Tree?       get tree       => _tree;
  String?     get scannedId  => _scannedId;
  String?     get error      => _error;
  bool        get hasScanned => _hasScanned;

  Future<void> handleScan(String rawValue) async {
    if (_hasScanned) return;
    _hasScanned = true;
    _scannedId  = rawValue;
    _state      = QRScanState.loading;
    notifyListeners();

    try {
      // rawValue may be a full URL like https://arbre.mnp.mg/t/QR-00001
      // Extract the QR code ID from the end
      final qrCode = rawValue.contains('/')
          ? rawValue.split('/').last
          : rawValue;

      final tree = await _treeRepo.getByQRCode(qrCode);

      if (tree == null) {
        _state = QRScanState.notFound;
      } else if (tree.touristId != null) {
        _tree  = tree;
        _state = QRScanState.alreadyUsed;
      } else {
        _tree  = tree;
        _state = QRScanState.found;
      }
    } catch (e) {
      _error = e.toString();
      _state = QRScanState.error;
    }

    notifyListeners();
  }

  void reset() {
    _hasScanned = false;
    _state      = QRScanState.scanning;
    _tree       = null;
    _scannedId  = null;
    _error      = null;
    notifyListeners();
  }
}
