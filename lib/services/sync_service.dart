// lib/services/sync_service.dart
//
// Handles deferred synchronisation (3h max constraint from Mantadia terrain).
// Listens for network reconnection and flushes the sync_queue automatically.

import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/db_constants.dart';
import '../models/sync_queue_entry.dart';
import '../repositories/sync_queue_repository.dart';
import '../repositories/tree_repository.dart';
import '../repositories/photo_repository.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _syncQueueRepo = SyncQueueRepository();
  final _treeRepo      = TreeRepository();
  final _photoRepo     = PhotoRepository();
  final _dio           = Dio(BaseOptions(
    baseUrl:        AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
  ));

  bool _isSyncing = false;

  // ── Public: start listening for connectivity ──────────────────────────────

  void startListening() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncAll();
      }
    });
  }

  // ── Public: manual trigger (call from SyncScreen) ─────────────────────────

  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult(synced: 0, failed: 0, skipped: 0);
    _isSyncing = true;

    int synced = 0, failed = 0, skipped = 0;

    try {
      final entries = await _syncQueueRepo.getPending();

      for (final entry in entries) {
        if (entry.attempts >= DbConstants.syncMaxRetries) {
          skipped++;
          continue;
        }

        await _syncQueueRepo.markInProgress(entry.id);

        try {
          await _processEntry(entry);
          await _syncQueueRepo.markDone(entry.id);
          synced++;
        } catch (e) {
          await _syncQueueRepo.markFailed(entry.id);
          failed++;
        }
      }
    } finally {
      _isSyncing = false;
    }

    return SyncResult(synced: synced, failed: failed, skipped: skipped);
  }

  Future<int> getPendingCount() => _syncQueueRepo.getPendingCount();

  // ── Private: route each entry by action type ──────────────────────────────

  Future<void> _processEntry(SyncQueueEntry entry) async {
    switch (entry.typeAction) {
      case SyncActions.create:
        await _handleCreate(entry);
        break;
      case SyncActions.update:
        await _handleUpdate(entry);
        break;
      case SyncActions.uploadPhoto:
        await _handlePhotoUpload(entry);
        break;
      case SyncActions.delete:
        await _handleDelete(entry);
        break;
      default:
        throw Exception('Unknown sync action: ${entry.typeAction}');
    }
  }

  Future<void> _handleCreate(SyncQueueEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    await _dio.post(
      '/${entry.tableTarget}',
      data: payload,
    );
    // Mark local record as synced
    if (entry.tableTarget == DbConstants.tableTrees) {
      await _treeRepo.markSynced(entry.entityId);
    }
  }

  Future<void> _handleUpdate(SyncQueueEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    await _dio.put(
      '/${entry.tableTarget}/${entry.entityId}',
      data: payload,
    );
    if (entry.tableTarget == DbConstants.tableTrees) {
      await _treeRepo.markSynced(entry.entityId);
    }
  }

  Future<void> _handlePhotoUpload(SyncQueueEntry entry) async {
    final meta    = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final path    = meta['local_path'] as String;
    final treeId  = meta['tree_id'] as String;
    final type    = meta['type'] as String;
    final photoId = meta['photo_id'] as String;

    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Local photo file not found: $path');
    }

    final formData = FormData.fromMap({
      'tree_id': treeId,
      'type':    type,
      'file':    await MultipartFile.fromFile(path, filename: file.uri.pathSegments.last),
    });

    final response = await _dio.post('/photos', data: formData);
    final remoteUrl = response.data['url'] as String;
    await _photoRepo.markUploaded(photoId, remoteUrl);
  }

  Future<void> _handleDelete(SyncQueueEntry entry) async {
    await _dio.delete('/${entry.tableTarget}/${entry.entityId}');
  }
}

// ── Result DTO ────────────────────────────────────────────────────────────────

class SyncResult {
  final int synced;
  final int failed;
  final int skipped;

  const SyncResult({
    required this.synced,
    required this.failed,
    required this.skipped,
  });

  bool get hasErrors => failed > 0;
  int  get total     => synced + failed + skipped;

  @override
  String toString() =>
      'SyncResult(synced: $synced, failed: $failed, skipped: $skipped)';
}
