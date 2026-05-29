// lib/screens/splash/pull_result.dart

class PullResult {
  final int                        trees;
  final int                        parcels;
  final int                        tourists;
  final DateTime                   pulledAt;
  final String?                    error;

  // Raw JSON maps from the server — used by SplashViewModel to upsert locally
  final List<Map<String, dynamic>> rawTrees;
  final List<Map<String, dynamic>> rawParcels;
  final List<Map<String, dynamic>> rawTourists;

  const PullResult({
    required this.trees,
    required this.parcels,
    required this.tourists,
    required this.pulledAt,
    this.error,
    this.rawTrees    = const [],
    this.rawParcels  = const [],
    this.rawTourists = const [],
  });

  bool get hasError => error != null;
}