// lib/screens/splash/pull_from_server_method.dart
//
// CORRECTIFS :
// 1. Dio séparé supprimé — on utilise SyncService.instance directement
//    pour bénéficier du baseUrl ET de l'intercepteur device token déjà configurés.
// 2. PullResult déplacé dans son propre fichier (pull_result.dart).

import 'package:mobile_app/services/sync_service.dart';
import 'pull_result.dart';

Future<PullResult> pullFromServer({DateTime? since}) async {
  try {
    final sinceParam = (since ?? DateTime.fromMillisecondsSinceEpoch(0))
        .toUtc()
        .toIso8601String();

    // Utilise le Dio de SyncService : baseUrl + intercepteur device token ✓
    final response = await SyncService.instance.dio.get(
      '/sync/pull',
      queryParameters: {'since': sinceParam},
    );

    final data = response.data as Map<String, dynamic>;

    final rawTrees    = List<Map<String, dynamic>>.from(data['trees']    ?? []);
    final rawParcels  = List<Map<String, dynamic>>.from(data['parcels']  ?? []);
    final rawTourists = List<Map<String, dynamic>>.from(data['tourists'] ?? []);

    return PullResult(
      trees:       rawTrees.length,
      parcels:     rawParcels.length,
      tourists:    rawTourists.length,
      pulledAt:    DateTime.tryParse(data['pulledAt'] ?? '') ?? DateTime.now(),
      rawTrees:    rawTrees,
      rawParcels:  rawParcels,
      rawTourists: rawTourists,
    );
  } catch (e) {
    return PullResult(
      trees:    0,
      parcels:  0,
      tourists: 0,
      pulledAt: DateTime.now(),
      error:    e.toString(),
    );
  }
}