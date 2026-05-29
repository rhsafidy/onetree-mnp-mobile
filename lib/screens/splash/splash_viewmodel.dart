// lib/screens/splash/splash_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/core/navigation/app_route.dart';
import '../../models/parcel.dart';
import '../../models/tree.dart';
import '../../models/tourist.dart';
import '../../repositories/parcel_repository.dart';
import '../../repositories/tree_repository.dart';
import '../../repositories/tourist_repository.dart';
import '../../services/device_service.dart';
import '../../services/session_service.dart';
import '../../services/sync_service.dart';
import 'pull_from_server_method.dart';
import 'pull_result.dart';

// ── Step model ────────────────────────────────────────────────────────────────

enum StepStatus { waiting, running, done, skipped, error }

class SplashStep {
  final String label;
  StepStatus   status;
  String?      detail;

  SplashStep({required this.label, this.status = StepStatus.waiting});
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class SplashViewModel extends ChangeNotifier {
  static const _lastSyncKey = 'last_pull_sync_at';

  final _parcelRepo  = ParcelRepository();
  final _treeRepo    = TreeRepository();
  final _touristRepo = TouristRepository();

  List<SplashStep> _steps       = [];
  double           _progress    = 0.0;
  String           _currentStep = 'Starting…';

  List<SplashStep> get steps       => _steps;
  double           get progress    => _progress;
  String           get currentStep => _currentStep;

  // ── Entry point ──────────────────────────────────────────────────────────

  Future<void> start(BuildContext context) async {
    _initSteps();
    await Future.delayed(const Duration(milliseconds: 350));

    bool isOnline       = false;
    bool hasSession     = false;
    bool hasDeviceToken = false;

    // Step 0 — Réseau
    await _run(0, 'Checking connection…', () async {
      final result = await Connectivity().checkConnectivity();
      isOnline     = result != ConnectivityResult.none;
      _steps[0].detail = isOnline ? 'Online' : 'Offline';
      if (!isOnline) _steps[0].status = StepStatus.skipped;
    });

    // Step 1 — Session + device token
    await _run(1, 'Restoring session…', () async {
      hasSession      = await SessionService.instance.restoreSession();
      hasDeviceToken  = await DeviceService.instance.hasDeviceToken();

      if (hasSession && !hasDeviceToken && isOnline) {
        // Première installation : enregistrer l'appareil auprès du backend
        try {
          await DeviceService.instance.registerDevice();
          hasDeviceToken  = true;
          _steps[1].detail =
              '${SessionService.instance.currentUser?.name} — device registered';
        } catch (_) {
          // Non bloquant — la sync sera possible à la prochaine ouverture
          _steps[1].detail =
              '${SessionService.instance.currentUser?.name} — registration pending';
        }
      } else if (hasSession) {
        _steps[1].detail = SessionService.instance.currentUser?.name ?? 'Logged in';
      } else {
        _steps[1].detail = 'Not authenticated';
      }
    });

    // La sync est possible si : online ET (device token OU session valide)
    final canSync = isOnline && (hasDeviceToken || hasSession);

    if (canSync) {
      // Step 2 — PULL : télécharger nouveautés du serveur
      await _run(2, 'Downloading updates…', () async {
        final since  = await _getLastSyncDate();
        final result = await pullFromServer(since: since);

        if (result.hasError) {
          _steps[2].status = StepStatus.error;
          _steps[2].detail = 'Server unreachable';
        } else {
          await _persistPullResult(result);
          await _saveLastSyncDate();
          _steps[2].detail =
              '${result.trees} trees  '
              '${result.parcels} parcels  '
              '${result.tourists} tourists';
        }
      });

      // Step 3 — PUSH : envoyer données offline en attente
      await _run(3, 'Uploading pending data…', () async {
        final count = await SyncService.instance.getPendingCount();
        if (count == 0) {
          _steps[3].status = StepStatus.skipped;
          _steps[3].detail = 'All up to date';
        } else {
          final res = await SyncService.instance.syncAll();
          _steps[3].detail  = '${res.synced} sent, ${res.failed} failed';
          if (res.hasErrors) _steps[3].status = StepStatus.error;
        }
      });
    } else {
      _markSkipped(2, isOnline ? 'No credentials' : 'Offline — skipped');
      _markSkipped(3, 'Offline — skipped');
    }

    // Step 4 — Données locales
    await _run(4, 'Loading local data…', () async {
      final parcels = await _parcelRepo.getAll();
      final trees   = await _treeRepo.getAll();
      final pending = await _treeRepo.getPendingSync();
      _steps[4].detail =
          '${parcels.length} parcels · '
          '${trees.length} trees · '
          '${pending.length} pending';
    });

    // ── Navigation ────────────────────────────────────────────────────────
    _progress    = 1.0;
    _currentStep = 'Ready';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    if (context.mounted) {
      Navigator.pushReplacementNamed(
        context,
        hasSession ? AppRoutes.parcelList : AppRoutes.login,
      );
    }
  }

  // ── Persist pulled server data to local SQLite ────────────────────────────

  Future<void> _persistPullResult(PullResult result) async {
    // Parcels
    for (final raw in result.rawParcels) {
      try {
        final p = Parcel.fromMap(_snake(raw));
        (await _parcelRepo.getById(p.id)) == null
            ? await _parcelRepo.create(p)
            : await _parcelRepo.update(p);
      } catch (_) {}
    }

    // Trees
    for (final raw in result.rawTrees) {
      try {
        final t = Tree.fromMap(_snake(raw));
        (await _treeRepo.getById(t.id)) == null
            ? await _treeRepo.createPlantation(t.copyWith(syncPending: false))
            : await _treeRepo.update(t.copyWith(syncPending: false));
      } catch (_) {}
    }

    // Tourists
    for (final raw in result.rawTourists) {
      try {
        final t = Tourist.fromMap(_snake(raw));
        (await _touristRepo.getById(t.id)) == null
            ? await _touristRepo.create(t)
            : await _touristRepo.update(t);
      } catch (_) {}
    }
  }

  // ── camelCase API → snake_case SQLite ─────────────────────────────────────

  Map<String, dynamic> _snake(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    map.forEach((k, v) {
      final s = k.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      );
      out[s] = v;
    });
    return out;
  }

  // ── SharedPreferences : dernière date de sync ─────────────────────────────

  Future<DateTime?> _getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final iso   = prefs.getString(_lastSyncKey);
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  Future<void> _saveLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastSyncKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  // ── Step helpers ──────────────────────────────────────────────────────────

  void _initSteps() {
    _steps = [
      SplashStep(label: 'Network check'),
      SplashStep(label: 'Session restore'),
      SplashStep(label: 'Download updates'),
      SplashStep(label: 'Upload offline data'),
      SplashStep(label: 'Load local database'),
    ];
    notifyListeners();
  }

  Future<void> _run(
    int     index,
    String  msg,
    Future<void> Function() fn,
  ) async {
    _steps[index].status = StepStatus.running;
    _currentStep         = msg;
    _progress            = (index + 0.5) / _steps.length;
    notifyListeners();

    try {
      await fn();
      if (_steps[index].status == StepStatus.running) {
        _steps[index].status = StepStatus.done;
      }
    } catch (_) {
      _steps[index].status = StepStatus.error;
      _steps[index].detail = 'Unexpected error';
    }

    _progress = (index + 1) / _steps.length;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 180));
  }

  void _markSkipped(int index, String detail) {
    _steps[index].status = StepStatus.skipped;
    _steps[index].detail = detail;
    _progress            = (index + 1) / _steps.length;
    notifyListeners();
  }
}