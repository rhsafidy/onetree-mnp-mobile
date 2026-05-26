// lib/providers/sync_provider.dart
//
// Exposes real-time sync state to the UI (pending count, online status, etc.)
// Consumed by the AppBar badge and the SyncScreen.

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';

enum SyncState { idle, syncing, done, error }

class SyncProvider extends ChangeNotifier {
  int       _pendingCount = 0;
  bool      _isOnline     = false;
  SyncState _state        = SyncState.idle;
  String?   _lastError;
  SyncResult? _lastResult;

  // ── Getters ───────────────────────────────────────────────────────────────

  int         get pendingCount => _pendingCount;
  bool        get isOnline     => _isOnline;
  SyncState   get state        => _state;
  String?     get lastError    => _lastError;
  SyncResult? get lastResult   => _lastResult;

  bool get hasPending => _pendingCount > 0;
  bool get isSyncing  => _state == SyncState.syncing;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _refreshPendingCount();
    _listenToConnectivity();
    SyncService.instance.startListening();
  }

  // ── Manual sync trigger ───────────────────────────────────────────────────

  Future<void> syncNow() async {
    if (isSyncing) return;

    _state     = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final result = await SyncService.instance.syncAll();
      _lastResult  = result;
      _state       = result.hasErrors ? SyncState.error : SyncState.done;
    } catch (e) {
      _lastError = e.toString();
      _state     = SyncState.error;
    }

    await _refreshPendingCount();
    notifyListeners();
  }

  // ── Called by repositories after any local write ──────────────────────────

  Future<void> onNewPendingEntry() async {
    await _refreshPendingCount();
    notifyListeners();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _refreshPendingCount() async {
    _pendingCount = await SyncService.instance.getPendingCount();
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      // Auto-sync when coming back online
      if (wasOffline && _isOnline && hasPending) {
        syncNow();
      }
      notifyListeners();
    });

    // Check current state immediately
    Connectivity().checkConnectivity().then((result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }
}
